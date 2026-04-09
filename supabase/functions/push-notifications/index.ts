import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID")!;
const firebaseServiceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);

const supabase = createClient(supabaseUrl, serviceRoleKey);

serve(async (req) => {
  try {
    const payload = await req.json();
    const { record } = payload; // This is the new notification record

    // 1. SAFETY CHECK: Ensure not blocked or muted (Backup for DB trigger)
    // A. Check if recipient blocked actor
    const { data: blockData } = await supabase
      .from('blocked_users')
      .select('id')
      .eq('blocker_id', record.user_id)
      .eq('blocked_id', record.actor_id)
      .maybeSingle();

    if (blockData) {
      return new Response(JSON.stringify({ message: "Recipient has blocked actor" }), { status: 200 });
    }

    // B. Check if conversation is muted (for DMs)
    if (record.type === 'dm' && record.message_id) {
      // Get conversation_id
      const { data: msgData } = await supabase
        .from('messages')
        .select('conversation_id')
        .eq('id', record.message_id)
        .single();

      if (msgData) {
        const { data: participant } = await supabase
          .from('conversation_participants')
          .select('is_muted')
          .eq('conversation_id', msgData.conversation_id)
          .eq('user_id', record.user_id)
          .maybeSingle();

        if (participant?.is_muted) {
          return new Response(JSON.stringify({ message: "Conversation is muted" }), { status: 200 });
        }
      }
    }

    // 2. Get recipient profile (for FCM token)
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token, username')
      .eq('id', record.user_id)
      .single();

    if (profileError || !profile?.fcm_token) {
      return new Response(JSON.stringify({ message: "No token found" }), { status: 200 });
    }

    // 2. Get actor profile (sender)
    const { data: actor, error: actorError } = await supabase
      .from('profiles')
      .select('username')
      .eq('id', record.actor_id)
      .single();

    const actorName = actor?.username || "Someone";
    let title = "New Notification";
    let body = record.content || "";

    // 3. Customize based on type
    switch (record.type) {
      case 'dm':
        title = actorName;
        break;
      case 'like':
        title = "New Like";
        body = `${actorName} liked your post`;
        break;
      case 'comment':
        title = "New Comment";
        body = `${actorName} commented on your post`;
        break;
      case 'follow':
        title = "New Follower";
        body = `${actorName} started following you`;
        break;
      case 'call':
        // Parse call details from content (stored as JSON string)
        let callDetails = {};
        try {
          if (record.content) {
            callDetails = JSON.parse(record.content);
          }
        } catch (e) {
          // ignore parse error
        }
        const callType = callDetails['type'] || 'voice';
        const callId = callDetails['call_id'] || '';
        title = "Incoming ${callType === 'video' ? 'Video' : 'Voice'} Call";
        body = `${actorName} is calling you`;
        // Add call-specific data for navigation
        record.call_id = callId;
        record.call_type = callType;
        break;
    }

    // 4. Get Google OAuth2 access token for FCM
    const accessToken = await getGoogleAccessToken(firebaseServiceAccount);

    // 5. Send FCM message
    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: profile.fcm_token,
            notification: {
              title: title,
              body: body,
            },
            data: {
              type: record.type,
              actor_id: record.actor_id,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              ...(record.call_id ? { call_id: record.call_id, call_type: record.call_type } : {}),
            },
            android: {
              priority: "high",
              notification: {
                sound: "default",
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                },
              },
            },
          },
        }),
      }
    );

    const fcmResult = await fcmResponse.json();
    return new Response(JSON.stringify(fcmResult), { status: 200 });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});

async function getGoogleAccessToken(serviceAccount: any) {
  // Create JWT for Google OAuth2
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  // Encode header and claim
  const encodedHeader = b64url(JSON.stringify(header));
  const encodedClaim = b64url(JSON.stringify(claim));
  const payload = `${encodedHeader}.${encodedClaim}`;

  // Sign the JWT using Web Crypto API
  const signature = await signJwt(payload, serviceAccount.private_key);
  const jwt = `${payload}.${signature}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

async function signJwt(payload: string, privateKeyPem: string): Promise<string> {
  // Import the private key
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  // Sign the payload
  const signature = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    privateKey,
    new TextEncoder().encode(payload)
  );

  // Convert to base64url
  return b64url(Array.from(new Uint8Array(signature)));
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  // Remove PEM header/footer and decode base64
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function b64url(str: string): string {
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

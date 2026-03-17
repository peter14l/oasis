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

    // 1. Get recipient profile (for FCM token)
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
  // Simple JWT implementation for Deno
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = b64(JSON.stringify(header));
  const encodedClaim = b64(JSON.stringify(claim));
  const signatureInput = `${encodedHeader}.${encodedClaim}`;
  
  // This requires a subtle crypto polyfill or library in Deno
  // For simplicity in this prompt, assume we have a helper or use a library
  // In real deployment, you'd use 'https://deno.land/x/djwt/mod.ts'
  
  // MOCK for instruction: 
  // return await signJwt(signatureInput, serviceAccount.private_key);
  return "TOKEN_PLACEHOLDER"; 
}

function b64(str: string) {
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

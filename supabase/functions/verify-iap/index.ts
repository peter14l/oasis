import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { product_id, purchase_id, verification_data, platform } = await req.json()
    
    // 1. Setup Supabase
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 2. Authenticate User
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('No authorization header')
    const { data: { user }, error: userError } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''))
    if (userError || !user) throw new Error('Unauthorized')

    let isValid = false;

    if (platform === 'apple') {
      isValid = await verifyApplePurchase(verification_data);
    } else if (platform === 'google') {
      isValid = await verifyGooglePurchase(verification_data, product_id);
    }

    if (!isValid) {
      throw new Error('Invalid purchase verification');
    }

    // 3. Update Subscriptions table
    const periodEnd = new Date()
    periodEnd.setDate(periodEnd.getDate() + 30) // Monthly

    const { error: upsertError } = await supabase.from('subscriptions').upsert({
      user_id: user.id,
      status: 'active',
      plan_id: product_id,
      payment_provider: platform === 'apple' ? 'apple_store' : 'google_play',
      provider_subscription_id: purchase_id,
      current_period_start: new Date().toISOString(),
      current_period_end: periodEnd.toISOString(),
    }, { onConflict: 'user_id' })

    if (upsertError) throw upsertError;

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    console.error(`[IAP Verify Error] ${error.message}`)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})

async function verifyApplePurchase(receipt: string): Promise<boolean> {
  const password = Deno.env.get('APPLE_IAP_SHARED_SECRET');
  const url = Deno.env.get('APPLE_ENVIRONMENT') === 'production'
    ? 'https://buy.itunes.apple.com/verifyReceipt'
    : 'https://sandbox.itunes.apple.com/verifyReceipt';

  const response = await fetch(url, {
    method: 'POST',
    body: JSON.stringify({
      'receipt-data': receipt,
      'password': password,
      'exclude-old-transactions': true
    })
  });
  
  const data = await response.json();
  return data.status === 0;
}

async function verifyGooglePurchase(token: string, productId: string): Promise<boolean> {
  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!serviceAccountRaw) throw new Error("FIREBASE_SERVICE_ACCOUNT not configured");
  
  const serviceAccount = JSON.parse(serviceAccountRaw);
  const packageName = Deno.env.get("ANDROID_PACKAGE_NAME") || "com.oasis.app";

  const accessToken = await getGoogleAccessToken(serviceAccount, "https://www.googleapis.com/auth/androidpublisher");

  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${productId}/tokens/${token}`;

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    }
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('Google Play API error:', errorText);
    return false;
  }

  const data = await response.json();
  
  // Verify subscription status
  // paymentState: 1 (Received), 0 (Pending), 2 (Free Trial)
  // For production, we usually want 1 or 2.
  const expiryTimeMillis = parseInt(data.expiryTimeMillis);
  const isNotExpired = expiryTimeMillis > Date.now();
  
  return isNotExpired;
}

// Helper functions for Google Auth (shared logic with push-notifications)
async function getGoogleAccessToken(serviceAccount: any, scope: string) {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: serviceAccount.client_email,
    scope: scope,
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = b64url(JSON.stringify(header));
  const encodedClaim = b64url(JSON.stringify(claim));
  const payload = `${encodedHeader}.${encodedClaim}`;

  const signature = await signJwt(payload, serviceAccount.private_key);
  const jwt = `${payload}.${signature}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenResponse.json();
  if (!tokenResponse.ok) throw new Error(`Failed to get Google token: ${JSON.stringify(tokenData)}`);
  return tokenData.access_token;
}

async function signJwt(payload: string, privateKeyPem: string): Promise<string> {
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    privateKey,
    new TextEncoder().encode(payload)
  );

  return b64url(Array.from(new Uint8Array(signature)));
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
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

function b64url(input: string | number[]): string {
  let base64: string;
  if (typeof input === 'string') {
    base64 = btoa(input);
  } else {
    base64 = btoa(String.fromCharCode(...input));
  }
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

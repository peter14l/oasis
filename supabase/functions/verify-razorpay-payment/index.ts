import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { 
      razorpay_payment_id, 
      razorpay_order_id,      // For one-time payments
      razorpay_subscription_id, // For subscriptions
      razorpay_signature,
      plan = 'Pro' 
    } = await req.json()
    
    const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')
    const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')
    
    if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
      console.error('Missing Razorpay credentials in Supabase secrets');
      return new Response(JSON.stringify({ error: 'Razorpay credentials not configured' }), { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    // 1. Verify Signature (HMAC SHA256)
    // One-time: order_id + "|" + payment_id
    // Subscription: payment_id + "|" + subscription_id
    const targetId = razorpay_order_id || razorpay_subscription_id
    if (!targetId) throw new Error('Missing order_id or subscription_id')

    const data = razorpay_order_id 
      ? `${razorpay_order_id}|${razorpay_payment_id}`
      : `${razorpay_payment_id}|${razorpay_subscription_id}`

    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      "raw", 
      encoder.encode(RAZORPAY_KEY_SECRET), 
      { name: "HMAC", hash: "SHA-256" }, 
      false, 
      ["sign"]
    )
    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(data))
    const generated_signature = Array.from(new Uint8Array(signatureBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')

    if (generated_signature !== razorpay_signature) {
      console.error(`Signature verification failed. Data: ${data}, Expected: ${razorpay_signature}, Generated: ${generated_signature}`);
      return new Response(JSON.stringify({ error: 'Invalid payment signature' }), { 
        status: 400, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    // 2. Initialize Supabase Admin
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 3. Get User from Auth Header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Unauthorized: No Authorization header provided')
    
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)
    
    if (userError || !user) {
      console.error('Auth User Error:', userError)
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { 
        status: 401, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    console.log(`[VerifyPayment] Verified signature for user: ${user.id}`)

    // 4. Update Database (Idempotent Update)
    // Update profiles
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({ is_pro: true })
      .eq('id', user.id)

    if (profileError) {
      console.error('Profile update failed:', profileError.message)
      throw new Error('Failed to update user profile')
    }

    // Update or insert subscription record
    const periodEnd = new Date()
    periodEnd.setDate(periodEnd.getDate() + 30) // Default 30 days

    const { error: subError } = await supabaseAdmin.from('subscriptions').upsert({
      user_id: user.id,
      status: 'active',
      plan_id: plan,
      payment_provider: 'razorpay',
      provider_payment_id: razorpay_payment_id,
      provider_order_id: razorpay_order_id,
      provider_subscription_id: razorpay_subscription_id,
      current_period_start: new Date().toISOString(),
      current_period_end: periodEnd.toISOString(),
      updated_at: new Date().toISOString()
    }, { onConflict: 'user_id' })

    if (subError) {
      console.error('Subscription upsert failed:', subError.message)
      // We don't throw here because profile is already updated, but we log it
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Payment verified and account upgraded' }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )

  } catch (error: any) {
    console.error(`[VerifyPayment Error] ${error.message}`)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})

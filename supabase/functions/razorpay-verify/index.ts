import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = await req.json()
    const secret = Deno.env.get('RAZORPAY_SECRET')
    if (!secret) throw new Error('Razorpay secret not configured')

    // 1. Verify Signature (HMAC SHA256)
    // Formula: SHA256(order_id + "|" + payment_id, secret)
    const data = razorpay_order_id + "|" + razorpay_payment_id
    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      "raw", 
      encoder.encode(secret), 
      { name: "HMAC", hash: "SHA-256" }, 
      false, 
      ["sign"]
    )
    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(data))
    const generated_signature = Array.from(new Uint8Array(signatureBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')

    if (generated_signature !== razorpay_signature) {
      throw new Error('Invalid payment signature')
    }

    // 2. Setup Supabase with Service Role
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 3. Authenticate User
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('No authorization header')
    
    const { data: { user }, error: userError } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''))
    if (userError || !user) throw new Error('Unauthorized')

    // 4. Record the subscription (this will trigger is_pro updates in DB)
    const periodEnd = new Date()
    periodEnd.setDate(periodEnd.getDate() + 30) // 30 days from now

    // We can extract the plan from the request if we update the frontend, 
    // for now we'll check if it was provided in the body or default to Pro
    const { plan = 'Pro' } = await req.json()

    await supabase.from('subscriptions').upsert({
      user_id: user.id,
      status: 'active',
      plan_id: plan,
      payment_provider: 'razorpay',
      provider_subscription_id: razorpay_payment_id,
      current_period_start: new Date().toISOString(),
      current_period_end: periodEnd.toISOString(),
    }, { onConflict: 'user_id' })

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    console.error(`[Razorpay Verify Error] ${error.message}`)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})

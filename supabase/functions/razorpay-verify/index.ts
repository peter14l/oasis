import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// SECURE PRICE MAP (The "Truth")
const PLAN_PRICES: Record<string, { USD: number; INR: number }> = {
  'Pro': { USD: 4.99, INR: 5.00 } // Temporarily Rs 5 for testing
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { razorpay_payment_id, razorpay_subscription_id, razorpay_signature, plan = 'Pro', currency = 'INR' } = await req.json()
    
    const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')
    const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')
    
    if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
      console.error('Missing Razorpay credentials in Supabase secrets');
      throw new Error('Razorpay credentials not configured');
    }

    // 1. Verify Signature (HMAC SHA256) - Subscription signature uses payment_id + subscription_id
    const data = razorpay_payment_id + "|" + razorpay_subscription_id
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
      console.error('Signature verification failed');
      throw new Error('Invalid payment signature');
    }

    // 2. Fetch Payment Details from Razorpay to verify Amount
    const basicAuth = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`)
    const paymentRes = await fetch(`https://api.razorpay.com/v1/payments/${razorpay_payment_id}`, {
      method: 'GET',
      headers: {
        'Authorization': `Basic ${basicAuth}`,
      }
    })

    if (!paymentRes.ok) throw new Error('Failed to fetch payment details from Razorpay')
    const paymentData = await paymentRes.json()

    if (paymentData.status !== 'captured' && paymentData.status !== 'authorized') {
      throw new Error(`Payment status is ${paymentData.status}, expected captured or authorized`)
    }

    // 3. SECURITY: Validate Amount & Currency (Price check removed for subscriptions as plan handles it)
    // We just verify the subscription was indeed authorized.

    // 4. Update User Subscription in Database
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Unauthorized: No Authorization header provided')
    
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)
    
    if (userError) {
      console.error('Auth User Error:', userError)
      throw new Error(`Unauthorized: ${userError.message}`)
    }
    if (!user) throw new Error('Unauthorized: User not found')

    console.log(`Verified payment for user: ${user.id}`)

    // BACKUP: Update profile directly to ensure user gets Pro status immediately
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({ is_pro: true })
      .eq('id', user.id)

    if (profileError) {
      console.warn('Direct profile update failed (non-critical):', profileError.message)
    }

    const periodEnd = new Date()
    periodEnd.setDate(periodEnd.getDate() + 30)

    // Primary: Update subscriptions table
    const { error: upsertError } = await supabaseAdmin.from('subscriptions').upsert({
      user_id: user.id,
      status: 'active',
      plan_id: plan,
      payment_provider: 'razorpay',
      provider_subscription_id: razorpay_subscription_id,
      current_period_start: new Date().toISOString(),
      current_period_end: periodEnd.toISOString(),
    }, { onConflict: 'user_id' })

    if (upsertError) {
      console.error('Database Upsert Error:', upsertError)
      throw new Error(`Failed to record subscription: ${upsertError.message}`)
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    console.error(`[Razorpay Verify Error] ${error.message}`)
    // Return 200 with success: false so the frontend can read the error message
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})

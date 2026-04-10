import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { b64 } from "https://deno.land/x/b64@1.1.2/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// SECURE PRICE MAP (The "Truth")
const PLAN_PRICES: Record<string, { USD: number; INR: number }> = {
  'Pro': { USD: 4.99, INR: 149.00 }
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, plan = 'Pro', currency = 'INR' } = await req.json()
    
    const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')
    const RAZORPAY_SECRET = Deno.env.get('RAZORPAY_SECRET')
    
    if (!RAZORPAY_KEY_ID || !RAZORPAY_SECRET) {
      throw new Error('Razorpay credentials not configured')
    }

    // 1. Verify Signature (HMAC SHA256)
    const data = razorpay_order_id + "|" + razorpay_payment_id
    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      "raw", 
      encoder.encode(RAZORPAY_SECRET), 
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

    // 2. Fetch Payment Details from Razorpay to verify Amount
    const basicAuth = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_SECRET}`)
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

    // 3. SECURITY: Validate Amount & Currency
    // Razorpay amounts are in subunits (paise for INR, cents for USD)
    const paidAmount = paymentData.amount / 100;
    const paidCurrency = paymentData.currency;

    const expectedPrice = PLAN_PRICES[plan]?.[paidCurrency as 'USD' | 'INR'];
    
    if (!expectedPrice) {
      throw new Error(`Invalid plan or currency: ${plan} / ${paidCurrency}`);
    }

    if (Math.abs(paidAmount - expectedPrice) > 0.01) {
      throw new Error(`Price mismatch! Paid: ${paidAmount}, Expected: ${expectedPrice}`);
    }

    // 4. Update User Subscription in Database
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Unauthorized')
    
    const { data: { user }, error: userError } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''))
    if (userError || !user) throw new Error('Unauthorized')

    const periodEnd = new Date()
    periodEnd.setDate(periodEnd.getDate() + 30) // 30 days from now

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
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})

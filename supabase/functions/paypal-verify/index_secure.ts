import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// SECURE PRICE MAP (The "Truth")
// Users cannot edit these amounts as they are enforced on the server.
const PLAN_PRICES: Record<string, { USD: number; INR: number }> = {
  'Pro': { USD: 4.99, INR: 149.00 }
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { orderId, plan, currency } = await req.json()
    const PAYPAL_CLIENT_ID = Deno.env.get('PAYPAL_CLIENT_ID')
    const PAYPAL_SECRET = Deno.env.get('PAYPAL_SECRET')
    
    const PAYPAL_API = Deno.env.get('PAYPAL_ENVIRONMENT') === 'production' 
      ? 'https://api-m.paypal.com' 
      : 'https://api-m.sandbox.paypal.com'

    if (!PAYPAL_CLIENT_ID || !PAYPAL_SECRET) {
      throw new Error('PayPal credentials are not configured on the server.')
    }

    // 1. Get Access Token
    const basicAuth = btoa(`${PAYPAL_CLIENT_ID}:${PAYPAL_SECRET}`)
    const tokenRes = await fetch(`${PAYPAL_API}/v1/oauth2/token`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Authorization': `Basic ${basicAuth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials'
    })
    
    if (!tokenRes.ok) throw new Error('Failed to get PayPal token')
    const tokenData = await tokenRes.json()

    // 2. Verify Order with PayPal
    const orderRes = await fetch(`${PAYPAL_API}/v2/checkout/orders/${orderId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${tokenData.access_token}`,
        'Content-Type': 'application/json',
      }
    })
    
    if (!orderRes.ok) throw new Error('Failed to verify PayPal order')
    const orderData = await orderRes.json()

    if (orderData.status !== 'COMPLETED') {
        throw new Error('Order is not completed')
    }

    // 3. SECURITY: Validate Amount & Currency (Price Integrity Check)
    const paidAmount = parseFloat(orderData.purchase_units[0].amount.value);
    const paidCurrency = orderData.purchase_units[0].amount.currency_code;
    
    const expectedPrice = PLAN_PRICES[plan]?.[paidCurrency as 'USD' | 'INR'];
    
    if (!expectedPrice) {
      throw new Error(`Invalid plan or currency: ${plan} / ${paidCurrency}`);
    }

    // Allow for small rounding differences but enforce integrity
    if (Math.abs(paidAmount - expectedPrice) > 0.01) {
      throw new Error(`Price mismatch! Paid: ${paidAmount}, Expected: ${expectedPrice}`);
    }

    // 4. Update User Subscription in Database
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Unauthorized: No token provided');
    
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabase.auth.getUser(token)
    
    if (userError || !user) throw new Error('Unauthorized: Invalid token')

    const periodEnd = new Date()
    periodEnd.setDate(periodEnd.getDate() + 30) // 30 days from now

    // Record the subscription
    const { error: upsertError } = await supabase.from('subscriptions').upsert({
      user_id: user.id,
      status: 'active',
      plan_id: plan,
      payment_provider: 'paypal',
      provider_subscription_id: orderId,
      current_period_start: new Date().toISOString(),
      current_period_end: periodEnd.toISOString(),
    }, { onConflict: 'user_id' })

    if (upsertError) throw upsertError;

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[PayPal Verify Error]', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

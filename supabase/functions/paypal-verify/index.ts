import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { orderId, plan, amount, currency } = await req.json()
    const PAYPAL_CLIENT_ID = Deno.env.get('PAYPAL_CLIENT_ID')
    const PAYPAL_SECRET = Deno.env.get('PAYPAL_SECRET')
    
    // For test mode, use sandbox. For prod, use api-m.paypal.com
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
        'Accept-Language': 'en_US',
        'Authorization': `Basic ${basicAuth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials'
    })
    
    if (!tokenRes.ok) {
        throw new Error('Failed to get PayPal token')
    }
    const tokenData = await tokenRes.json()

    // 2. Verify Order
    const orderRes = await fetch(`${PAYPAL_API}/v2/checkout/orders/${orderId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${tokenData.access_token}`,
        'Content-Type': 'application/json',
      }
    })
    
    if (!orderRes.ok) {
        throw new Error('Failed to verify PayPal order')
    }
    const orderData = await orderRes.json()

    if (orderData.status !== 'COMPLETED') {
        throw new Error('Order is not completed')
    }

    // 3. Update User Subscription in Database
    // Using service role key to bypass RLS for updating subscription
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Extract user from request header
    const authHeader = req.headers.get('Authorization')
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '')
      const { data: { user }, error: userError } = await supabase.auth.getUser(token)
      if (user && !userError) {
          // 3. Record the subscription (this will trigger is_pro updates in DB)
          const periodEnd = new Date()
          periodEnd.setDate(periodEnd.getDate() + 30) // 30 days from now

          await supabase.from('subscriptions').upsert({
            user_id: user.id,
            status: 'active',
            plan_id: plan,
            payment_provider: 'paypal',
            provider_subscription_id: orderId, // Use order ID as subscription ID for now
            current_period_start: new Date().toISOString(),
            current_period_end: periodEnd.toISOString(),
          }, { onConflict: 'user_id' })

          // Also update profile plan name
          await supabase.from('profiles').update({ 
            plan: plan, 
            updated_at: new Date().toISOString() 
          }).eq('id', user.id)
      }
    }

    return new Response(
      JSON.stringify({ success: true, order: orderData }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('PayPal Verify Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

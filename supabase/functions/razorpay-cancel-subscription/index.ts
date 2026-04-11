import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')
    const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')
    
    if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
      throw new Error('Razorpay credentials not configured')
    }

    // 1. Authenticate User
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Unauthorized')
    
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))
    if (userError || !user) throw new Error('Unauthorized')

    // 2. Find the user's active subscription ID
    const { data: subData, error: subError } = await supabaseAdmin
      .from('subscriptions')
      .select('provider_subscription_id')
      .eq('user_id', user.id)
      .eq('status', 'active')
      .maybeSingle()

    if (subError || !subData?.provider_subscription_id) {
      throw new Error('No active subscription found to cancel.')
    }

    const subscriptionId = subData.provider_subscription_id

    // 3. Call Razorpay to cancel at cycle end
    const basicAuth = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`)
    const response = await fetch(`https://api.razorpay.com/v1/subscriptions/${subscriptionId}/cancel`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${basicAuth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        cancel_at_cycle_end: 1 // Safety: Let them use what they paid for until the month ends
      })
    })

    if (!response.ok) {
      const errText = await response.text()
      throw new Error(`Razorpay API Error: ${errText}`)
    }

    // 4. Update Database
    await supabaseAdmin.from('subscriptions').update({
      status: 'canceled', // This signifies it won't renew
      updated_at: new Date().toISOString()
    }).eq('user_id', user.id)

    return new Response(JSON.stringify({ success: true }), { 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    })

  } catch (error) {
    console.error(`[Cancel Subscription Error] ${error.message}`)
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } 
    })
  }
})

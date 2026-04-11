import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const payload = await req.json()
    const event = payload.event
    
    console.log(`[Razorpay Webhook] Received event: ${event}`)

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    if (event === 'subscription.charged') {
      const subscription = payload.payload.subscription.entity
      const payment = payload.payload.payment.entity
      
      console.log(`[Razorpay Webhook] Subscription charged: ${subscription.id}`)

      // Find the user by subscription ID
      const { data: subData, error: subError } = await supabaseAdmin
        .from('subscriptions')
        .select('user_id')
        .eq('provider_subscription_id', subscription.id)
        .maybeSingle()

      if (subError || !subData) {
        console.error(`[Razorpay Webhook] Could not find user for subscription ${subscription.id}`)
        return new Response(JSON.stringify({ error: 'User not found' }), { status: 400 })
      }

      const userId = subData.user_id
      const periodEnd = new Date(subscription.current_end * 1000)

      // Update subscription status and dates
      await supabaseAdmin.from('subscriptions').update({
        status: 'active',
        current_period_start: new Date(subscription.current_start * 1000).toISOString(),
        current_period_end: periodEnd.toISOString(),
        updated_at: new Date().toISOString()
      }).eq('user_id', userId)

      // Ensure profile is Pro
      await supabaseAdmin.from('profiles').update({ is_pro: true }).eq('id', userId)
    } 
    else if (event === 'subscription.cancelled' || event === 'subscription.halted') {
      const subscription = payload.payload.subscription.entity
      console.log(`[Razorpay Webhook] Subscription cancelled/halted: ${subscription.id}`)

      const { data: subData } = await supabaseAdmin
        .from('subscriptions')
        .select('user_id')
        .eq('provider_subscription_id', subscription.id)
        .maybeSingle()

      if (subData) {
        // Mark as canceled
        await supabaseAdmin.from('subscriptions').update({
          status: 'canceled',
          updated_at: new Date().toISOString()
        }).eq('user_id', subData.user_id)

        // Revoke Pro status
        await supabaseAdmin.from('profiles').update({ is_pro: false }).eq('id', subData.user_id)
      }
    }

    return new Response(JSON.stringify({ received: true }), { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200 
    })
  } catch (error) {
    console.error(`[Razorpay Webhook Error] ${error.message}`)
    return new Response(JSON.stringify({ error: error.message }), { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400 
    })
  }
})

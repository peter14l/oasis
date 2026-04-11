import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { plan = 'Pro' } = await req.json()
    const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')?.trim()
    const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')?.trim()
    const RAZORPAY_PLAN_ID = Deno.env.get('RAZORPAY_PLAN_ID')?.trim() || 'plan_Sc9w7G8vVOk3yw'

    if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) throw new Error('Credentials missing.')

    const auth = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`)

    // DIAGNOSTIC: Check if Plan exists first
    console.log(`Checking Plan ID: ${RAZORPAY_PLAN_ID}`)
    const planCheck = await fetch(`https://api.razorpay.com/v1/plans/${RAZORPAY_PLAN_ID}`, {
      method: 'GET',
      headers: { 'Authorization': `Basic ${auth}` }
    })

    if (planCheck.status === 404) {
      throw new Error(`Plan ID "${RAZORPAY_PLAN_ID}" was not found in your Razorpay account. Please ensure you created this plan in TEST MODE.`)
    } else if (planCheck.status === 401) {
      throw new Error("Razorpay API Keys are invalid. Please regenerate them in Dashboard > Settings.")
    }

    // If plan is okay, proceed to create subscription
    console.log(`Creating subscription...`)
    const response = await fetch('https://api.razorpay.com/v1/subscriptions', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        plan_id: RAZORPAY_PLAN_ID,
        total_count: 120,
        quantity: 1,
        customer_notify: 1,
        notes: { plan_name: plan }
      })
    })

    const data = await response.json()
    if (!response.ok) {
      console.error('Razorpay Error:', data)
      throw new Error(data.error?.description || 'Subscription creation failed.')
    }

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    })

  } catch (error: any) {
    console.error('Function Error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400
    })
  }
})

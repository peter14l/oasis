import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

const PAYU_KEY = Deno.env.get('PAYU_KEY') || 'YOUR_PAYU_KEY'
const PAYU_SALT = Deno.env.get('PAYU_SALT') || 'YOUR_PAYU_SALT'
const PAYU_URL = Deno.env.get('PAYU_URL') || 'https://test.payu.in/_payment' // Use https://secure.payu.in/_payment for prod

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { plan, amount, currency, email, firstname, phone } = await req.json()

    // 1. Generate unique transaction ID
    const txnid = `txn_${Date.now()}_${Math.floor(Math.random() * 1000)}`
    
    // 2. Prepare hash string
    // formula: sha512(key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5|udf6|udf7|udf8|udf9|udf10|salt)
    const productinfo = `Morrow ${plan} Subscription`
    const udf1 = '', udf2 = '', udf3 = '', udf4 = '', udf5 = '', udf6 = '', udf7 = '', udf8 = '', udf9 = '', udf10 = ''
    
    const hashString = `${PAYU_KEY}|${txnid}|${amount}|${productinfo}|${firstname}|${email}|${udf1}|${udf2}|${udf3}|${udf4}|${udf5}|${udf6}|${udf7}|${udf8}|${udf9}|${udf10}|${PAYU_SALT}`
    
    // 3. Calculate SHA512 hash
    const hashBuffer = new TextEncoder().encode(hashString)
    const hashArrayBuffer = await crypto.subtle.digest('SHA-512', hashBuffer)
    const hashHex = Array.from(new Uint8Array(hashArrayBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')

    // 4. Return the data to the frontend
    const responseData = {
      key: PAYU_KEY,
      txnid,
      amount: amount.toString(),
      productinfo,
      firstname,
      email,
      phone,
      surl: `${Deno.env.get('SITE_URL') || 'https://morrow.app'}/payment-success`,
      furl: `${Deno.env.get('SITE_URL') || 'https://morrow.app'}/payment-failure`,
      hash: hashHex,
      payu_url: PAYU_URL
    }

    return new Response(
      JSON.stringify(responseData),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

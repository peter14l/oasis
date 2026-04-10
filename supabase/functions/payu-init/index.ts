import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

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
    
    const PAYU_KEY = Deno.env.get('PAYU_KEY')
    const PAYU_SALT = Deno.env.get('PAYU_SALT')
    const PAYU_URL = Deno.env.get('PAYU_URL') || 'https://secure.payu.in/_payment'

    if (!PAYU_KEY || !PAYU_SALT) {
      throw new Error('PayU credentials are not configured on the server.')
    }

    // 1. Generate unique transaction ID
    const txnid = `txn_${Date.now()}_${Math.floor(Math.random() * 1000)}`
    
    // 2. Prepare hash string
    // formula: sha512(key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5|udf6|udf7|udf8|udf9|udf10|salt)
    const productinfo = `Oasis ${plan} Subscription`
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
      surl: `${Deno.env.get('SITE_URL')}/payment-success`,
      furl: `${Deno.env.get('SITE_URL')}/payment-failure`,
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

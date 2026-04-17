import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { code, refresh_token, redirect_uri } = await req.json()
    
    const SPOTIFY_CLIENT_ID = Deno.env.get('SPOTIFY_CLIENT_ID')
    const SPOTIFY_CLIENT_SECRET = Deno.env.get('SPOTIFY_CLIENT_SECRET')

    if (!SPOTIFY_CLIENT_ID || !SPOTIFY_CLIENT_SECRET) {
      throw new Error('Spotify credentials not configured on backend')
    }

    const authStr = btoa(`${SPOTIFY_CLIENT_ID}:${SPOTIFY_CLIENT_SECRET}`)
    
    let body = ''
    if (code) {
      body = new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: redirect_uri,
      }).toString()
    } else if (refresh_token) {
      body = new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
      }).toString()
    } else {
      // Client Credentials Flow (for public search without user login)
      body = new URLSearchParams({
        grant_type: 'client_credentials',
      }).toString()
    }

    const tokenResponse = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${authStr}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    })

    const data = await tokenResponse.json()
    
    if (!tokenResponse.ok) {
      return new Response(JSON.stringify({ error: data }), { 
        status: tokenResponse.status, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    return new Response(JSON.stringify(data), { 
      status: 200, 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500, 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })
  }
})

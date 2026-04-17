import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { query, type = 'track', limit = 20 } = await req.json()
    
    const SPOTIFY_CLIENT_ID = Deno.env.get('SPOTIFY_CLIENT_ID')
    const SPOTIFY_CLIENT_SECRET = Deno.env.get('SPOTIFY_CLIENT_SECRET')

    if (!SPOTIFY_CLIENT_ID || !SPOTIFY_CLIENT_SECRET) {
      throw new Error('Spotify credentials missing in environment variables.')
    }

    // 1. Get Access Token
    const authStr = btoa(`${SPOTIFY_CLIENT_ID}:${SPOTIFY_CLIENT_SECRET}`)
    const tokenResponse = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${authStr}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    })

    if (!tokenResponse.ok) {
      const errorData = await tokenResponse.json()
      throw new Error(`Spotify Auth Error: ${JSON.stringify(errorData)}`)
    }

    const { access_token } = await tokenResponse.json()

    // 2. Perform Search if query is provided
    if (query) {
      const searchResponse = await fetch(
        `https://api.spotify.com/v1/search?q=${encodeURIComponent(query)}&type=${type}&limit=${limit}`,
        {
          headers: { 'Authorization': `Bearer ${access_token}` },
        }
      )

      if (!searchResponse.ok) {
        const errorData = await searchResponse.json()
        throw new Error(`Spotify Search Error: ${JSON.stringify(errorData)}`)
      }

      const searchData = await searchResponse.json()
      return new Response(JSON.stringify(searchData), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // If no query, just return the token (though we'd prefer to keep it backend-only)
    return new Response(JSON.stringify({ access_token }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})

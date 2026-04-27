import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { S3Client, PutObjectCommand, GetObjectCommand } from 'https://esm.sh/@aws-sdk/client-s3@3.341.0'
import { getSignedUrl } from 'https://esm.sh/@aws-sdk/s3-request-presigner@3.341.0'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.21.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Validate User Session
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) throw new Error('Unauthorized')

    // 2. Parse Request
    const { bucket, fileId, type, method } = await req.json()
    // bucket: 'oasis' (CF), 'oasis-feed' (B2), 'oasis-ripples' (B2)
    // type: 'images', 'videos', 'documents', 'recordings', 'posts', 'ripples'
    // method: 'PUT' or 'GET'
    // fileId: should be simple filename for PUT, but for our ChatMediaService it's "userId/filename"

    let clientConfig;
    if (bucket === 'oasis') {
      // Cloudflare R2 Configuration
      clientConfig = {
        region: 'auto',
        endpoint: `https://${Deno.env.get('R2_ACCOUNT_ID')}.r2.cloudflarestorage.com`,
        credentials: {
          accessKeyId: Deno.env.get('R2_ACCESS_KEY_ID')!,
          secretAccessKey: Deno.env.get('R2_SECRET_ACCESS_KEY')!,
        },
      }
    } else if (bucket === 'oasis-feed' || bucket === 'oasis-ripples') {
      // Backblaze B2 Configuration
      clientConfig = {
        region: 'us-east-005', // Adjust based on your B2 bucket region
        endpoint: Deno.env.get('B2_ENDPOINT')!,
        credentials: {
          accessKeyId: Deno.env.get('B2_ACCESS_KEY_ID')!,
          secretAccessKey: Deno.env.get('B2_SECRET_ACCESS_KEY')!,
        },
      }
    } else {
      throw new Error('Invalid bucket')
    }

    const s3Client = new S3Client(clientConfig)
    
    // SECURITY: Enforce directory structure
    // Path: <type>/<user_id>/<file_name>
    
    // Extract filename from fileId (to prevent path traversal if user sends "../../etc")
    const fileName = fileId.split('/').pop();
    const key = `${type}/${user.id}/${fileName}`;
    
    let url;
    if (method === 'PUT') {
      const command = new PutObjectCommand({ Bucket: bucket, Key: key })
      // PUT URLs expire in 5 minutes
      url = await getSignedUrl(s3Client, command, { expiresIn: 300 })
    } else {
      const command = new GetObjectCommand({ Bucket: bucket, Key: key })
      // GET URLs expire in 1 hour
      url = await getSignedUrl(s3Client, command, { expiresIn: 3600 })
    }

    return new Response(
      JSON.stringify({ url, key }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

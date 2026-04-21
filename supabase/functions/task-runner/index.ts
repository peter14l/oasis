import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, serviceRoleKey)

  try {
    const payload = await req.json()
    const { record, type } = payload // record is the task_queue entry from webhook

    // Only process if it's an INSERT or if manually triggered
    if (type !== 'INSERT' && !payload.manual) {
      return new Response(JSON.stringify({ message: "Not an insert event" }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    const task = record
    if (task.status !== 'pending') {
      return new Response(JSON.stringify({ message: "Task is not pending" }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    // 1. Mark as processing
    await supabase
      .from('task_queue')
      .update({ status: 'processing', processed_at: new Date().toISOString() })
      .eq('id', task.id)

    let result = null
    let error = null

    try {
      // 2. Route based on task_type
      switch (task.task_type) {
        case 'transcription':
          result = await handleTranscription(task.payload, supabase)
          break;
        case 'ping':
          result = { message: "Pong", timestamp: new Date().toISOString() }
          break;
        default:
          throw new Error(`Unknown task type: ${task.task_type}`)
      }

      // 3. Mark as completed
      await supabase
        .from('task_queue')
        .update({ 
          status: 'completed', 
          result: result,
          updated_at: new Date().toISOString() 
        })
        .eq('id', task.id)

    } catch (taskErr) {
      console.error(`[Task Error] ${taskErr.message}`)
      // 4. Mark as failed
      await supabase
        .from('task_queue')
        .update({ 
          status: 'failed', 
          error: taskErr.message,
          updated_at: new Date().toISOString() 
        })
        .eq('id', task.id)
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })

  } catch (error) {
    console.error(`[Internal Error] ${error.message}`)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" }
    })
  }
})

async function handleTranscription(payload: any, supabase: any) {
  const { message_id, audio_url } = payload
  if (!message_id || !audio_url) throw new Error("Missing message_id or audio_url in payload")

  const openAIKey = Deno.env.get('OPENAI_API_KEY')
  if (!openAIKey) throw new Error("Missing OPENAI_API_KEY")

  // Download audio
  const audioResponse = await fetch(audio_url)
  if (!audioResponse.ok) throw new Error(`Failed to download audio: ${audioResponse.statusText}`)
  const audioBlob = await audioResponse.blob()

  // Prepare OpenAI request
  const formData = new FormData()
  formData.append('file', audioBlob, 'audio.m4a')
  formData.append('model', 'whisper-1')
  formData.append('response_format', 'json')

  // Request Transcription
  const whisperResponse = await fetch('https://api.openai.com/v1/audio/transcriptions', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${openAIKey}` },
    body: formData
  })

  const whisperResult = await whisperResponse.json()
  if (!whisperResponse.ok) throw new Error(whisperResult.error?.message || 'Whisper API failed')

  const transcriptData = {
    message_id,
    text: whisperResult.text,
    language: whisperResult.language || 'en',
    confidence: 1.0
  }

  // Persist to transcripts table
  const { error: upsertErr } = await supabase
    .from('message_transcripts')
    .upsert(transcriptData)

  if (upsertErr) throw upsertErr

  return transcriptData
}

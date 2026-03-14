-- Alter call_signaling table to match WebRTC ICE candidate structure expected by CallService
ALTER TABLE call_signaling DROP COLUMN IF EXISTS type;
ALTER TABLE call_signaling DROP COLUMN IF EXISTS data;

ALTER TABLE call_signaling ADD COLUMN IF NOT EXISTS candidate TEXT NOT NULL;
ALTER TABLE call_signaling ADD COLUMN IF NOT EXISTS "sdpMid" TEXT;
ALTER TABLE call_signaling ADD COLUMN IF NOT EXISTS "sdpMLineIndex" INTEGER;

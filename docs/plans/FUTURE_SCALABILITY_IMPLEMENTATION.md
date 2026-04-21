# Future Scalability Implementation: Redis & SFU

This document outlines the implementation details for the advanced scalability features added to the Oasis platform.

---

## 📞 SFU Signaling Readiness
The WebRTC system has been refactored to support both **Mesh** and **SFU (Selective Forwarding Unit)** architectures.

### Changes:
1. **Config:** Added `isSFUEnabled` and `sfuServerUrl` to `SupabaseConfig`.
2. **CallService:** 
   - Refactored `_subscribeToParticipants` to detect SFU mode.
   - In SFU mode, the client initiates a single `RTCPeerConnection` to a virtual `SFU_SERVER` instead of multiple peer-to-peer connections.
   - Signaling logic is preserved using the existing E2EE Signal Protocol layer.

### Why this scales:
- **Mesh:** Bandwidth and CPU grow at $O(N^2)$ for $N$ participants. Good for 1-on-1 or small groups (3-4).
- **SFU:** Bandwidth and CPU grow at $O(N)$. Essential for large group calls (10+ participants) and screen sharing.

---

## 💾 Redis Integration Strategy
To handle high-frequency data that would overwhelm PostgreSQL, we have laid the groundwork for Redis integration.

### Recommended Provider: **Upstash** (Serverless Redis)
- **Why:** Works natively with Deno/Supabase Edge Functions via HTTP (no persistent TCP connection required).

### Implementation Steps (for Edge Functions):
1. **Secrets:**
   ```bash
   supabase secrets set REDIS_URL=https://your-upstash-db.upstash.io
   supabase secrets set REDIS_TOKEN=your_token
   ```
2. **Deno Client:**
   ```typescript
   import { Redis } from "https://esm.sh/@upstash/redis"
   
   const redis = new Redis({
     url: Deno.env.get('REDIS_URL'),
     token: Deno.env.get('REDIS_TOKEN'),
   })
   ```

### Use Cases:
- **Presence:** Storing "Last Seen" and "Online" status (updates every 30s).
- **Trending Feed:** Caching the most popular posts for 5-minute intervals to avoid heavy SQL aggregations.
- **Rate Limiting:** Implementing custom API rate limits for premium features.

---

## 🛠️ Cold-Start Optimizations
To reduce Edge Function latency:
1. **Minimize Imports:** Use specific sub-module imports instead of large bundle imports.
2. **ESM.sh Pinning:** Pin versions of libraries (e.g., `@supabase/supabase-js@2.39.0`) to improve Deno's caching performance.
3. **One-Shot Policy:** If memory usage is high, set `policy = "oneshot"` in `config.toml` for critical functions.

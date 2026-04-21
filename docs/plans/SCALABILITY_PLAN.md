# Oasis Scalability & Performance Plan

This document outlines the strategy for implementing dynamic scaling, caching, and queuing mechanisms to ensure the system remains stable and cost-effective as the user base grows.

---

## 🛑 Current Scalability Bottlenecks

### 1. Synchronous Heavy Tasks
- **Issue:** Voice transcription (`transcribe-voice`) and Push Notifications are currently synchronous.
- **Risk:** Execution timeouts (Deno limits), high concurrency usage, and user-perceived latency.
- **Current Pattern:** `App -> Edge Function (Wait) -> External API (OpenAI/FCM) -> DB -> App`.

### 2. Database Write Amplification
- **Issue:** Group chat triggers update `unread_count` for every participant on every message.
- **Risk:** $O(N)$ database operations per message, leading to severe IOPS exhaustion in large groups.

### 3. Lack of Global Asset Delivery
- **Issue:** Reliance on default storage egress without a dedicated CDN edge layer or image optimization.
- **Risk:** High latency for international users and excessive bandwidth costs for high-resolution media.

---

## 🛠️ Proposed Solution: CDN + Cache + Queue

### 🚀 Phase 1: Background Task Queue (Immediate)
To prevent system crashes during bursts of activity, we will move heavy tasks to an asynchronous queue.

#### Implementation Steps:
1. **Queue Table:**
   ```sql
   CREATE TABLE public.task_queue (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     task_type TEXT NOT NULL, -- 'transcription', 'notification_burst', 'cleanup'
     payload JSONB NOT NULL,
     status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
     result JSONB,
     error TEXT,
     created_at TIMESTAMPTZ DEFAULT now(),
     processed_at TIMESTAMPTZ
   );
   ```
2. **Webhook Trigger:** Configure Supabase to trigger a `task-runner` Edge Function on `INSERT` to `task_queue`.
3. **Async UI:** The Flutter app inserts a task and uses `Supabase Realtime` to listen for the `status` update, showing a progress indicator instead of blocking.

### 💾 Phase 2: Multi-Layer Caching (Short-term)
Reduce database load by implementing caching at both the Edge and the Database level.

#### Implementation Steps:
1. **Edge Caching:** 
   - Implement `Cache-Control` headers in Edge Function responses.
   - Use in-memory caching for OAuth tokens (FCM/Google) to avoid re-auth on every call.
2. **Client-Side SQLite:**
   - Deepen the use of `sqflite` for relational data to avoid redundant network fetches for profiles and history.
3. **Redis (Upstream):**
   - For high-traffic features (e.g., "Trending" or "Live Counts"), integrate a Redis layer between Edge Functions and PostgreSQL.

### 🌐 Phase 3: CDN & Asset Optimization (Medium-term)
Improve global performance and reduce egress costs.

#### Implementation Steps:
1. **CDN Integration:** 
   - Point a custom domain (via Cloudflare) to Supabase Storage.
   - Configure "Cache Everything" rules for the `/storage/v1/object/public/` path.
2. **Image Transformation:**
   - Implement an image proxy (or use Supabase's Pro transformation) to serve WebP/AVIF formats and resized thumbnails.
   - `https://cdn.oasis.app/render?width=300&url=...`

---

## 📈 Scalability Success Metrics

| Component | Metric | Target |
| :--- | :--- | :--- |
| **Transcription** | Max Latency (Processing) | < 10s (Async) |
| **Notifications** | Concurrency Limit | 10k+ simultaneous |
| **Media** | Cache Hit Ratio (CDN) | > 85% |
| **Database** | IOPS Utilization | < 40% at peak |

---

## 📝 Implementation Timeline

1. **Week 1:** Database Queue schema and `task-runner` Edge Function.
2. **Week 2:** Refactor Voice Transcription to use the Queue.
3. **Week 3:** Cloudflare CDN setup and Image Transformation logic.
4. **Week 4:** Stress testing and IOPS monitoring.

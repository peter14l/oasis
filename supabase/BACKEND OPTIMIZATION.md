# Oasis Backend Optimization & Scaling Guide

This document provides a technical roadmap for optimizing the Supabase/PostgreSQL backend of Oasis. Use this as a reference for refactoring or implementing new features to ensure they are cost-effective, scalable, and secure.

---

## 🔒 1. Security Best Practices (MANDATORY)

### A. Row Level Security (RLS)
- **Rule:** Every single table in the `public` schema **MUST** have RLS enabled.
- **Vibe Code:** Never use `USING (true)` for anything other than truly public data. Always validate against `auth.uid()`.
- **Policy Audit:** Periodically check for "leaky" policies where `INSERT` or `UPDATE` checks are missing or too broad.

### B. Security Definer Functions
- **Rule:** When using `SECURITY DEFINER` (to bypass RLS for system tasks), **ALWAYS** set a safe `search_path`.
- **SQL Pattern:**
  ```sql
  CREATE OR REPLACE FUNCTION my_secure_function()
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public, auth -- <--- CRITICAL for security
  AS $$ ... $$;
  ```
- **Why:** This prevents "search path hijacking" attacks where an attacker creates a malicious function with the same name in a different schema.

### C. Input Validation & Constraints
- **Rule:** Don't rely solely on the frontend. Use PostgreSQL `CHECK` constraints for data integrity (e.g., username length, valid enum values).
- **Triggers:** Use `BEFORE INSERT OR UPDATE` triggers to sanitize inputs or enforce complex business rules that RLS cannot handle.

### D. Secret Management
- **Rule:** **NEVER** hardcode API keys, secrets, or sensitive configuration in SQL files.
- **Vibe Code:** Use Supabase Vault or environment variables for sensitive data.

### E. Service Role Key
- **Rule:** The `service_role` key **MUST NEVER** be exposed to the client side. It bypasses all RLS. Use it only in secure Edge Functions or trusted backend environments.

---

## 🚀 2. Critical Scaling Bottlenecks

### A. Chat Write Amplification ($O(N)$ Problem)
**Current:** `handle_new_message()` trigger updates `unread_count` for every participant on every message.
**Fix:** 
- In group chats, avoid updating a counter row for every user.
- **Alternative:** Calculate `unread_count` dynamically on the client by comparing a user's `last_read_at` timestamp with the message's `created_at`.
- **Optimization:** If a counter is required, use a "counter cache" or batch updates rather than per-row triggers.

### B. Typing Indicators (IOPS Drain)
**Current:** Writing `typing_indicators` to a database table.
**Fix:**
- **DO NOT** use the database for typing status.
- **Vibe Code:** Use Supabase Realtime **Broadcast** or **Presence**. These are ephemeral, memory-based events that don't touch the disk or count against database IOPS.

### C. RLS Recursion & Performance
**Current:** Nested `EXISTS` clauses in `profiles` and `posts` SELECT policies.
**Fix:**
- Use `auth.uid()` directly whenever possible.
- Wrap complex RLS logic in `SECURITY DEFINER` functions to bypass RLS overhead within the check itself.

---

## 💰 3. Cost Optimization (Supabase Billing)

### A. Realtime Channel Management
- **Rule:** Only enable Realtime on tables that require instant UI updates (e.g., `messages`, `notifications`).
- **Optimization:** Avoid `REPLICA IDENTITY FULL` on high-traffic tables unless absolutely necessary for DELETE event data. Every byte in the WAL sent over Realtime costs money and CPU.

### B. Storage & Egress
- **Rule:** 150MB file limits will spike egress costs.
- **Vibe Code:** Implement client-side compression for images and videos before upload. 
- **TTL:** Ensure the `delete_expired_messages()` function is actually running via `pg_cron` or an Edge Function to keep the `messages` table lean.

---

## 🛠️ 4. Implementation Checklist for AI Agents

1. [ ] **Security Audit:** Verify RLS and `search_path` on all functions.
2. [ ] **Refactor Typing:** Move `TypingIndicator` logic from SQL to Realtime Broadcast.
3. [ ] **Unread Logic:** Switch from `unread_count` column to a `last_read_message_id` reference in `conversation_participants`.
4. [ ] **Index Audit:** Add composite indexes for feed generation.
5. [ ] **Cron Setup:** Enable `pg_cron` to automate the cleanup of ephemeral data.

---

## 📝 SQL Patterns to Avoid
- `SELECT COUNT(*)` on large tables without a filter.
- Triggers that perform multiple `UPDATE` calls on unrelated tables.
- Storing large JSON blobs in tables that are frequently scanned (use `JSONB` or separate metadata tables).

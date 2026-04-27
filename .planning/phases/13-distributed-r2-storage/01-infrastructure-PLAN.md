# Plan: R2 Infrastructure & S3 Client Setup (Plan 01)

## Goal
Establish the foundational S3-compatible storage services for Cloudflare R2 and Backblaze R2, including secure credential management and media encryption helpers.

## Tasks

### 1. Environment & Configuration
- [x] Update `supabase/supabase/functions/.env` (and `.env.example`) with R2/B2 credentials (Account IDs, Access Keys, Secrets) for the Edge Functions.
- [x] Create `lib/core/config/r2_config.dart` to manage bucket names and endpoints.
- [x] Add documentation in `docs/R2_STORAGE_SETUP.md` explaining the Pre-Signed URL architecture.

### 2. S3 Client & Edge Function Implementation
- [x] Create Supabase Edge Function `generate-presigned-url` (TypeScript/Deno):
    - Validates user session.
    - Generates pre-signed PUT/GET URLs for Cloudflare R2 (`oasis` bucket) or Backblaze B2 (`oasis-feed`, `oasis-ripples`).
    - Enforces path isolation (`<bucket>/<type>/<user_id>/<file_id>`).
- [x] Implement `lib/services/s3_storage_service.dart`:
    - Calls Edge Function to get pre-signed URL.
    - Uses `dio` to perform the actual PUT/GET requests directly to B2/R2 using the signed URL.
    - Methods: `uploadFile`, `getPresignedUrl`, `deleteFile` (via edge function or RPC).

### 3. Media Encryption Infrastructure
- [x] Extend `lib/features/messages/data/encryption_service.dart` with:
    - `encryptFile(File file)`: Generates AES key, encrypts file, returns `(encryptedBytes, encryptedKeyMap)`.
    - `decryptFile(Uint8List encryptedBytes, Map<String, dynamic> encryptedKeys)`: Decrypts AES key with RSA, then decrypts bytes.
- [x] Create `lib/services/media_cache_service.dart`:
    - Manage local directory structure: `ApplicationDocumentsDirectory/oasis/media/...`.
    - Map remote URLs/FileIDs to local paths using `hive` or `shared_preferences`.

### 4. Database Schema (Supabase)
- [x] Create migration `20260427000000_r2_storage_metadata.sql`:
    - Add `media_encryption_keys` table to store encrypted AES keys for chat messages.
    - Add `storage_provider` column to `posts` and `ripples` (default 'supabase', new 'backblaze').

## Verification
- [ ] Unit test `S3StorageService` with a mock S3 server or test bucket.
- [ ] Unit test `EncryptionService.encryptFile` and `decryptFile` for integrity.
- [ ] Verify local directory creation on different platforms (Android/iOS/Desktop).

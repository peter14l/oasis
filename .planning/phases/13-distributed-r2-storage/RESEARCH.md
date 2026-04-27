# Research: Distributed R2 Storage Integration

## 1. Cloudflare R2 vs Backblaze R2
- **Backblaze R2 (B2)**: 
  - Cost-effective for larger storage (Feeds/Ripples).
  - S3 compatible.
  - No egress fees (limited per month).
- **Cloudflare R2**:
  - Zero egress fees.
  - Global performance.
  - Better for frequent access (Chat attachments).
  - S3 compatible.

## 2. Technical Stack
- **S3 Client**: `aws_common`, `aws_signature_v4`, or `dio` with manual S3 signatures.
- **Local Caching**: `path_provider` for local storage, `sqflite` or `hive` for tracking local file paths.
- **Encryption**: `EncryptionService` (AES-256) per file, RSA-encrypted AES keys.

## 3. Storage Hierarchy
### Cloudflare R2 (oasis bucket)
- `oasis/chat/documents/<user_id>/<file_id>`
- `oasis/chat/recordings/<user_id>/<file_id>`
- `oasis/chat/videos/<user_id>/<file_id>`
- `oasis/chat/images/<user_id>/<file_id>`

### Backblaze R2
- `oasis-feed/posts/<user_id>/<file_id>`
- `oasis-ripples/videos/<user_id>/<file_id>`

## 4. WhatsApp-style Logic
- **Upload**: Encrypt locally -> Upload to R2 -> Store local path in DB/Cache.
- **Download**: 
  1. Check local path in Cache.
  2. If file exists on disk, display it.
  3. If not, check if remote URL exists.
  4. If remote exists, show "Download" button.
  5. On download: Fetch -> Decrypt -> Save to local storage -> Update Cache.

## 5. Security & Privacy
- **E2EE**: AES keys are never stored in plain text.
- **Isolation**: Paths prefixed by `user_id` (though bucket-level isolation requires signed URLs or proxy).
- **Signed URLs**: Use S3 Presigned URLs for temporary access if public access is disabled.

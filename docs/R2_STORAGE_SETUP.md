# Distributed R2 Storage Setup Guide

## Overview
Oasis uses a distributed storage architecture to optimize for cost, performance, and privacy.

- **Backblaze R2**: Used for high-volume public/semi-private content (Feeds, Ripples).
- **Cloudflare R2**: Used for high-frequency private content (Chat attachments).

## Bucket Configuration

### 1. Cloudflare R2 (Chat)
- **Bucket Name**: `oasis`
- **Region**: `auto`
- **Endpoint**: `https://<account_id>.r2.cloudflarestorage.com`
- **Directories**:
    - `chat/documents/<user_id>/`
    - `chat/recordings/<user_id>/`
    - `chat/videos/<user_id>/`
    - `chat/images/<user_id>/`

### 2. Backblaze R2 (Feed & Ripples)
- **Bucket Name**: `oasis-feed`, `oasis-ripples`
- **Endpoint**: `s3.<region>.backblazeb2.com`
- **Directories**:
    - `posts/<user_id>/`
    - `videos/<user_id>/`

## Security Practices
1. **E2EE for Chat**: All files in the `oasis` bucket are encrypted with a unique AES-256 key before upload. The AES key is then RSA-encrypted for each recipient.
2. **User Isolation**: All paths are prefixed with the owner's `user_id`.
3. **Signed URLs**: For private Feed content, use S3 Presigned URLs with short expiration.
4. **No Public Access**: Cloudflare R2 bucket should have public access disabled; media is served via signed URLs or authenticated proxy if necessary.

## Local Caching (WhatsApp Logic)
1. **Upload**: Encrypt -> Upload -> Store locally in `ApplicationDocumentsDirectory/oasis/`.
2. **Display**: Always prefer local file if available.
3. **Fallback**: Show "Download" button if local file is missing but remote exists.
4. **Decryption**: Decrypt only on-the-fly or into temporary secure storage.

# Plan: Secure Chat Media & Cloudflare R2 (Plan 03)

## Goal
Implement WhatsApp-style chat media handling with E2EE, local caching, and Cloudflare R2 storage, including a fallback "Download" button for missing local files.

## Tasks

### 1. R2 Upload with E2EE
- [ ] Modify `ChatMediaService.uploadChatMedia`:
    - Integrate `EncryptionService.encryptFile` to encrypt media locally before upload.
    - Use `S3StorageService` (Cloudflare) to upload encrypted bytes.
    - Bucket: `oasis`.
    - Path: `oasis/chat/<type>/<user_id>/<file_id>`.
- [ ] Save the encrypted AES key map to the `media_encryption_keys` table (Supabase) linked to the message.

### 2. WhatsApp-style Media Logic
- [ ] Implement `MediaCacheService`:
    - Save uploaded/downloaded files to: `ApplicationDocumentsDirectory/oasis/chat/<type>/<file_id>`.
    - Maintain a Hive database mapping `remote_url` to `local_path`.
- [ ] Update `ChatProvider.onMessageReceived`:
    - Automatically trigger background download if "auto-download" is enabled for that media type.
    - Store local path in `MediaCacheService`.

### 3. UI: Download Button & Preview
- [ ] Update `ImageBubble`, `VideoBubble`, and `DocumentBubble`:
    - Logic: `if (localFileExists) showLocal() else if (remoteUrlExists) showDownloadButton() else showBrokenIcon()`.
    - Implement `DownloadButton` overlay on the media preview.
    - Add "Download" action that triggers: `S3 Download -> EncryptionService Decrypt -> Save to Local -> Refresh UI`.
- [ ] Implement "Clearly displayed preview":
    - Use low-res thumbnails or blurred placeholders while media is not downloaded.

### 4. User-Specific Isolation & Security
- [ ] Ensure all R2 paths are prefixed with `user_id`.
- [ ] Implement Row-Level Security (RLS) or signed URL logic to ensure only message participants can fetch the encrypted AES keys.
- [ ] Add "Clear Media Cache" option in settings to delete local files (leaving them only on R2).

## Verification
- [ ] Send an image, verify it's encrypted on R2 and saved locally.
- [ ] Delete the local file, verify the "Download" button appears in chat.
- [ ] Click "Download", verify the file is restored and viewable.
- [ ] Verify another user (not in the chat) cannot decrypt or access the media.

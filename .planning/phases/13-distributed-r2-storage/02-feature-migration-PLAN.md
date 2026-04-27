# Plan: Feed & Ripples Migration to Backblaze R2 (Plan 02)

## Goal
Migrate new content creation for Feeds and Ripples to use Backblaze R2 while maintaining backward compatibility for existing Supabase-hosted media.

## Tasks

### 1. Ripples Migration
- [x] Modify `RippleRemoteDatasource.uploadRippleVideo`:
    - Switch from `_supabase.storage` to `S3StorageService` (Backblaze).
    - Use bucket `oasis-ripples`.
    - Path: `<user_id>/<file_id>.<ext>`.
- [x] Update `RippleRemoteDatasource.createRipple`:
    - Save `storage_provider: 'backblaze'` in the DB record.
- [x] Update `RippleEntity` and its UI components to handle both Supabase and R2 URLs.

### 2. Feed/Post Migration
- [x] Modify `PostService.createPost`:
    - Switch media uploads to `S3StorageService` (Backblaze).
    - Use bucket `oasis-feed`.
- [x] Update post insertion logic to store `storage_provider` metadata.
- [x] Ensure `PostCard` handles R2 URLs correctly (signed URLs if private).

### 3. Cleanup & Optimization
- [x] Implement `deleteMedia` logic in `S3StorageService` for post/ripple deletion.
- [x] Add basic retry logic for R2 uploads (exponential backoff).

## Verification
- [ ] Create a new Ripple and verify it is stored in Backblaze R2.
- [ ] Create a new Post with multiple images and verify Backblaze storage.
- [ ] Verify that old Supabase-hosted posts/ripples still load and display correctly.
- [ ] Test deletion of R2-hosted content.

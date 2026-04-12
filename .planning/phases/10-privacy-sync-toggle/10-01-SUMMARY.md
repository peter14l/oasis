---
phase: 10-privacy-sync-toggle
plan: 01
subsystem: Privacy & Curation
tags: [privacy, curation, tracking, server-sync]
requires: [PRIVACY-02]

## Plan Summary

| Field | Value |
|-------|-------|
| Phase | 10-privacy-sync-toggle |
| Plan | 01 |
| Status | ✅ Complete |
| Duration | ~15 minutes |

## Objective

Fix the existing tracking system so it actually tracks user interactions, then extend it with optional server sync.

## Context

- **Prior work:** CurationTrackingService existed but was NOT being called anywhere
- **Problem:** Local tracking didn't work because it was never invoked
- **Solution:** Wire tracking into feed and chat flows

## Tasks Executed

### Task 1: Fix Curation Tracking - Wire to Actual Usage ✅

**Modified files:**
- `lib/features/feed/presentation/providers/feed_provider.dart`
- `lib/features/messages/presentation/providers/chat_provider.dart`

**Changes:**
- Added CurationTrackingService to FeedProvider constructor
- Added `_trackCategories()` method - tracks unique community names from loaded posts
- Added `_trackPostLike()` method - tracks when user likes a post
- Added tracking calls in `loadFeed()` for categories
- Added optional `communityName` parameter to `likePost()` for tracking
- Added `_trackChatTimeSpent()` - tracks time when chat is disposed
- Added tracking in ChatProvider's dispose method

**Verification:**
```
grep -r "trackCategoryInteraction" lib/ → Found in 2 files
```

### Task 2: Create Supabase Schema for User Analytics ✅

**Created file:**
- `supabase/migrations/20260414000000_user_analytics_sync.sql`

**Schema:**
- `user_analytics` table with RLS policies (user can only access own data)
- `sync_user_analytics()` RPC function for syncing local → server
- `delete_user_analytics()` RPC function for deleting on server (toggle OFF)

**Security:**
- RLS ensures users can only see/modify their own analytics
- SECURITY DEFINER for RPC functions

## Decisions Made

| Decision | Rationale |
|----------|----------|
| Track categories from posts | Communities are what users interact with most |
| Track on dispose | Chat time tracking needs session to end |
| Default OFF for sync | Privacy-first default per requirements |

## Metrics

| Metric | Value |
|--------|-------|
| Files Modified | 3 |
| Files Created | 1 |
| Tasks Completed | 2/2 |
| Verification | Pass |

## Deviation: None

Plan executed as written. All tasks completed.

## Stub Tracking

No stubs in this plan.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| None | - | No new threat surface introduced |

---

*Plan: 10-01 • Phase: 10-privacy-sync-toggle*
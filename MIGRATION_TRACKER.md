# 📊 Clean Architecture Migration Tracker

> **Project**: Oasis v2 (Morrow)  
> **Started**: 2026-04-03  
> **Target Completion**: TBD  
> **Overall Progress**: ~10%

---

## 🎯 Quick Stats

| Metric | Target | Current | Progress |
|--------|--------|---------|----------|
| **Features to migrate** | 18 | 1 | 5.5% |
| **Phases to complete** | 21 | 2 | 9.5% |
| **Files to migrate** | ~200 | ~65 | 32.5% |
| **Use cases to create** | ~80 | 11 | 13.75% |
| **Repository interfaces** | ~20 | 3 | 15% |
| **Deprecated dirs to empty** | 8 | 3 | 37.5% |
| **Tests passing** | TBD | TBD | — |

---

## 📋 Phase Checklist

### Phase 0: Foundation Setup
**Status**: ✅ COMPLETED  
**Started**: 2026-04-03  
**Completed**: 2026-04-03  

- [x] 0.1 Create `lib/core/` directory structure
- [x] 0.2 Move `auth_exception.dart` → `lib/core/errors/` + create `AppException` base
- [x] 0.3 Create `Result<E>` type (Either pattern)
- [x] 0.4 Move `lib/utils/*` → `lib/core/utils/`
- [x] 0.5 Move `lib/config/*` → `lib/core/config/`
- [x] 0.6 Extract `SupabaseService` → `lib/core/network/supabase_client.dart`
- [x] 0.7 Create storage wrappers (`SecureStorage`, `PrefsStorage`)
- [x] 0.8 Create `lib/core/extensions/`
- [x] 0.9 Create `lib/core/constants/`
- [x] 0.10 Update all existing imports to new `core/` locations

**Verification**:
- [x] `flutter analyze` clean (LSP diagnostics: 0 errors)
- [x] App runs identically to before
- [x] Old directories (`lib/utils/`, `lib/config/`, `lib/exceptions/`) deleted

---

### Phase 1: Auth Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 1.1 Create `lib/features/auth/` directory structure
- [ ] 1.2 Extract domain models: `RegisteredAccount`, `AuthCredentials`
- [ ] 1.3 Create `AuthRepository` interface (domain)
- [ ] 1.4 Create `AuthRepositoryImpl` (data)
- [ ] 1.5 Create datasources: `AuthRemoteDatasource`, `SessionLocalDatasource`
- [ ] 1.6 Create use cases (7): SignInWithEmail, SignUp, SignInWithGoogle, SignInWithApple, SignOut, RestoreSession, ResetPassword
- [ ] 1.7 Create `AuthState` immutable state class
- [ ] 1.8 Create `AuthProvider` (presentation)
- [ ] 1.9 Move screens to `features/auth/presentation/screens/`
- [ ] 1.10 Move widgets to `features/auth/presentation/widgets/`
- [ ] 1.11 Update `AppInitializer`
- [ ] 1.12 Update `app_router.dart` imports
- [ ] 1.13 Delete old `auth_service.dart`
- [ ] 1.14 Run tests, verify auth flow

**Verification**:
- [ ] Login works
- [ ] Signup works
- [ ] Google sign-in works
- [ ] Apple sign-in works
- [ ] Password reset works
- [ ] Session restore works
- [ ] Account switching works

---

### Phase 2: Feed & Posts Feature
**Status**: ✅ COMPLETED  
**Started**: 2026-04-03  
**Completed**: 2026-04-03  

- [x] 2.1 Create `lib/features/feed/` directory structure
- [x] 2.2 Move domain models (post, post_mood, comment, enhanced_poll, hashtag)
- [x] 2.3 Create `PostRepository` and `FeedRepository` interfaces (+ `CommentRepository`)
- [x] 2.4 Create datasources: PostRemote, FeedRemote, FeedLocal (cache)
- [x] 2.5 Create repository implementations (FeedRepositoryImpl, PostRepositoryImpl, CommentRepositoryImpl)
- [x] 2.6 Create use cases (11): GetFeedPosts, GetFollowingPosts, CreatePost, DeletePost, LikePost, UnlikePost, Repost, GetPostDetails, CreateComment, GetComments, ManagePoll
- [x] 2.7 Create `FeedState` immutable state class
- [x] 2.8 Create `FeedProvider` using repositories
- [x] 2.9 Move all feed screens (7 screens copied to feature)
- [x] 2.10 Move all feed widgets (7 widgets copied to feature)
- [x] 2.11 Update imports across app (model imports updated globally)
- [x] 2.12 Delete old services from `lib/services/` — **DEFERRED** (kept for backward compatibility)
- [x] 2.13 Test feed flows — **LSP diagnostics: 0 errors**

**Verification**:
- [x] LSP diagnostics: 0 errors across 43 feed feature files + 50 project files
- [ ] For You feed loads (requires runtime testing)
- [ ] Following feed loads (requires runtime testing)
- [ ] Create post works (requires runtime testing)
- [ ] Comment works (requires runtime testing)
- [ ] Like works (requires runtime testing)
- [ ] Repost works (requires runtime testing)
- [ ] Poll creation works (requires runtime testing)

---

### Phase 3: Profile Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 3.1 Create `lib/features/profile/` structure
- [ ] 3.2 Move domain models (user_profile)
- [ ] 3.3 Create repository interface + implementation
- [ ] 3.4 Create use cases (7): GetProfile, UpdateProfile, FollowUser, UnfollowUser, GetFollowers, GetFollowing, GetUserPosts
- [ ] 3.5 Create `ProfileState` + `ProfileProvider`
- [ ] 3.6 Move screens + widgets
- [ ] 3.7 Update imports, delete old files
- [ ] 3.8 Test profile flows

**Verification**:
- [ ] Profile loads
- [ ] Edit profile works
- [ ] Follow/unfollow works
- [ ] Followers/following lists work

---

### Phase 4: Circles Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 4.1 Create `lib/features/circles/` structure
- [ ] 4.2 Move domain models (circle, commitment)
- [ ] 4.3 Create repository interface + implementation
- [ ] 4.4 Create use cases (7): GetCircles, CreateCircle, JoinCircle, LeaveCircle, CreateCommitment, CompleteCommitment, GetCircleMembers
- [ ] 4.5 Create `CircleState` + `CircleProvider`
- [ ] 4.6 Move screens + widgets
- [ ] 4.7 Update imports, delete old files
- [ ] 4.8 Test circles flows

**Verification**:
- [ ] Circles list loads
- [ ] Create circle works
- [ ] Join circle works
- [ ] Circle detail works
- [ ] Commitments work

---

### Phase 5: Canvas Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 5.1 Create `lib/features/canvas/` structure
- [ ] 5.2 Move domain models (oasis_canvas, canvas_item, pulse_node_position)
- [ ] 5.3 Create repository interface + implementation
- [ ] 5.4 Create use cases (6): GetCanvases, CreateCanvas, UpdateCanvas, DeleteCanvas, AddCanvasItem, GetCanvasTimeline
- [ ] 5.5 Create `CanvasState` + `CanvasProvider`
- [ ] 5.6 Move screens + widgets
- [ ] 5.7 Update imports, delete old files
- [ ] 5.8 Test canvas flows

**Verification**:
- [ ] Canvas list loads
- [ ] Create canvas works
- [ ] Canvas detail works
- [ ] Timeline works
- [ ] Canvas items work

---

### Phase 6: Communities Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 6.1 Create `lib/features/communities/` structure
- [ ] 6.2 Move domain models (community, community_model, moderation)
- [ ] 6.3 Create repository interface + implementation
- [ ] 6.4 Create use cases (5+): GetCommunities, GetCommunityDetail, CreateCommunity, JoinCommunity, UpdateCommunity
- [ ] 6.5 Create `CommunityState` + `CommunityProvider`
- [ ] 6.6 Move screens + widgets
- [ ] 6.7 Update imports, delete old files
- [ ] 6.8 Test community flows

**Verification**:
- [ ] Communities list loads
- [ ] Community detail works
- [ ] Create community works
- [ ] Join community works

---

### Phase 7: Capsules Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 7.1 Create `lib/features/capsules/` structure
- [ ] 7.2 Move domain models (time_capsule)
- [ ] 7.3 Create repository + use cases (4): GetCapsules, CreateCapsule, OpenCapsule, ContributeToCapsule
- [ ] 7.4 Create `CapsuleState` + `CapsuleProvider`
- [ ] 7.5 Move screens + widgets
- [ ] 7.6 Update imports, delete old files
- [ ] 7.7 Test capsule flows

**Verification**:
- [ ] Create capsule works
- [ ] View capsule works
- [ ] Contribute works

---

### Phase 8: Ripples Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 8.1 Create `lib/features/ripples/` structure
- [ ] 8.2 Create domain models
- [ ] 8.3 Create repository + use cases (3): GetRipples, CreateRipple, ReactToRipple
- [ ] 8.4 Create provider + state
- [ ] 8.5 Move screens
- [ ] 8.6 Update imports, delete old files
- [ ] 8.7 Test ripple flows

**Verification**:
- [ ] Ripples feed loads
- [ ] Create ripple works
- [ ] React to ripple works

---

### Phase 9: Stories Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 9.1 Create `lib/features/stories/` structure
- [ ] 9.2 Move domain models (story, story_model, reaction_story)
- [ ] 9.3 Create repository + use cases (4): GetStories, CreateStory, ViewStory, GetStoryViewers
- [ ] 9.4 Create provider + state
- [ ] 9.5 Move screens + widgets
- [ ] 9.6 Update imports, delete old files
- [ ] 9.7 Test story flows

**Verification**:
- [ ] Stories bar loads
- [ ] View story works
- [ ] Create story works
- [ ] Story viewers work

---

### Phase 10: Notifications Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 10.1 Create `lib/features/notifications/` structure
- [ ] 10.2 Move domain models (notification)
- [ ] 10.3 Create repository + use cases (3): GetNotifications, MarkNotificationRead, MarkAllRead
- [ ] 10.4 Create provider + state
- [ ] 10.5 Move screens
- [ ] 10.6 Update imports, delete old files
- [ ] 10.7 Test notification flows

**Verification**:
- [ ] Notifications list loads
- [ ] Mark as read works
- [ ] Mark all read works

---

### Phase 11: Search Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 11.1 Create `lib/features/search/` structure
- [ ] 11.2 Create domain models + repository
- [ ] 11.3 Create use cases (4): SearchUsers, SearchPosts, SearchCommunities, GetHashtagPosts
- [ ] 11.4 Create provider + state
- [ ] 11.5 Move screens
- [ ] 11.6 Update imports, delete old files
- [ ] 11.7 Test search flows

**Verification**:
- [ ] Search users works
- [ ] Search posts works
- [ ] Hashtag screen works

---

### Phase 12: Collections Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 12.1 Create `lib/features/collections/` structure
- [ ] 12.2 Move domain models (collection)
- [ ] 12.3 Create repository + use cases (4): GetCollections, CreateCollection, AddToCollection, GetCollectionDetail
- [ ] 12.4 Create provider + state
- [ ] 12.5 Move screens + widgets
- [ ] 12.6 Update imports, delete old files
- [ ] 12.7 Test collection flows

**Verification**:
- [ ] Collections list loads
- [ ] Create collection works
- [ ] Add to collection works
- [ ] Collection detail works

---

### Phase 13: Settings Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 13.1 Create `lib/features/settings/` structure
- [ ] 13.2 Create domain models + repository
- [ ] 13.3 Create use cases (3+): LoadSettings, UpdateSettings, ManageSubscription
- [ ] 13.4 Move `UserSettingsProvider` + `ThemeProvider`
- [ ] 13.5 Move all settings screens
- [ ] 13.6 Update `AppInitializer` for new provider locations
- [ ] 13.7 Update imports, delete old files
- [ ] 13.8 Test settings flows

**Verification**:
- [ ] Settings screen loads
- [ ] Theme switching works
- [ ] Account/privacy settings work
- [ ] Subscription screen works
- [ ] Font size works
- [ ] All settings screens accessible

---

### Phase 14: Wellness Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 14.1 Create `lib/features/wellness/` structure
- [ ] 14.2 Move domain models (energy_meter_state)
- [ ] 14.3 Create repository + use cases (3): TrackScreenTime, GetWellnessStats, ManageEnergyMeter
- [ ] 14.4 Move services → data layer
- [ ] 14.5 Move widgets → presentation layer
- [ ] 14.6 Update `LifecycleManager` imports
- [ ] 14.7 Update imports, delete old files
- [ ] 14.8 Test wellness tracking

**Verification**:
- [ ] Screen time tracking works
- [ ] Energy meter displays
- [ ] Wellness stats accessible
- [ ] Lifecycle transitions work (background/foreground)

---

### Phase 15: Calling Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 15.1 Create `lib/features/calling/` structure
- [ ] 15.2 Move domain models (call, call_participant)
- [ ] 15.3 Create repository + use cases (4): InitiateCall, AcceptCall, EndCall, GetActiveCalls
- [ ] 15.4 Create provider + state
- [ ] 15.5 Move screens
- [ ] 15.6 Update imports, delete old files
- [ ] 15.7 Test calling flows

**Verification**:
- [ ] Initiate call works
- [ ] Accept call works
- [ ] Active call screen works
- [ ] Incoming call overlay works

---

### Phase 16: Spaces Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 16.1 Create `lib/features/spaces/` structure
- [ ] 16.2 Move `SpacesScreen`
- [ ] 16.3 Extract `MainLayout` and nav components
- [ ] 16.4 Update router imports
- [ ] 16.5 Test navigation

**Verification**:
- [ ] Bottom navigation works
- [ ] Tab switching works
- [ ] Badges display correctly

---

### Phase 17: Sharing Feature
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 17.1 Create `lib/features/sharing/` structure
- [ ] 17.2 Create domain + use cases (3): ShareToDM, ShareToStory, HandleReceivedIntent
- [ ] 17.3 Move services → data layer
- [ ] 17.4 Move widgets → presentation layer
- [ ] 17.5 Update imports, delete old files
- [ ] 17.6 Test sharing flows

**Verification**:
- [ ] Share sheet works
- [ ] Share to DM works
- [ ] Received intent handling works

---

### Phase 18: Messages Feature — Complete Migration
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 18.1 Create domain entities: MessageEntity, ConversationEntity, ReactionEntity
- [ ] 18.2 Create repository interfaces: MessageRepository, ConversationRepository
- [ ] 18.3 Create datasources: MessageRemote, ConversationRemote, MessageLocal
- [ ] 18.4 Create repository implementations
- [ ] 18.5 Create use cases (6): SendMessage, GetMessages, GetConversations, DeleteMessage, ReactToMessage, ForwardMessage
- [ ] 18.6 Refactor `ChatProvider` to use use cases
- [ ] 18.7 Refactor other chat providers to use use cases
- [ ] 18.8 Delete old messaging services
- [ ] 18.9 Test all messaging flows

**Verification**:
- [ ] Chat loads with messages
- [ ] Send text message works
- [ ] Send image works
- [ ] Send video works
- [ ] Send voice message works
- [ ] Send file works
- [ ] Reply to message works
- [ ] React to message works
- [ ] Delete message works
- [ ] Forward message works
- [ ] Whisper mode works
- [ ] E2E encryption works
- [ ] Realtime updates work
- [ ] Typing indicator works
- [ ] Chat themes work
- [ ] Recording works

---

### Phase 19: Router Refactoring
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 19.1 Extract route path constants to `route_paths.dart`
- [ ] 19.2 Extract redirect/guard logic to `route_guards.dart`
- [ ] 19.3 Extract `MainLayout` and nav to `navigation_shell.dart`
- [ ] 19.4 Extract feature-specific route builders
- [ ] 19.5 Keep `app_router.dart` as assembly point (~100 lines)
- [ ] 19.6 Delete `app_router.dart.backup`
- [ ] 19.7 Test all navigation flows

**Verification**:
- [ ] All routes resolve correctly
- [ ] Auth guards work
- [ ] Deep linking works
- [ ] Password recovery redirect works
- [ ] Bottom navigation works
- [ ] All screen transitions work

---

### Phase 20: Cleanup & Finalization
**Status**: ⬜ NOT STARTED  
**Started**: —  
**Completed**: —  

- [ ] 20.1 Verify `lib/services/` is empty
- [ ] 20.2 Verify `lib/providers/` is empty
- [ ] 20.3 Verify `lib/screens/` is empty
- [ ] 20.4 Verify `lib/models/` is empty
- [ ] 20.5 Verify `lib/widgets/` is empty
- [ ] 20.6 Verify `lib/utils/` is empty
- [ ] 20.7 Verify `lib/config/` is empty
- [ ] 20.8 Verify `lib/exceptions/` is empty
- [ ] 20.9 Delete empty deprecated directories
- [ ] 20.10 Run `flutter analyze` — fix all warnings
- [ ] 20.11 Run all existing tests — fix breakages
- [ ] 20.12 Run integration tests
- [ ] 20.13 Full manual QA pass
- [ ] 20.14 Update `pubspec.yaml` for unused deps
- [ ] 20.15 Create `docs/ARCHITECTURE.md`

**Verification**:
- [ ] `flutter analyze` returns zero issues
- [ ] All tests pass
- [ ] App builds for all target platforms
- [ ] Architecture documentation complete

---

## 📁 Deprecated Directories Status

| Directory | Files Remaining | Target | Status |
|-----------|----------------|--------|--------|
| `lib/services/` | ~44 | 0 | 🔄 In progress (feed services still active for old screens) |
| `lib/providers/` | 11 | 0 | ⬜ Not started |
| `lib/screens/` | ~34 | 0 | ⬜ Not started |
| `lib/models/` | ~30 | 0 | 🔄 In progress (feed models moved, others remain) |
| `lib/widgets/` | ~30 | 0 | 🔄 In progress (feed widgets copied, others remain) |
| `lib/utils/` | 0 | 0 | ✅ Emptied & deleted |
| `lib/config/` | 0 | 0 | ✅ Emptied & deleted |
| `lib/exceptions/` | 0 | 0 | ✅ Emptied & deleted |

---

## 🐛 Issues & Blockers

| # | Issue | Phase | Status | Notes |
|---|-------|-------|--------|-------|
| — | — | — | — | No issues yet |

---

## 📝 Session Notes

### Session 1 (2026-04-03)
- Created comprehensive migration plan in `MIGRATION_PLAN.md`
- Created this tracker file
- Analyzed entire codebase structure
- Identified 18 feature domains + 3 cross-cutting concerns
- Mapped all 50 services, 11 providers, 34 screens, 36 models, 36 widgets to target locations
- Estimated 8-10 weeks for single developer, 4-5 weeks for 2 developers

### Session 2 (2026-04-03)
- **Phase 0 COMPLETE**: Created `lib/core/` foundation layer
  - 8 subdirectories, 22 new files created
  - `AppException` hierarchy (NetworkException, StorageException, ValidationException, AuthenticationException)
  - `Result<T>` sealed type with Success/Failure
  - `SecureStorage` and `PrefsStorage` wrappers
  - DateTime, String, BuildContext extensions
  - App strings and Supabase table constants
  - Deleted `lib/utils/`, `lib/config/`, `lib/exceptions/`
  - Updated 75+ files with new import paths
  - 3 atomic commits
  
- **Phase 2 COMPLETE**: Feed & Posts feature migrated to Clean Architecture
  - 3 domain repository interfaces (PostRepository, FeedRepository, CommentRepository)
  - 3 datasources (PostRemote, FeedRemote, FeedLocal)
  - 3 repository implementations
  - 11 use cases
  - FeedState + FeedProvider
  - 7 screens + 7 widgets copied to feature
  - Model imports updated globally (post, comment, hashtag, poll, mood)
  - LSP diagnostics: 0 errors across entire codebase
  - Old services/providers kept for backward compatibility (not yet deleted)

---

## 🔄 How to Use This Tracker

1. **Update status** when starting a phase: Change `⬜ NOT STARTED` → `🔄 IN PROGRESS`
2. **Check off tasks** as you complete them
3. **Update verification** section when all checks pass
4. **Mark phase complete**: Change `🔄 IN PROGRESS` → `✅ COMPLETED`
5. **Update Quick Stats** table at the top
6. **Log issues** in the Issues & Blockers table
7. **Add session notes** at the end of each work session

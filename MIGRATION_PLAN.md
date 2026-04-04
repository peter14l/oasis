# 🏗️ Clean Architecture Migration Plan — Oasis v2 (Morrow)

> **Version**: 1.0  
> **Created**: 2026-04-03  
> **Status**: Ready for execution  
> **Scope**: Full migration from flat service/provider/screen architecture to feature-based Clean Architecture

---

## 📋 Executive Summary

**Current State**: Flat architecture with 50 services, 11 providers, 34 screens, 36 models, and 36 widgets all in top-level `lib/` directories. Tight coupling between layers. Single 1,437-line router file.

**Target State**: Feature-based Clean Architecture with `data/` → `domain/` → `presentation/` layers per feature. Shared infrastructure extracted to `lib/core/`. Each feature is independently testable, replaceable, and navigable.

**Reference Pattern**: `lib/features/messages/` (partially migrated — presentation layer extracted, domain/data scaffolding in place).

**Migration Strategy**: Strangler Fig — migrate one feature at a time, keeping the app functional throughout. No big-bang rewrites.

---

## 🎯 Target Architecture

### Directory Structure (Final State)

```
lib/
├── main.dart                          # Thin entry point (unchanged pattern)
├── app_initializer.dart               # Startup orchestration (moved from services/)
│
├── core/                              # SHARED INFRASTRUCTURE (cross-cutting)
│   ├── constants/
│   │   ├── app_strings.dart
│   │   ├── app_dimensions.dart
│   │   └── supabase_tables.dart
│   ├── errors/
│   │   ├── app_exception.dart         # Base exception class
│   │   ├── auth_exception.dart        # ← move from lib/exceptions/
│   │   ├── network_exception.dart
│   │   ├── storage_exception.dart
│   │   └── validation_exception.dart
│   ├── result/
│   │   └── result.dart               # Either<Failure, Success> type
│   ├── network/
│   │   └── supabase_client.dart       # ← extracted from supabase_service.dart
│   ├── storage/
│   │   ├── secure_storage.dart        # ← flutter_secure_storage wrapper
│   │   └── prefs_storage.dart         # ← shared_preferences wrapper
│   ├── utils/
│   │   ├── color_utils.dart           # ← move from lib/utils/
│   │   ├── file_utils.dart            # ← move from lib/utils/
│   │   ├── json_utils.dart            # ← move from lib/utils/
│   │   ├── text_parser.dart           # ← move from lib/utils/
│   │   ├── haptic_utils.dart          # ← move from lib/utils/
│   │   ├── permission_utils.dart      # ← move from lib/utils/
│   │   └── map_positioner.dart        # ← move from lib/utils/
│   ├── config/
│   │   ├── feature_flags.dart         # ← move from lib/config/
│   │   └── supabase_config.dart       # ← move from lib/config/
│   └── extensions/
│       ├── datetime_extensions.dart
│       ├── string_extensions.dart
│       └── context_extensions.dart
│
├── features/
│   ├── auth/                          # FEATURE: Authentication & Onboarding
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── session_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── registered_account.dart
│   │   │   │   └── auth_credentials.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sign_in_with_email.dart
│   │   │       ├── sign_up.dart
│   │   │       ├── sign_in_with_google.dart
│   │   │       ├── sign_in_with_apple.dart
│   │   │       ├── sign_out.dart
│   │   │       ├── restore_session.dart
│   │   │       ├── reset_password.dart
│   │   │       └── manage_accounts.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── auth_provider.dart
│   │       │   └── auth_state.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   ├── register_screen.dart
│   │       │   ├── registration_screen.dart
│   │       │   ├── reset_password_screen.dart
│   │       │   └── onboarding_screen.dart
│   │       └── widgets/
│   │           ├── auth_layout_wrapper.dart
│   │           ├── account_switcher_sheet.dart
│   │           └── onboarding/
│   │
│   ├── feed/                          # FEATURE: Feed & Posts
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── post_remote_datasource.dart
│   │   │   │   ├── feed_remote_datasource.dart
│   │   │   │   └── feed_local_datasource.dart  # cache
│   │   │   └── repositories/
│   │   │       ├── post_repository_impl.dart
│   │   │       └── feed_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── post.dart              # ← move from lib/models/
│   │   │   │   ├── post_mood.dart         # ← move from lib/models/
│   │   │   │   ├── comment.dart           # ← move from lib/models/
│   │   │   │   └── enhanced_poll.dart     # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   ├── post_repository.dart
│   │   │   │   └── feed_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_feed_posts.dart
│   │   │       ├── get_following_posts.dart
│   │   │       ├── create_post.dart
│   │   │       ├── delete_post.dart
│   │   │       ├── like_post.dart
│   │   │       ├── repost.dart
│   │   │       ├── get_post_details.dart
│   │   │       ├── create_comment.dart
│   │   │       ├── get_comments.dart
│   │   │       └── manage_poll.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── feed_provider.dart     # ← move from lib/providers/
│   │       │   └── feed_state.dart
│   │       ├── screens/
│   │       │   ├── feed_screen.dart       # ← move from lib/screens/
│   │       │   ├── feed_list.dart         # ← move from lib/screens/
│   │       │   ├── pulse_feed_screen.dart # ← move from lib/screens/
│   │       │   ├── zen_feed_screen.dart   # ← move from lib/screens/
│   │       │   ├── create_post_screen.dart
│   │       │   ├── post_details_screen.dart
│   │       │   └── comments_screen.dart
│   │       └── widgets/
│   │           ├── post_card.dart         # ← move from lib/widgets/
│   │           ├── stories_bar.dart       # ← move from lib/widgets/
│   │           ├── feed_layout_switcher.dart
│   │           ├── mood_selector.dart
│   │           ├── trending_hashtags.dart
│   │           ├── polls/
│   │           └── animations/
│   │
│   ├── profile/                       # FEATURE: User Profiles
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── profile_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── profile_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── user_profile.dart    # ← move from lib/models/
│   │   │   │   └── user_model.dart      # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── profile_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_profile.dart
│   │   │       ├── update_profile.dart
│   │   │       ├── follow_user.dart
│   │   │       ├── unfollow_user.dart
│   │   │       ├── get_followers.dart
│   │   │       ├── get_following.dart
│   │   │       └── get_user_posts.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── profile_provider.dart  # ← move from lib/providers/
│   │       │   └── profile_state.dart
│   │       ├── screens/
│   │       │   ├── profile_screen.dart
│   │       │   ├── edit_profile_screen.dart
│   │       │   └── followers_screen.dart
│   │       └── widgets/
│   │           ├── profile/
│   │           │   ├── activity_graph.dart
│   │           │   └── profile_customization.dart
│   │           └── story_circle.dart
│   │
│   ├── circles/                       # FEATURE: Circles & Commitments
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── circle_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── circle_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── circle.dart          # ← move from lib/models/
│   │   │   │   └── commitment.dart      # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── circle_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_circles.dart
│   │   │       ├── create_circle.dart
│   │   │       ├── join_circle.dart
│   │   │       ├── leave_circle.dart
│   │   │       ├── create_commitment.dart
│   │   │       ├── complete_commitment.dart
│   │   │       └── get_circle_members.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── circle_provider.dart   # ← move from lib/providers/
│   │       │   └── circle_state.dart
│   │       ├── screens/
│   │       │   ├── circles_list_screen.dart
│   │       │   ├── circle_detail_screen.dart
│   │       │   ├── create_circle_screen.dart
│   │       │   ├── circle_join_screen.dart
│   │       │   └── create_commitment_screen.dart
│   │       └── widgets/
│   │           ├── circles/
│   │           │   ├── circle_list_card.dart
│   │           │   ├── commitment_card.dart
│   │           │   ├── streak_banner.dart
│   │           │   └── shattering_glass_animation.dart
│   │
│   ├── canvas/                        # FEATURE: Canvases (Collaborative Spaces)
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── canvas_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── canvas_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── oasis_canvas.dart    # ← move from lib/models/
│   │   │   │   └── canvas_item.dart     # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── canvas_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_canvases.dart
│   │   │       ├── create_canvas.dart
│   │   │       ├── update_canvas.dart
│   │   │       ├── delete_canvas.dart
│   │   │       ├── add_canvas_item.dart
│   │   │       └── get_canvas_timeline.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── canvas_provider.dart   # ← move from lib/providers/
│   │       │   └── canvas_state.dart
│   │       ├── screens/
│   │       │   ├── canvas_list_screen.dart
│   │       │   ├── canvas_detail_screen.dart
│   │       │   ├── create_canvas_screen.dart
│   │       │   └── timeline_canvas_screen.dart
│   │       └── widgets/
│   │           ├── canvas/
│   │           │   ├── canvas_item_widget.dart
│   │           │   ├── canvas_list_tile.dart
│   │           │   ├── glowing_note.dart
│   │           │   ├── journal_entry_widget.dart
│   │           │   ├── scrapbook_motif_wrapper.dart
│   │           │   ├── scattered_polaroid_spread.dart
│   │           │   ├── voice_memo.dart
│   │           │   ├── timeline_scrubber.dart
│   │           │   ├── starry_night_background.dart
│   │           │   ├── pulse_ripple.dart
│   │           │   └── infinite_card_stack.dart
│   │
│   ├── communities/                   # FEATURE: Communities
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── community_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── community_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── community.dart       # ← move from lib/models/
│   │   │   │   └── community_model.dart # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── community_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_communities.dart
│   │   │       ├── get_community_detail.dart
│   │   │       ├── create_community.dart
│   │   │       ├── join_community.dart
│   │   │       └── update_community.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── community_provider.dart  # ← move from lib/providers/
│   │       │   └── community_state.dart
│   │       ├── screens/
│   │       │   ├── communities_screen.dart
│   │       │   ├── community_detail_screen.dart
│   │       │   ├── community_name_theme_screen.dart
│   │       │   ├── community_description_rules_screen.dart
│   │       │   ├── community_privacy_moderation_screen.dart
│   │       │   ├── community_guidelines_screen.dart
│   │       │   └── community_setup_confirmation_screen.dart
│   │
│   ├── capsules/                      # FEATURE: Time Capsules
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── capsule_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── capsule_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── time_capsule.dart    # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── capsule_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_capsules.dart
│   │   │       ├── create_capsule.dart
│   │   │       ├── open_capsule.dart
│   │   │       └── contribute_to_capsule.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── capsule_provider.dart  # ← move from lib/providers/
│   │       │   └── capsule_state.dart
│   │       ├── screens/
│   │       │   ├── create_capsule_screen.dart
│   │       │   └── capsule_view_screen.dart
│   │       └── widgets/
│   │           ├── capsules/
│   │           │   ├── capsule_feed_item.dart
│   │           │   └── capsule_carousel.dart
│   │
│   ├── ripples/                       # FEATURE: Ripples (Public Posts)
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── ripple_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── ripple_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── ripple.dart          # (new model or reuse Post)
│   │   │   ├── repositories/
│   │   │   │   └── ripple_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_ripples.dart
│   │   │       ├── create_ripple.dart
│   │   │       └── react_to_ripple.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── ripples_provider.dart
│   │       │   └── ripples_state.dart
│   │       ├── screens/
│   │       │   ├── ripples_screen.dart
│   │       │   └── create_ripple_screen.dart
│   │       └── widgets/
│   │           └── wellness_badge.dart
│   │
│   ├── stories/                       # FEATURE: Stories
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── story_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── story_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── story.dart           # ← move from lib/models/
│   │   │   │   └── story_model.dart     # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── story_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_stories.dart
│   │   │       ├── create_story.dart
│   │   │       ├── view_story.dart
│   │   │       └── get_story_viewers.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── stories_provider.dart
│   │       ├── screens/
│   │       │   ├── story_view_screen.dart
│   │       │   └── create_story_screen.dart
│   │       └── widgets/
│   │           ├── stories/
│   │           │   └── story_viewers_sheet.dart
│   │           └── story_ring.dart
│   │
│   ├── notifications/                 # FEATURE: Notifications
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── notification_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── notification_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── notification.dart    # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── notification_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_notifications.dart
│   │   │       ├── mark_notification_read.dart
│   │   │       └── mark_all_read.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── notification_provider.dart  # ← move from lib/providers/
│   │       │   └── notification_state.dart
│   │       ├── screens/
│   │       │   └── notifications_screen.dart
│   │
│   ├── search/                        # FEATURE: Search & Discovery
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── search_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── search_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── hashtag.dart         # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── search_repository.dart
│   │   │   └── usecases/
│   │   │       ├── search_users.dart
│   │   │       ├── search_posts.dart
│   │   │       ├── search_communities.dart
│   │   │       └── get_hashtag_posts.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── search_provider.dart
│   │       ├── screens/
│   │       │   └── search_screen.dart
│   │       │   └── hashtag_screen.dart
│   │
│   ├── collections/                   # FEATURE: Collections
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── collection_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── collection_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── collection.dart      # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── collection_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_collections.dart
│   │   │       ├── create_collection.dart
│   │   │       ├── add_to_collection.dart
│   │   │       └── get_collection_detail.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── collections_provider.dart
│   │       ├── screens/
│   │       │   ├── collections_screen.dart
│   │       │   └── collection_detail_screen.dart
│   │       └── widgets/
│   │           └── add_to_collection_sheet.dart
│   │
│   ├── moderation/                    # FEATURE: Moderation
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── moderation_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── moderation_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── moderation.dart      # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── moderation_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_reported_content.dart
│   │   │       ├── take_moderation_action.dart
│   │   │       └── get_moderation_stats.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── moderation_provider.dart
│   │       ├── screens/
│   │       │   └── moderation_screens.dart
│   │       └── widgets/
│   │           └── moderation_dialogs.dart
│   │
│   ├── settings/                      # FEATURE: Settings & Preferences
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── settings_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── settings_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── user_settings.dart
│   │   │   ├── repositories/
│   │   │   │   └── settings_repository.dart
│   │   │   └── usecases/
│   │   │       ├── load_settings.dart
│   │   │       ├── update_settings.dart
│   │   │       └── manage_subscription.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── user_settings_provider.dart  # ← move from lib/providers/
│   │       │   └── theme_provider.dart          # ← move from app_initializer.dart
│   │       ├── screens/
│   │       │   ├── settings_screen.dart
│   │       │   ├── account_privacy_screen.dart
│   │       │   ├── two_factor_auth_screen.dart
│   │       │   ├── download_data_screen.dart
│   │       │   ├── storage_usage_screen.dart
│   │       │   ├── font_size_screen.dart
│   │       │   ├── help_support_screen.dart
│   │       │   ├── subscription_screen.dart
│   │       │   ├── digital_wellbeing_screen.dart
│   │       │   ├── screen_time_screen.dart
│   │       │   ├── wellness_stats_screen.dart
│   │       │   └── vault_settings_screen.dart
│   │       └── widgets/
│   │
│   ├── wellness/                      # FEATURE: Wellness & Digital Wellbeing
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── wellness_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── energy_meter_state.dart  # ← move from lib/models/
│   │   │   │   └── wellness_stats.dart
│   │   │   ├── repositories/
│   │   │   │   └── wellness_repository.dart
│   │   │   └── usecases/
│   │   │       ├── track_screen_time.dart
│   │   │       ├── get_wellness_stats.dart
│   │   │       └── manage_energy_meter.dart
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── energy_meter_widget.dart
│   │           ├── wellness_badge.dart
│   │           └── zen_breath_widget.dart
│   │
│   ├── calling/                       # FEATURE: Voice/Video Calling
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── call_signaling_datasource.dart
│   │   │   └── repositories/
│   │   │       └── call_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── call.dart            # ← move from lib/models/
│   │   │   │   └── call_participant.dart # ← move from lib/models/
│   │   │   ├── repositories/
│   │   │   │   └── call_repository.dart
│   │   │   └── usecases/
│   │   │       ├── initiate_call.dart
│   │   │       ├── accept_call.dart
│   │   │       ├── end_call.dart
│   │   │       └── get_active_calls.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── call_provider.dart
│   │       ├── screens/
│   │       │   ├── active_call_screen.dart
│   │       │   └── incoming_call_overlay.dart
│   │
│   ├── spaces/                        # FEATURE: Spaces (Navigation Shell)
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── spaces_screen.dart   # Main tab navigation
│   │       └── widgets/
│   │           └── spaces_shell.dart
│   │
│   ├── sharing/                       # FEATURE: Sharing & Intents
│   │   ├── data/
│   │   │   └── datasources/
│   │   │       └── sharing_datasource.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       ├── share_to_dm.dart
│   │   │       ├── share_to_story.dart
│   │   │       └── handle_received_intent.dart
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── share_sheet.dart
│   │           └── messages/share_to_dm_modal.dart
│   │
│   └── messages/                      # FEATURE: Messaging (EXISTING — complete migration)
│       ├── data/                      # (currently: datasources/chat_media_picker.dart)
│       │   ├── datasources/
│       │   │   ├── chat_media_picker.dart
│       │   │   ├── message_remote_datasource.dart    # NEW
│       │   │   ├── conversation_remote_datasource.dart  # NEW
│       │   │   └── message_local_datasource.dart     # NEW (cache)
│       │   └── repositories/                          # NEW
│       │       ├── message_repository_impl.dart
│       │       └── conversation_repository_impl.dart
│       ├── domain/                    # (currently: empty)
│       │   ├── models/                                # NEW
│       │   │   ├── message_entity.dart
│       │   │   ├── conversation_entity.dart
│       │   │   └── reaction_entity.dart
│       │   ├── repositories/                          # NEW
│       │   │   ├── message_repository.dart
│       │   │   └── conversation_repository.dart
│       │   └── usecases/                              # NEW
│       │       ├── send_message.dart
│       │       ├── get_messages.dart
│       │       ├── get_conversations.dart
│       │       ├── delete_message.dart
│       │       ├── react_to_message.dart
│       │       └── forward_message.dart
│       └── presentation/              # (currently: fully populated)
│           ├── providers/             # (5 providers — keep, refactor to use usecases)
│           ├── screens/               # (chat_screen.dart — keep)
│           └── widgets/               # (many — keep)
│
├── routes/
│   └── app_router.dart               # SPLIT into:
│       ├── app_router.dart           # Route definitions only (~200 lines)
│       ├── route_guards.dart         # Auth guards, redirect logic
│       └── navigation_shell.dart     # MainLayout, bottom nav, badges
│
├── services/                          # DEPRECATED — will be emptied during migration
│   └── (files gradually move to feature data/ layers)
│
├── providers/                         # DEPRECATED — will be emptied during migration
│   └── (files gradually move to feature presentation/ layers)
│
├── screens/                           # DEPRECATED — will be emptied during migration
│   └── (files gradually move to feature presentation/ layers)
│
├── models/                            # DEPRECATED — will be emptied during migration
│   └── (files gradually move to feature domain/ layers)
│
├── widgets/                           # DEPRECATED — will be emptied during migration
│   └── (files gradually move to feature presentation/ or core/)
│
├── utils/                             # DEPRECATED — will be emptied during migration
│   └── (files move to core/utils/)
│
├── config/                            # DEPRECATED — will be emptied during migration
│   └── (files move to core/config/)
│
└── exceptions/                        # DEPRECATED — will be emptied during migration
    └── (files move to core/errors/)
```

---

## 📐 Layer Responsibilities

### `domain/` Layer (Pure Dart — NO Flutter, NO Supabase, NO external deps)
- **Entities/Models**: Pure data classes with `fromJson`/`toJson`
- **Repository Interfaces**: Abstract contracts defining what data operations are available
- **Use Cases**: Single-responsibility classes that orchestrate repository calls
- **Rules**: Cannot import from `data/` or `presentation/`. Only imports: `dart:*`, other domain files, `core/` types.

### `data/` Layer (Infrastructure — Supabase, storage, network)
- **Data Sources**: Remote (Supabase API calls) and Local (cache, SharedPreferences, secure storage)
- **DTOs**: Data Transfer Objects that map between raw JSON and domain entities
- **Repository Implementations**: Concrete implementations of domain repository interfaces
- **Rules**: Can import from `domain/` and `core/`. Cannot import from `presentation/`.

### `presentation/` Layer (Flutter UI)
- **Providers**: ChangeNotifier classes managing UI state, calling use cases or services
- **Screens**: Full-screen widgets with route-level concerns
- **Widgets**: Reusable UI components within the feature
- **State Classes**: Immutable UI state with `copyWith` pattern (like `ChatState`)
- **Rules**: Can import from `domain/`, `data/`, `core/`, and other presentation files.

---

## 🗺️ Migration Phases

### Phase 0: Foundation Setup (Week 1)
**Goal**: Create the scaffolding that all features will depend on. Zero breaking changes.

| # | Task | Files | Est. Effort |
|---|------|-------|-------------|
| 0.1 | Create `lib/core/` directory structure | New dirs | 30min |
| 0.2 | Move `lib/exceptions/auth_exception.dart` → `lib/core/errors/` + create base `AppException` | Move + new | 30min |
| 0.3 | Create `Result<E>` type (Either pattern) for error handling | New file | 1hr |
| 0.4 | Move `lib/utils/*` → `lib/core/utils/` | Move + update imports | 1hr |
| 0.5 | Move `lib/config/*` → `lib/core/config/` | Move + update imports | 30min |
| 0.6 | Extract `SupabaseService` → `lib/core/network/supabase_client.dart` | Extract + refactor | 2hr |
| 0.7 | Create storage wrappers (`SecureStorage`, `PrefsStorage`) in `lib/core/storage/` | New files | 1hr |
| 0.8 | Create `lib/core/extensions/` with common extensions | New files | 1hr |
| 0.9 | Create `lib/core/constants/` for app-wide constants | New files | 30min |
| 0.10 | Update all existing imports to point to new `core/` locations | Global search/replace | 2hr |

**Verification**: `flutter analyze` clean, app runs identically to before.

---

### Phase 1: Auth Feature (Week 1-2)
**Goal**: Migrate authentication to Clean Architecture. Auth is the most isolated feature — ideal first migration.

**Source files**:
- Services: `auth_service.dart`, `session_registry_service.dart`
- Screens: `login_screen.dart`, `register_screen.dart`, `registration_screen.dart`, `reset_password_screen.dart`
- Screens: `onboarding/onboarding_screen.dart`
- Widgets: `auth_layout_wrapper.dart`, `account_switcher_sheet.dart`, `onboarding/*`
- Models: `user_model.dart` (auth-related fields)

**Target structure**: `lib/features/auth/` with full data/domain/presentation layers.

| # | Task | Est. Effort |
|---|------|-------------|
| 1.1 | Create `lib/features/auth/` directory structure | 15min |
| 1.2 | Extract domain models: `RegisteredAccount`, `AuthCredentials` | 1hr |
| 1.3 | Create `AuthRepository` interface (domain) | 30min |
| 1.4 | Create `AuthRepositoryImpl` (data) wrapping existing `AuthService` logic | 2hr |
| 1.5 | Create datasources: `AuthRemoteDatasource`, `SessionLocalDatasource` | 2hr |
| 1.6 | Create use cases: `SignInWithEmail`, `SignUp`, `SignInWithGoogle`, `SignInWithApple`, `SignOut`, `RestoreSession`, `ResetPassword` | 3hr |
| 1.7 | Create `AuthState` immutable state class | 1hr |
| 1.8 | Create `AuthProvider` (presentation) using use cases | 2hr |
| 1.9 | Move screens to `features/auth/presentation/screens/` | 1hr |
| 1.10 | Move widgets to `features/auth/presentation/widgets/` | 1hr |
| 1.11 | Update `AppInitializer` to use new auth structure | 1hr |
| 1.12 | Update `app_router.dart` imports | 30min |
| 1.13 | Delete old `auth_service.dart` from `lib/services/` | 15min |
| 1.14 | Run tests, verify auth flow end-to-end | 2hr |

**Verification**: Full auth flow works (login, signup, Google/Apple sign-in, password reset, session restore, account switching).

---

### Phase 2: Feed & Posts Feature (Week 2-3)
**Goal**: Migrate the feed system — the most complex read-heavy feature.

**Source files**:
- Services: `feed_service.dart`, `post_service.dart`, `comment_service.dart`, `cross_posting_service.dart`, `hashtag_service.dart`, `cache_service.dart`
- Providers: `feed_provider.dart`
- Screens: `feed_screen.dart`, `feed_list.dart`, `pulse_feed_screen.dart`, `zen_feed_screen.dart`, `create_post_screen.dart`, `post_details_screen.dart`, `comments_screen.dart`
- Widgets: `post_card.dart`, `stories_bar.dart`, `feed_layout_switcher.dart`, `mood_selector.dart`, `trending_hashtags.dart`, `polls/*`, `animations/*`
- Models: `post.dart`, `post_mood.dart`, `comment.dart`, `enhanced_poll.dart`, `hashtag.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 2.1 | Create `lib/features/feed/` directory structure | 15min |
| 2.2 | Move domain models to `features/feed/domain/models/` | 1hr |
| 2.3 | Create `PostRepository` and `FeedRepository` interfaces | 1hr |
| 2.4 | Create datasources: `PostRemoteDatasource`, `FeedRemoteDatasource`, `FeedLocalDatasource` (cache) | 3hr |
| 2.5 | Create repository implementations | 2hr |
| 2.6 | Create use cases (10+ use cases for feed, posts, comments, polls) | 4hr |
| 2.7 | Create `FeedState` immutable state class | 1hr |
| 2.8 | Create `FeedProvider` using use cases | 2hr |
| 2.9 | Move all feed screens to `features/feed/presentation/screens/` | 2hr |
| 2.10 | Move all feed widgets to `features/feed/presentation/widgets/` | 2hr |
| 2.11 | Update imports across the app | 1hr |
| 2.12 | Delete old services from `lib/services/` | 30min |
| 2.13 | Test feed flows (For You, Following, create post, comment, like, repost) | 2hr |

---

### Phase 3: Profile Feature (Week 3)
**Goal**: Migrate user profiles — medium complexity, depends on feed for user posts.

**Source files**:
- Services: `profile_service.dart`
- Providers: `profile_provider.dart`
- Screens: `profile_screen.dart`, `edit_profile_screen.dart`, `followers_screen.dart`
- Widgets: `profile/*`, `story_circle.dart`, `story_ring.dart`
- Models: `user_profile.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 3.1 | Create `lib/features/profile/` structure | 15min |
| 3.2 | Move domain models | 30min |
| 3.3 | Create repository interface + implementation | 1.5hr |
| 3.4 | Create use cases (7 use cases) | 2hr |
| 3.5 | Create `ProfileState` + `ProfileProvider` | 1.5hr |
| 3.6 | Move screens + widgets | 1hr |
| 3.7 | Update imports, delete old files | 30min |
| 3.8 | Test profile flows | 1hr |

---

### Phase 4: Circles Feature (Week 3-4)
**Goal**: Migrate circles and commitments — well-isolated feature.

**Source files**:
- Services: `circle_service.dart`
- Providers: `circle_provider.dart`
- Screens: `circles/circles_list_screen.dart`, `circles/circle_detail_screen.dart`, `circles/create_circle_screen.dart`, `circles/circle_join_screen.dart`, `circles/create_commitment_screen.dart`
- Widgets: `circles/*`
- Models: `circle.dart`, `commitment.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 4.1 | Create `lib/features/circles/` structure | 15min |
| 4.2 | Move domain models | 30min |
| 4.3 | Create repository interface + implementation | 1.5hr |
| 4.4 | Create use cases (7 use cases) | 2hr |
| 4.5 | Create `CircleState` + `CircleProvider` | 1hr |
| 4.6 | Move screens + widgets | 1hr |
| 4.7 | Update imports, delete old files | 30min |
| 4.8 | Test circles flows | 1hr |

---

### Phase 5: Canvas Feature (Week 4)
**Goal**: Migrate canvases — creative/collaborative feature.

**Source files**:
- Services: `canvas_service.dart`, `canvas_audio_service.dart`
- Providers: `canvas_provider.dart`
- Screens: `canvas/canvas_list_screen.dart`, `canvas/canvas_detail_screen.dart`, `canvas/create_canvas_screen.dart`, `canvas/timeline_canvas_screen.dart`
- Widgets: `canvas/*`
- Models: `oasis_canvas.dart`, `canvas_item.dart`, `pulse_node_position.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 5.1 | Create `lib/features/canvas/` structure | 15min |
| 5.2 | Move domain models | 30min |
| 5.3 | Create repository interface + implementation | 2hr |
| 5.4 | Create use cases (6 use cases) | 2hr |
| 5.5 | Create `CanvasState` + `CanvasProvider` | 1.5hr |
| 5.6 | Move screens + widgets (many canvas widgets) | 2hr |
| 5.7 | Update imports, delete old files | 30min |
| 5.8 | Test canvas flows | 1hr |

---

### Phase 6: Communities Feature (Week 4-5)
**Goal**: Migrate communities — includes moderation-adjacent functionality.

**Source files**:
- Services: `community_service.dart`, `moderation_service.dart`
- Providers: `community_provider.dart`
- Screens: `community/*` (6 screens), `moderation/moderation_screens.dart`
- Widgets: `moderation_dialogs.dart`
- Models: `community.dart`, `community_model.dart`, `moderation.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 6.1 | Create `lib/features/communities/` structure | 15min |
| 6.2 | Move domain models | 30min |
| 6.3 | Create repository interface + implementation | 2hr |
| 6.4 | Create use cases (5+ use cases) | 2hr |
| 6.5 | Create `CommunityState` + `CommunityProvider` | 1.5hr |
| 6.6 | Move screens + widgets | 1.5hr |
| 6.7 | Update imports, delete old files | 30min |
| 6.8 | Test community flows | 1hr |

---

### Phase 7: Capsules Feature (Week 5)
**Goal**: Migrate time capsules — self-contained feature.

**Source files**:
- Services: `time_capsule_service.dart`
- Providers: `capsule_provider.dart`
- Screens: `capsules/create_capsule_screen.dart`, `capsules/capsule_view_screen.dart`
- Widgets: `capsules/*`
- Models: `time_capsule.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 7.1 | Create `lib/features/capsules/` structure | 15min |
| 7.2 | Move domain models | 30min |
| 7.3 | Create repository + use cases (4 use cases) | 2hr |
| 7.4 | Create `CapsuleState` + `CapsuleProvider` | 1hr |
| 7.5 | Move screens + widgets | 1hr |
| 7.6 | Update imports, delete old files | 30min |
| 7.7 | Test capsule flows | 1hr |

---

### Phase 8: Ripples Feature (Week 5)
**Goal**: Migrate ripples — public posting feature.

**Source files**:
- Services: `ripples_service.dart`
- Screens: `ripples_screen.dart`, `create_ripple_screen.dart`
- Models: (may reuse `Post` or create `Ripple` entity)

| # | Task | Est. Effort |
|---|------|-------------|
| 8.1 | Create `lib/features/ripples/` structure | 15min |
| 8.2 | Create domain models | 30min |
| 8.3 | Create repository + use cases (3 use cases) | 1.5hr |
| 8.4 | Create provider + state | 1hr |
| 8.5 | Move screens | 30min |
| 8.6 | Update imports, delete old files | 30min |
| 8.7 | Test ripple flows | 1hr |

---

### Phase 9: Stories Feature (Week 5-6)
**Goal**: Migrate stories — ephemeral content feature.

**Source files**:
- Services: `stories_service.dart`
- Screens: `story_view_screen.dart`, `stories/create_story_screen.dart`
- Widgets: `stories/*`, `story_ring.dart`
- Models: `story.dart`, `story_model.dart`, `reaction_story.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 9.1 | Create `lib/features/stories/` structure | 15min |
| 9.2 | Move domain models | 30min |
| 9.3 | Create repository + use cases (4 use cases) | 2hr |
| 9.4 | Create provider + state | 1hr |
| 9.5 | Move screens + widgets | 1hr |
| 9.6 | Update imports, delete old files | 30min |
| 9.7 | Test story flows | 1hr |

---

### Phase 10: Notifications Feature (Week 6)
**Goal**: Migrate notifications — read-heavy, realtime feature.

**Source files**:
- Services: `notification_service.dart`, `notification_manager.dart`
- Providers: `notification_provider.dart`
- Screens: `notifications/notifications_screen.dart`
- Models: `notification.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 10.1 | Create `lib/features/notifications/` structure | 15min |
| 10.2 | Move domain models | 30min |
| 10.3 | Create repository + use cases (3 use cases) | 1.5hr |
| 10.4 | Create provider + state | 1hr |
| 10.5 | Move screens | 30min |
| 10.6 | Update imports, delete old files | 30min |
| 10.7 | Test notification flows | 1hr |

---

### Phase 11: Search Feature (Week 6)
**Goal**: Migrate search — query-based feature.

**Source files**:
- Services: `search_service.dart`
- Screens: `search_screen.dart`, `hashtag_screen.dart`
- Models: `hashtag.dart` (if not moved to feed)

| # | Task | Est. Effort |
|---|------|-------------|
| 11.1 | Create `lib/features/search/` structure | 15min |
| 11.2 | Create domain models + repository | 1hr |
| 11.3 | Create use cases (4 use cases) | 1.5hr |
| 11.4 | Create provider + state | 1hr |
| 11.5 | Move screens | 30min |
| 11.6 | Update imports, delete old files | 30min |
| 11.7 | Test search flows | 1hr |

---

### Phase 12: Collections Feature (Week 6-7)
**Goal**: Migrate collections — bookmarking feature.

**Source files**:
- Services: `collections_service.dart`
- Screens: `collections/collections_screen.dart`, `collections/collection_detail_screen.dart`
- Widgets: `add_to_collection_sheet.dart`
- Models: `collection.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 12.1 | Create `lib/features/collections/` structure | 15min |
| 12.2 | Move domain models | 30min |
| 12.3 | Create repository + use cases (4 use cases) | 1.5hr |
| 12.4 | Create provider + state | 1hr |
| 12.5 | Move screens + widgets | 30min |
| 12.6 | Update imports, delete old files | 30min |
| 12.7 | Test collection flows | 1hr |

---

### Phase 13: Settings Feature (Week 7)
**Goal**: Migrate settings — many screens, mostly local state.

**Source files**:
- Services: `subscription_service.dart`, `pricing_service.dart`, `desktop_window_service.dart`
- Providers: `user_settings_provider.dart`, `ThemeProvider` (from `app_initializer.dart`)
- Screens: All `settings/*` screens + `settings_screen.dart`, `oasis_pro_screen.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 13.1 | Create `lib/features/settings/` structure | 15min |
| 13.2 | Create domain models + repository | 1hr |
| 13.3 | Create use cases (3+ use cases) | 1.5hr |
| 13.4 | Move `UserSettingsProvider` + `ThemeProvider` | 1hr |
| 13.5 | Move all settings screens | 1.5hr |
| 13.6 | Update `AppInitializer` for new provider locations | 1hr |
| 13.7 | Update imports, delete old files | 30min |
| 13.8 | Test settings flows | 1hr |

---

### Phase 14: Wellness Feature (Week 7)
**Goal**: Migrate wellness tracking — service-heavy, UI-light.

**Source files**:
- Services: `screen_time_service.dart`, `wellness_service.dart`, `energy_meter_service.dart`
- Widgets: `energy_meter_widget.dart`, `wellness_badge.dart`, `zen_breath_widget.dart`
- Models: `energy_meter_state.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 14.1 | Create `lib/features/wellness/` structure | 15min |
| 14.2 | Move domain models | 30min |
| 14.3 | Create repository + use cases (3 use cases) | 1.5hr |
| 14.4 | Move services → data layer | 1hr |
| 14.5 | Move widgets → presentation layer | 30min |
| 14.6 | Update `LifecycleManager` imports | 30min |
| 14.7 | Update imports, delete old files | 30min |
| 14.8 | Test wellness tracking | 1hr |

---

### Phase 15: Calling Feature (Week 7-8)
**Goal**: Migrate WebRTC calling — complex realtime feature.

**Source files**:
- Services: `call_service.dart`, `audio_room_service.dart`
- Screens: `messages/active_call_screen.dart`, `messages/incoming_call_overlay.dart`
- Models: `call.dart`, `call_participant.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 15.1 | Create `lib/features/calling/` structure | 15min |
| 15.2 | Move domain models | 30min |
| 15.3 | Create repository + use cases (4 use cases) | 2hr |
| 15.4 | Create provider + state | 1.5hr |
| 15.5 | Move screens | 1hr |
| 15.6 | Update imports, delete old files | 30min |
| 15.7 | Test calling flows | 2hr |

---

### Phase 16: Spaces Feature (Week 8)
**Goal**: Migrate the navigation shell — the main app layout.

**Source files**:
- Screens: `spaces/spaces_screen.dart`
- From `app_router.dart`: `MainLayout`, bottom navigation, badge components

| # | Task | Est. Effort |
|---|------|-------------|
| 16.1 | Create `lib/features/spaces/` structure | 15min |
| 16.2 | Move `SpacesScreen` to `features/spaces/presentation/screens/` | 30min |
| 16.3 | Extract `MainLayout` and nav components to `features/spaces/presentation/widgets/` | 1hr |
| 16.4 | Update router to import from new location | 30min |
| 16.5 | Test navigation | 1hr |

---

### Phase 17: Sharing Feature (Week 8)
**Goal**: Migrate sharing/intent handling — cross-cutting concern.

**Source files**:
- Services: `sharing_service.dart`, `media_download_service.dart`
- Widgets: `share_sheet.dart`, `messages/share_to_dm_modal.dart`

| # | Task | Est. Effort |
|---|------|-------------|
| 17.1 | Create `lib/features/sharing/` structure | 15min |
| 17.2 | Create domain + use cases (3 use cases) | 1hr |
| 17.3 | Move services → data layer | 1hr |
| 17.4 | Move widgets → presentation layer | 30min |
| 17.5 | Update imports, delete old files | 30min |
| 17.6 | Test sharing flows | 1hr |

---

### Phase 18: Messages Feature — Complete Migration (Week 8-9)
**Goal**: Complete the partially-migrated messages feature — fill in the empty domain/data layers.

**Current state**: Presentation layer fully extracted, but `domain/` and `data/repositories/` are empty. `ChatProvider` directly calls `MessagingService`, `EncryptionService`, etc.

| # | Task | Est. Effort |
|---|------|-------------|
| 18.1 | Create domain entities: `MessageEntity`, `ConversationEntity`, `ReactionEntity` | 2hr |
| 18.2 | Create repository interfaces: `MessageRepository`, `ConversationRepository` | 1hr |
| 18.3 | Create datasources: `MessageRemoteDatasource`, `ConversationRemoteDatasource`, `MessageLocalDatasource` | 3hr |
| 18.4 | Create repository implementations | 2hr |
| 18.5 | Create use cases: `SendMessage`, `GetMessages`, `GetConversations`, `DeleteMessage`, `ReactToMessage`, `ForwardMessage` | 3hr |
| 18.6 | Refactor `ChatProvider` to use use cases instead of direct service calls | 3hr |
| 18.7 | Refactor other chat providers to use use cases | 2hr |
| 18.8 | Delete old `messaging_service.dart`, `chat_messaging_service.dart`, etc. from `lib/services/` | 30min |
| 18.9 | Test all messaging flows | 3hr |

---

### Phase 19: Router Refactoring (Week 9)
**Goal**: Split the 1,437-line `app_router.dart` into manageable pieces.

| # | Task | Est. Effort |
|---|------|-------------|
| 19.1 | Extract route path constants to `lib/routes/route_paths.dart` | 30min |
| 19.2 | Extract redirect/guard logic to `lib/routes/route_guards.dart` | 1hr |
| 19.3 | Extract `MainLayout`, bottom nav, badge widgets to `lib/routes/navigation_shell.dart` | 1.5hr |
| 19.4 | Extract feature-specific route builders to separate files: `auth_routes.dart`, `feed_routes.dart`, etc. | 2hr |
| 19.5 | Keep `app_router.dart` as the router assembly point (~100 lines) | 1hr |
| 19.6 | Delete `app_router.dart.backup` | 5min |
| 19.7 | Test all navigation flows | 2hr |

---

### Phase 20: Cleanup & Finalization (Week 9-10)
**Goal**: Remove all deprecated directories, ensure everything compiles, run full test suite.

| # | Task | Est. Effort |
|---|------|-------------|
| 20.1 | Verify `lib/services/` is empty (or contains only truly shared services) | 30min |
| 20.2 | Verify `lib/providers/` is empty | 15min |
| 20.3 | Verify `lib/screens/` is empty | 15min |
| 20.4 | Verify `lib/models/` is empty | 15min |
| 20.5 | Verify `lib/widgets/` is empty | 15min |
| 20.6 | Verify `lib/utils/` is empty | 15min |
| 20.7 | Verify `lib/config/` is empty | 15min |
| 20.8 | Verify `lib/exceptions/` is empty | 15min |
| 20.9 | Delete empty deprecated directories | 15min |
| 20.10 | Run `flutter analyze` — fix all warnings | 2hr |
| 20.11 | Run all existing tests — fix any breakages | 2hr |
| 20.12 | Run `flutter test` integration tests | 1hr |
| 20.13 | Full manual QA pass on critical flows | 4hr |
| 20.14 | Update `pubspec.yaml` if any dependencies are now unused | 30min |
| 20.15 | Create architecture documentation in `docs/ARCHITECTURE.md` | 2hr |

---

## 📊 Feature-to-Service Mapping

| Feature | Services to Migrate | Providers to Migrate | Screens to Migrate | Models to Migrate |
|---------|-------------------|---------------------|-------------------|-------------------|
| **auth** | `auth_service`, `session_registry_service` | `AuthService` (from initializer) | 5 screens | `user_model` (partial) |
| **feed** | `feed_service`, `post_service`, `comment_service`, `cross_posting_service`, `hashtag_service`, `cache_service` | `FeedProvider` | 7 screens | `post`, `post_mood`, `comment`, `enhanced_poll` |
| **profile** | `profile_service` | `ProfileProvider` | 3 screens | `user_profile` |
| **circles** | `circle_service` | `CircleProvider` | 5 screens | `circle`, `commitment` |
| **canvas** | `canvas_service`, `canvas_audio_service` | `CanvasProvider` | 4 screens | `oasis_canvas`, `canvas_item`, `pulse_node_position` |
| **communities** | `community_service`, `moderation_service` | `CommunityProvider` | 6 screens | `community`, `community_model`, `moderation` |
| **capsules** | `time_capsule_service` | `CapsuleProvider` | 2 screens | `time_capsule` |
| **ripples** | `ripples_service` | (new) | 2 screens | (new or reuse Post) |
| **stories** | `stories_service` | (new) | 2 screens | `story`, `story_model`, `reaction_story` |
| **notifications** | `notification_service`, `notification_manager` | `NotificationProvider` | 1 screen | `notification` |
| **search** | `search_service` | (new) | 2 screens | `hashtag` |
| **collections** | `collections_service` | (new) | 2 screens | `collection` |
| **settings** | `subscription_service`, `pricing_service`, `desktop_window_service` | `UserSettingsProvider`, `ThemeProvider` | 12 screens | (new: `user_settings`) |
| **wellness** | `screen_time_service`, `wellness_service`, `energy_meter_service` | (services become data layer) | 0 screens | `energy_meter_state` |
| **calling** | `call_service`, `audio_room_service` | `CallService` (from initializer) | 2 screens | `call`, `call_participant` |
| **spaces** | (none) | (none) | 1 screen | (none) |
| **sharing** | `sharing_service`, `media_download_service` | (none) | 0 screens | (none) |
| **messages** | `messaging_service`, `chat_messaging_service`, `chat_media_service`, `chat_decryption_service`, `message_operations_service`, `conversation_service`, `smart_reply_service`, `voice_transcript_service` | `ChatProvider`, `ChatEncryptionProvider`, `ChatRecordingProvider`, `ChatReactionsProvider`, `ChatSettingsProvider`, `ConversationProvider`, `TypingIndicatorProvider` | 5 screens | `message`, `message_reaction`, `conversation`, `chat_background`, `chat_theme` |

---

## 🔄 Shared Services (stay in `core/` or become cross-feature)

| Service | Destination | Reason |
|---------|------------|--------|
| `supabase_service` | `core/network/supabase_client.dart` | Used by every feature |
| `encryption_service` | `core/security/encryption.dart` | Used by messages, vault, settings |
| `key_management_service` | `core/security/key_management.dart` | Signal protocol support |
| `signal/signal_service` | `core/signal/signal_service.dart` | E2E encryption infrastructure |
| `signal/signal_store` | `core/signal/signal_store.dart` | E2E encryption infrastructure |
| `presence_service` | `core/realtime/presence.dart` | Used across features |
| `ai_content_service` | `core/ai/ai_content.dart` | Smart replies, content generation |
| `study_session_service` | `features/study/` or `core/` | Depends on scope |
| `nearby_discovery_service` | `core/discovery/nearby.dart` | Location-based, cross-feature |
| `creator_analytics_service` | `core/analytics/creator.dart` | Analytics across features |
| `vault_service` | `features/vault/` or `core/security/` | Secure content storage |
| `wellness_service` | `features/wellness/data/` | Wellness feature |
| `screen_time_service` | `features/wellness/data/` | Wellness feature |
| `energy_meter_service` | `features/wellness/data/` | Wellness feature |
| `desktop_window_service` | `core/platform/desktop_window.dart` | Platform-specific utility |

---

## ⚠️ Migration Rules

### DO:
1. **One feature at a time** — complete a phase before starting the next
2. **Keep the app running** after every phase — no broken builds
3. **Run `flutter analyze`** after every file move
4. **Update imports immediately** when moving files
5. **Create barrel files** (`export` files) for each feature layer to simplify imports
6. **Write tests** for each new use case created
7. **Commit after each phase** with descriptive messages

### DON'T:
1. **Don't refactor logic** while migrating — move code as-is first, refactor in a separate pass
2. **Don't delete old files** until the new feature is fully verified
3. **Don't change business logic** during migration — only move and restructure
4. **Don't skip the domain layer** — even if it feels like overkill for simple features
5. **Don't create circular dependencies** — domain → core only, data → domain + core, presentation → everything

---

## 📈 Progress Tracking

See `MIGRATION_TRACKER.md` in the project root for the live tracking file.

### Key Metrics to Track:
- [ ] Files migrated: 0 / ~200
- [ ] Features fully migrated: 0 / 18
- [ ] Deprecated directories emptied: 0 / 8
- [ ] Use cases created: 0 / ~80
- [ ] Repository interfaces created: 0 / ~20
- [ ] Tests passing: TBD / TBD

---

## 🚀 Post-Migration Benefits

1. **Testability**: Each use case is independently unit-testable
2. **Replaceability**: Swap Supabase for another backend by replacing data layer only
3. **Navigability**: New developers can find everything about a feature in one directory
4. **Parallel Development**: Multiple devs can work on different features without conflicts
5. **Feature Flags**: Easy to enable/disable entire features
6. **Code Reuse**: Clear distinction between shared (`core/`) and feature-local code
7. **Scalability**: Adding a new feature means adding a new `features/x/` directory — no more adding to giant service files

---

## 📝 Notes

- The `features/messages/` pattern currently has **empty domain/data layers**. Phase 18 fills these in and refactors the existing presentation providers to use the new use case layer.
- The `LifecycleManager` in `main.dart` will need import updates when wellness services move.
- The `AppInitializer` will need to be updated after each phase as provider locations change.
- The router refactoring (Phase 19) should happen AFTER all features are migrated, so route imports are stable.
- Total estimated effort: **8-10 weeks** for a single developer, or **4-5 weeks** with 2 developers working on independent features in parallel.

---

## ❌ Removed Features (Not Used in App)

The following features were planned but are **NOT actively used** in the application and have been removed from the migration scope:

### Audio Rooms
- **Status**: Completely unimplemented
- **Files**: `lib/services/audio_room_service.dart`, `lib/models/audio_room.dart`
- **Reason**: Both files are entirely commented out (`/* ... */`). The service throws `UnimplementedError` for room creation. No audio room UI screens exist.

### Communities  
- **Status**: Screens exist but not accessible
- **Files**: 7 screens in `lib/screens/community/`, service `community_service.dart`, provider `community_provider.dart`, models `community.dart`, `community_model.dart`
- **Reason**: 
  - No routes in `app_router.dart` point to any community screens
  - No navigation in `spaces_screen.dart` references communities
  - Provider exists but is not used anywhere in the app
  - Feature appears to be a planned but incomplete feature

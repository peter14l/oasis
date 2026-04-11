# Phase 07: Account Management & Moderation Enhancements - Implementation Plan

## Overview
This phase enhances user privacy through a permanent account deletion flow, centralizes all support and reporting to `oasis.officialsupport@outlook.com`, and improves moderation with an expanded reporting system for posts and messages.

---

## 1. Account Deletion & Support Email Migration
### 1.1 Support Email Migration
- **Task:** Update all occurrences of support/contact emails to `oasis.officialsupport@outlook.com`.
- **Files to update:**
  - `lib/screens/settings_screen.dart`
  - `lib/features/settings/presentation/screens/help_support_screen.dart`
  - `lib/features/settings/presentation/screens/about_app_screen.dart`
  - `website/privacy.html`
  - Any other files found via grep.

### 1.2 Account Deletion UI & Logic
- **Task:** Implement the "Delete Account" flow in the Settings screen.
- **Implementation:**
  - Add a "Delete Account" button in `lib/screens/settings_screen.dart`.
  - Create a high-friction confirmation dialog (requires typing "DELETE").
  - Use `AuthService.deleteAccount()` to trigger the `delete_user_account` Supabase RPC.
  - Ensure the user is signed out and redirected to the login screen upon success.

### 1.3 Settings Screen Mini-Note
- **Task:** Add a dismissible notification in the Settings screen about the official support email.
- **Implementation:**
  - Create a `SupportEmailBanner` widget.
  - Use `SharedPreferences` to persist the dismissal state (`support_email_note_dismissed`).
  - Display the banner only if not dismissed.

---

## 2. Enhanced Reporting Flow
### 2.1 Expanded Reporting Categories
- **Task:** Update the reporting model and categories.
- **Implementation:**
  - Update `lib/models/moderation.dart` (or equivalent) with a comprehensive list of `ReportCategory` options (e.g., Harassment, Spam, Hate Speech, Inappropriate Content, etc.).
  - Add a "Details" field to the reporting flow.

### 2.2 Reporting UI for Posts & Messages
- **Task:** Implement the enhanced reporting dialog and integrate it into feed and chat.
- **Implementation:**
  - Update `ModerationDialogs` to include the new categories and details input.
  - Add a "Report Message" option to the message context menu in `lib/features/chat/presentation/widgets/message_options_sheet.dart` (or equivalent).
  - Update `PostCard` to use the new reporting dialog.
  - Display a note to users that report details will be shared with support via email.

### 2.3 Reporting Backend & Email Notification
- **Task:** Ensure reports are correctly sent and notify support.
- **Implementation:**
  - Update `ModerationService.submitReport` to include the new categories and details.
  - Implement a mechanism (e.g., Edge Function or direct email intent) to notify `oasis.officialsupport@outlook.com` of new reports.

---

## 3. Testing & Validation
### 3.1 Unit & Widget Tests
- **Task:** Create tests for new logic and UI components.
- **Tests:**
  - `test/services/auth_service_test.dart`: Verify account deletion logic.
  - `test/widgets/settings_screen_test.dart`: Verify the support email banner dismissal.
  - `test/widgets/moderation_dialogs_test.dart`: Verify the expanded reporting flow and validation.

### 3.2 Integration Tests
- **Task:** Verify end-to-end flows.
- **Tests:**
  - `test/integration/account_deletion_flow_test.dart`: Full account deletion journey.
  - `test/integration/reporting_flow_test.dart`: Reporting a post and a message.

---

## Success Criteria
- [ ] Users can permanently delete their accounts with a confirmation step.
- [ ] All support contacts globally updated to `oasis.officialsupport@outlook.com`.
- [ ] Reporting flow is available for both posts and messages with detailed categories.
- [ ] Settings screen banner is dismissible and persists across app restarts.
- [ ] All tests pass.

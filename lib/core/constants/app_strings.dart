/// App-wide string constants.
///
/// Centralize all user-facing strings here for easier
/// localization and consistency in the future.
class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'Morrow';
  static const String appTagline = 'Share moments, connect with communities.';

  // Auth
  static const String welcomeBack = 'Welcome back';
  static const String createAccount = 'Create Account';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String signInWithGoogle = 'Continue with Google';
  static const String signInWithApple = 'Continue with Apple';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError =
      'No internet connection. Please check your network.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String sessionExpired =
      'Your session has expired. Please sign in again.';
  static const String serverError = 'Server error. Please try again later.';

  // Placeholders
  static const String writeSomething = 'What\'s on your mind?';
  static const String searchPlaceholder =
      'Search people, posts, communities...';
  static const String noResults = 'No results found';
  static const String noContent = 'Nothing here yet';
  static const String loading = 'Loading...';

  // Navigation
  static const String feed = 'Feed';
  static const String search = 'Search';
  static const String spaces = 'Spaces';
  static const String messages = 'Messages';
  static const String profile = 'Profile';
  static const String notifications = 'Notifications';
  static const String settings = 'Settings';

  // Actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String share = 'Share';
  static const String send = 'Send';
  static const String reply = 'Reply';
  static const String like = 'Like';
  static const String comment = 'Comment';
  static const String follow = 'Follow';
  static const String unfollow = 'Unfollow';
  static const String create = 'Create';
  static const String join = 'Join';
  static const String leave = 'Leave';

  // Confirmations
  static const String confirmDelete = 'Are you sure you want to delete this?';
  static const String confirmLeave = 'Are you sure you want to leave?';
  static const String discardChanges = 'Discard changes?';

  // Time
  static const String justNow = 'Just now';
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
}

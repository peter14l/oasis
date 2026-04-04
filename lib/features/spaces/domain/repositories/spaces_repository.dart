import '../models/navigation_entity.dart';

/// Abstract repository interface for navigation/shell operations
abstract class SpacesRepository {
  /// Get app shell configuration
  AppShellEntity getAppShell();

  /// Update badge count for a tab
  Future<void> updateBadgeCount(String tabId, int count);

  /// Navigate to a tab
  Future<void> navigateToTab(String tabId);

  /// Get current tab
  NavigationTabEntity? getCurrentTab();

  /// Stream of tab changes
  Stream<NavigationTabEntity> watchCurrentTab();

  /// Update online status
  Future<void> updateOnlineStatus(bool isOnline);
}

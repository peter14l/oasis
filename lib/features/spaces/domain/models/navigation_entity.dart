/// Domain entity representing a navigation tab in the app
class NavigationTabEntity {
  final String id;
  final String name;
  final String icon;
  final String route;
  final int? badgeCount;
  final bool isSelected;

  const NavigationTabEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.route,
    this.badgeCount,
    this.isSelected = false,
  });

  NavigationTabEntity copyWith({
    String? id,
    String? name,
    String? icon,
    String? route,
    int? badgeCount,
    bool? isSelected,
  }) {
    return NavigationTabEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      badgeCount: badgeCount ?? this.badgeCount,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  bool get hasBadge => badgeCount != null && badgeCount! > 0;
}

/// App shell configuration
class AppShellEntity {
  final List<NavigationTabEntity> tabs;
  final String currentRoute;
  final bool isOnline;
  final DateTime lastActive;

  const AppShellEntity({
    required this.tabs,
    required this.currentRoute,
    this.isOnline = true,
    required this.lastActive,
  });

  factory AppShellEntity.initial() {
    return AppShellEntity(
      tabs: const [
        NavigationTabEntity(
          id: 'feed',
          name: 'Feed',
          icon: 'home',
          route: '/feed',
        ),
        NavigationTabEntity(
          id: 'circles',
          name: 'Circles',
          icon: 'circle',
          route: '/circles',
        ),
        NavigationTabEntity(
          id: 'canvas',
          name: 'Canvas',
          icon: 'palette',
          route: '/canvas',
        ),
        NavigationTabEntity(
          id: 'messages',
          name: 'Messages',
          icon: 'chat',
          route: '/messages',
        ),
        NavigationTabEntity(
          id: 'profile',
          name: 'Profile',
          icon: 'person',
          route: '/profile',
        ),
      ],
      currentRoute: '/feed',
      lastActive: DateTime.now(),
    );
  }

  AppShellEntity copyWith({
    List<NavigationTabEntity>? tabs,
    String? currentRoute,
    bool? isOnline,
    DateTime? lastActive,
  }) {
    return AppShellEntity(
      tabs: tabs ?? this.tabs,
      currentRoute: currentRoute ?? this.currentRoute,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  NavigationTabEntity? get currentTab {
    try {
      return tabs.firstWhere((tab) => tab.route == currentRoute);
    } catch (_) {
      return null;
    }
  }
}

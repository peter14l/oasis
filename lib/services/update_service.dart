import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oasis/core/config/app_config.dart';
import 'package:oasis/services/notification_manager.dart';

/// Model holding update information from remote server
class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isRequired;
  final DateTime? releaseDate;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isRequired,
    this.releaseDate,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion:
          json['latestVersion'] as String? ?? json['version'] as String? ?? '',
      downloadUrl:
          json['downloadUrl'] as String? ?? json['url'] as String? ?? '',
      releaseNotes:
          json['releaseNotes'] as String? ?? json['notes'] as String? ?? '',
      isRequired:
          json['isRequired'] as bool? ?? json['required'] as bool? ?? false,
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'] as String)
          : null,
    );
  }

  /// Check if current version is older than latest version
  bool get isUpdateAvailable {
    final currentVersion = _parseVersion(AppConfig.appVersion);
    final latest = _parseVersion(latestVersion);

    // Compare version parts: major, minor, patch
    if (latest[0] > currentVersion[0]) return true;
    if (latest[0] < currentVersion[0]) return false;
    if (latest[1] > currentVersion[1]) return true;
    if (latest[1] < currentVersion[1]) return false;
    return latest[2] > currentVersion[2];
  }

  List<int> _parseVersion(String version) {
    // Extract version numbers from string like "4.1.0+3" or "4.2.0"
    final cleanVersion = version.split('+').first.split('-').first;
    final parts = cleanVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }
}

/// Service to check for app updates from remote server
class UpdateService {
  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService._();
  UpdateService._();

  bool _hasChecked = false;
  UpdateInfo? _cachedUpdateInfo;

  /// Get update check URL from environment variable
  static String get _updateCheckUrl {
    const fromEnv = String.fromEnvironment('UPDATE_CHECK_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    // Default fallback for development
    return 'https://oasis-web-red.vercel.app/api/check-update';
  }

  /// Check if update checking is enabled
  static bool get isEnabled {
    const fromEnv = String.fromEnvironment('UPDATE_CHECK_ENABLED');
    if (fromEnv.isNotEmpty) return fromEnv.toLowerCase() == 'true';
    return !kDebugMode; // Only check in release mode by default
  }

  /// Check for updates - returns null if no update or check failed
  Future<UpdateInfo?> checkForUpdates() async {
    // Prevent multiple checks in same session
    if (_hasChecked && _cachedUpdateInfo != null) {
      return _cachedUpdateInfo;
    }

    if (!isEnabled) {
      debugPrint('UpdateService: Update checking is disabled');
      _hasChecked = true;
      return null;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      debugPrint(
        'UpdateService: Checking for updates. Current version: $currentVersion',
      );
      debugPrint('UpdateService: Update URL: $_updateCheckUrl');
      final fullUrl = '$_updateUrl?version=$currentVersion';
      debugPrint('UpdateService: Fetching full URL: $fullUrl');

      final response = await http
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 10));

      debugPrint('UpdateService: Status code: ${response.statusCode}');
      if (kDebugMode) {
        debugPrint('UpdateService: Response body length: ${response.body.length}');
        if (response.body.length < 500) {
          debugPrint('UpdateService: Response body: ${response.body}');
        }
      }

      if (response.statusCode == 200) {
        final json = _parseJsonResponse(response.body);
        if (json != null) {
          final updateInfo = UpdateInfo.fromJson(json);
          _cachedUpdateInfo = updateInfo;
          _hasChecked = true;

          if (updateInfo.isUpdateAvailable) {
            debugPrint(
              'UpdateService: Update available: ${updateInfo.latestVersion}',
            );
          } else {
            debugPrint('UpdateService: App is up to date');
          }
          return updateInfo;
        }
      } else {
        debugPrint(
          'UpdateService: Update check failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('UpdateService: Update check failed: $e');
    }

    _hasChecked = true;
    return null;
  }

  /// Get the URL with current version appended
  String get _updateUrl {
    // If URL already has query params, append with &
    if (_updateCheckUrl.contains('?')) {
      return '$_updateCheckUrl&version=${AppConfig.appVersion}';
    }
    return '$_updateUrl?version=${AppConfig.appVersion}';
  }

  /// Parse JSON response safely
  Map<String, dynamic>? _parseJsonResponse(String body) {
    try {
      // Handle potential JSONP wrapper or plain JSON
      final cleanBody = body
          .replaceFirst(RegExp(r'^\s*update\s*\(\s*', multiLine: false), '')
          .replaceFirst(RegExp(r'\s*\)\s*$', multiLine: false), '');
      return jsonDecode(cleanBody) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('UpdateService: Failed to parse response: $e');
      return null;
    }
  }

  /// Show update available dialog
  Future<void> showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: !updateInfo.isRequired,
      builder: (context) => UpdateDialog(updateInfo: updateInfo),
    );
  }

  /// Show native notification for update
  Future<void> showUpdateNotification(UpdateInfo updateInfo) async {
    try {
      await NotificationManager.instance.showNotification(
        title: 'App Update Available',
        body:
            'Version ${updateInfo.latestVersion} is available. Tap to download.',
        payload: 'update:${updateInfo.latestVersion}',
      );
    } catch (e) {
      debugPrint('UpdateService: Failed to show notification: $e');
    }
  }

  /// Launch the download URL
  Future<bool> launchDownloadUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('UpdateService: Failed to launch URL: $e');
    }
    return false;
  }

  /// Reset cached state (useful for testing)
  void reset() {
    _hasChecked = false;
    _cachedUpdateInfo = null;
  }
}

/// Dialog widget shown when update is available
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final isRequired = updateInfo.isRequired;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(isRequired ? 'Update Required' : 'Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A new version (${updateInfo.latestVersion}) is available.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (updateInfo.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Release Notes:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  updateInfo.releaseNotes,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
          if (isRequired) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This update is required to continue using the app.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!isRequired)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await UpdateService.instance.launchDownloadUrl(
              updateInfo.downloadUrl,
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Download'),
        ),
      ],
      actionsAlignment: isRequired
          ? MainAxisAlignment.end
          : MainAxisAlignment.spaceBetween,
    );
  }
}

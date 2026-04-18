import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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
    if (version.isEmpty) return [0, 0, 0];
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

enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  installing,
  completed,
  failed,
  upToDate
}

class UpdateProgress {
  final UpdateStatus status;
  final double progress;
  final List<String> logs;
  final String? error;

  UpdateProgress({
    required this.status,
    this.progress = 0.0,
    this.logs = const [],
    this.error,
  });

  UpdateProgress copyWith({
    UpdateStatus? status,
    double? progress,
    List<String>? logs,
    String? error,
  }) {
    return UpdateProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      logs: logs ?? this.logs,
      error: error ?? this.error,
    );
  }
}

/// Service to check for app updates from remote server
class UpdateService extends ChangeNotifier {
  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService._();
  UpdateService._();

  bool _hasChecked = false;
  UpdateInfo? _cachedUpdateInfo;
  UpdateInfo? get cachedUpdateInfo => _cachedUpdateInfo;

  UpdateProgress _currentProgress = UpdateProgress(status: UpdateStatus.idle);
  UpdateProgress get currentProgress => _currentProgress;

  final Dio _dio = Dio();

  /// Get update check URL from environment variable
  static String get _updateCheckUrl {
    const fromEnv = String.fromEnvironment('UPDATE_CHECK_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    // Default fallback for development
    return 'https://oasisweb-omega.vercel.app/api/check-update';
  }

  /// Check if update checking is enabled
  static bool get isEnabled {
    const fromEnv = String.fromEnvironment('UPDATE_CHECK_ENABLED');
    if (fromEnv.isNotEmpty) return fromEnv.toLowerCase() == 'true';
    return true; // Enable by default as requested
  }

  void _updateState(UpdateProgress progress) {
    _currentProgress = progress;
    notifyListeners();
  }

  void _addLog(String log) {
    final newLogs = List<String>.from(_currentProgress.logs)..add(log);
    _updateState(_currentProgress.copyWith(logs: newLogs));
    debugPrint('UpdateService: $log');
  }

  /// Check for updates - returns null if no update or check failed
  Future<UpdateInfo?> checkForUpdates({bool manual = false}) async {
    // Prevent multiple checks in same session unless manual
    if (!manual && _hasChecked && _cachedUpdateInfo != null) {
      return _cachedUpdateInfo;
    }

    if (!isEnabled && !manual) {
      debugPrint('UpdateService: Update checking is disabled');
      _hasChecked = true;
      return null;
    }

    _updateState(_currentProgress.copyWith(status: UpdateStatus.checking));
    _addLog('Checking for updates...');

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      _addLog('Current version: $currentVersion');
      
      final fullUrl = _getUpdateUrlWithVersion(currentVersion);
      
      final response = await http
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = _parseJsonResponse(response.body);
        if (json != null) {
          final updateInfo = UpdateInfo.fromJson(json);
          _cachedUpdateInfo = updateInfo;
          _hasChecked = true;

          if (updateInfo.isUpdateAvailable) {
            _addLog('Update available: ${updateInfo.latestVersion}');
            _updateState(_currentProgress.copyWith(status: UpdateStatus.available));
          } else {
            _addLog('App is up to date');
            _updateState(_currentProgress.copyWith(status: UpdateStatus.upToDate));
          }
          return updateInfo;
        }
      } else {
        _addLog('Update check failed with status: ${response.statusCode}');
        _updateState(_currentProgress.copyWith(status: UpdateStatus.failed, error: 'Server returned ${response.statusCode}'));
      }
    } catch (e) {
      _addLog('Update check failed: $e');
      _updateState(_currentProgress.copyWith(status: UpdateStatus.failed, error: e.toString()));
    }

    _hasChecked = true;
    return null;
  }

  String _getUpdateUrlWithVersion(String version) {
    final baseUrl = _updateCheckUrl;
    if (baseUrl.contains('?')) {
      return '$baseUrl&version=$version';
    }
    return '$baseUrl?version=$version';
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

  /// Download and install update
  Future<void> downloadAndInstallUpdate(UpdateInfo updateInfo) async {
    if (_currentProgress.status == UpdateStatus.downloading || 
        _currentProgress.status == UpdateStatus.installing) {
      return;
    }

    _updateState(UpdateProgress(
      status: UpdateStatus.downloading,
      logs: ['Starting update process...'],
    ));

    try {
      // 1. Prepare download path
      final tempDir = await getTemporaryDirectory();
      final apkPath = '${tempDir.path}/oasis_update.apk';
      
      // Delete old APK if exists
      final oldFile = File(apkPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      _addLog('Fetching update from: ${updateInfo.downloadUrl}');

      // 2. Download
      await _dio.download(
        updateInfo.downloadUrl,
        apkPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateState(_currentProgress.copyWith(progress: progress));
          }
        },
      );

      _addLog('Download completed successfully.');
      _addLog('Preparing for installation...');
      _updateState(_currentProgress.copyWith(status: UpdateStatus.installing, progress: 1.0));

      // 3. Install
      _addLog('Opening APK for installation...');
      final result = await OpenFilex.open(apkPath);
      
      if (result.type == ResultType.done) {
        _addLog('Installation process started.');
        _addLog('App will be restarted for the updates to take effect.');
        _updateState(_currentProgress.copyWith(status: UpdateStatus.completed));
        
        // Give the user time to see the log before quitting
        await Future.delayed(const Duration(seconds: 3));
        _quitApp();
      } else {
        _addLog('Installation failed: ${result.message}');
        _updateState(_currentProgress.copyWith(status: UpdateStatus.failed, error: result.message));
      }

    } catch (e) {
      _addLog('Error during update: $e');
      _updateState(_currentProgress.copyWith(status: UpdateStatus.failed, error: e.toString()));
    }
  }

  void _quitApp() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  /// Show update available dialog (Legacy - replaced by modal sheet in main.dart)
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

  /// Reset cached state
  void reset() {
    _hasChecked = false;
    _cachedUpdateInfo = null;
    _currentProgress = UpdateProgress(status: UpdateStatus.idle);
    notifyListeners();
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
            // In the new flow, we navigate to the update screen
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


import 'package:flutter/foundation.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:uuid/uuid.dart';

class WelcomeTemplate {
  final String? id;
  final String? userId;
  final String templateText;
  final bool isDefault;
  final bool isActive;
  final bool includePrivacyTips;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WelcomeTemplate({
    this.id,
    this.userId,
    required this.templateText,
    this.isDefault = false,
    this.isActive = true,
    this.includePrivacyTips = true,
    this.createdAt,
    this.updatedAt,
  });

  factory WelcomeTemplate.fromJson(Map<String, dynamic> json) {
    return WelcomeTemplate(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      templateText: json['template_text'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      includePrivacyTips: json['include_privacy_tips'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'template_text': templateText,
      'is_default': isDefault,
      'is_active': isActive,
      'include_privacy_tips': includePrivacyTips,
    };
  }

  WelcomeTemplate copyWith({
    String? id,
    String? userId,
    String? templateText,
    bool? isDefault,
    bool? isActive,
    bool? includePrivacyTips,
  }) {
    return WelcomeTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateText: templateText ?? this.templateText,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      includePrivacyTips: includePrivacyTips ?? this.includePrivacyTips,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class WelcomeSettings {
  final String? id;
  final String userId;
  final bool welcomeEnabled;
  final bool sendOnFollow;
  final bool sendOnCircleJoin;
  final bool sendFirstDm;
  final String? lastTemplateId;

  WelcomeSettings({
    this.id,
    required this.userId,
    this.welcomeEnabled = true,
    this.sendOnFollow = true,
    this.sendOnCircleJoin = true,
    this.sendFirstDm = false,
    this.lastTemplateId,
  });

  factory WelcomeSettings.fromJson(Map<String, dynamic> json) {
    return WelcomeSettings(
      id: json['id'] as String?,
      userId: json['user_id'] as String? ?? '',
      welcomeEnabled: json['welcome_enabled'] as bool? ?? true,
      sendOnFollow: json['send_on_follow'] as bool? ?? true,
      sendOnCircleJoin: json['send_on_circle_join'] as bool? ?? true,
      sendFirstDm: json['send_first_dm'] as bool? ?? false,
      lastTemplateId: json['last_template_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'welcome_enabled': welcomeEnabled,
      'send_on_follow': sendOnFollow,
      'send_on_circle_join': sendOnCircleJoin,
      'send_first_dm': sendFirstDm,
      'last_template_id': lastTemplateId,
    };
  }

  WelcomeSettings copyWith({
    String? id,
    String? userId,
    bool? welcomeEnabled,
    bool? sendOnFollow,
    bool? sendOnCircleJoin,
    bool? sendFirstDm,
    String? lastTemplateId,
  }) {
    return WelcomeSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      welcomeEnabled: welcomeEnabled ?? this.welcomeEnabled,
      sendOnFollow: sendOnFollow ?? this.sendOnFollow,
      sendOnCircleJoin: sendOnCircleJoin ?? this.sendOnCircleJoin,
      sendFirstDm: sendFirstDm ?? this.sendFirstDm,
      lastTemplateId: lastTemplateId ?? this.lastTemplateId,
    );
  }
}

class WelcomeWagonService {
  final _supabase = SupabaseService().client;

  /// Get default templates (not user-specific)
  Future<List<WelcomeTemplate>> getDefaultTemplates() async {
    try {
      // Query templates where user_id IS NULL (default templates)
      final response = await _supabase
          .from(SupabaseConfig.welcomeTemplatesTable)
          .select()
          .filter('user_id', 'is', 'null')
          .eq('is_active', true)
          .order('created_at');

      if (response.isEmpty) return [];

      return response.map((json) => WelcomeTemplate.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching default templates: $e');
      return [];
    }
  }

  /// Get user's custom templates
  Future<List<WelcomeTemplate>> getUserTemplates(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.welcomeTemplatesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response.isEmpty) return [];

      return response.map((json) => WelcomeTemplate.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching user templates: $e');
      return [];
    }
  }

  /// Get all templates (defaults + user's custom)
  Future<List<WelcomeTemplate>> getAllTemplates(String userId) async {
    try {
      // Get defaults
      final defaults = await getDefaultTemplates();
      // Get user's custom
      final custom = await getUserTemplates(userId);
      // Combine (custom overrides defaults)
      return [...custom, ...defaults];
    } catch (e) {
      debugPrint('Error fetching all templates: $e');
      return [];
    }
  }

  /// Create a custom template
  Future<WelcomeTemplate?> createTemplate({
    required String userId,
    required String templateText,
    bool includePrivacyTips = true,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.welcomeTemplatesTable)
          .insert({
            'user_id': userId,
            'template_text': templateText,
            'is_default': false,
            'include_privacy_tips': includePrivacyTips,
          })
          .select()
          .single();

      return WelcomeTemplate.fromJson(response);
    } catch (e) {
      debugPrint('Error creating template: $e');
      return null;
    }
  }

  /// Update a template
  Future<bool> updateTemplate({
    required String templateId,
    String? templateText,
    bool? isActive,
    bool? includePrivacyTips,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (templateText != null) updates['template_text'] = templateText;
      if (isActive != null) updates['is_active'] = isActive;
      if (includePrivacyTips != null) {
        updates['include_privacy_tips'] = includePrivacyTips;
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from(SupabaseConfig.welcomeTemplatesTable)
          .update(updates)
          .eq('id', templateId);

      return true;
    } catch (e) {
      debugPrint('Error updating template: $e');
      return false;
    }
  }

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      await _supabase
          .from(SupabaseConfig.welcomeTemplatesTable)
          .delete()
          .eq('id', templateId);

      return true;
    } catch (e) {
      debugPrint('Error deleting template: $e');
      return false;
    }
  }

  /// Get user's welcome settings
  Future<WelcomeSettings?> getSettings(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.welcomeSettingsTable)
          .select()
          .eq('user_id', userId)
          .single();

      return WelcomeSettings.fromJson(response);
    } catch (e) {
      // Settings don't exist yet - create default
      return createSettings(userId);
    }
  }

  /// Create default welcome settings
  Future<WelcomeSettings?> createSettings(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.welcomeSettingsTable)
          .insert({
            'user_id': userId,
            'welcome_enabled': true,
            'send_on_follow': true,
            'send_on_circle_join': true,
            'send_first_dm': false,
          })
          .select()
          .single();

      return WelcomeSettings.fromJson(response);
    } catch (e) {
      debugPrint('Error creating welcome settings: $e');
      return null;
    }
  }

  /// Update welcome settings
  Future<bool> updateSettings({
    required String userId,
    bool? welcomeEnabled,
    bool? sendOnFollow,
    bool? sendOnCircleJoin,
    bool? sendFirstDm,
    String? lastTemplateId,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (welcomeEnabled != null) updates['welcome_enabled'] = welcomeEnabled;
      if (sendOnFollow != null) updates['send_on_follow'] = sendOnFollow;
      if (sendOnCircleJoin != null) {
        updates['send_on_circle_join'] = sendOnCircleJoin;
      }
      if (sendFirstDm != null) updates['send_first_dm'] = sendFirstDm;
      if (lastTemplateId != null) updates['last_template_id'] = lastTemplateId;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from(SupabaseConfig.welcomeSettingsTable)
          .update(updates)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error updating welcome settings: $e');
      return false;
    }
  }

  /// Preview what a message would look like (with privacy tips injected)
  String previewMessage(WelcomeTemplate template) {
    String text = template.templateText;

    if (template.includePrivacyTips &&
        !text.toLowerCase().contains('privacy')) {
      // Add privacy tip if not already present
      text = '$text\n\n💡 Tip: Check Settings → Privacy to control who sees your content.';
    }

    return text;
  }

  /// Manually trigger a welcome message (for testing or first DM)
  Future<String?> sendManualWelcome({
    required String senderId,
    required String recipientId,
    String triggerType = 'dm',
  }) async {
    try {
      final response = await _supabase.rpc('send_welcome_message', params: {
        'p_recipient_id': recipientId,
        'p_sender_id': senderId,
        'p_trigger_type': triggerType,
      });

      return response as String?;
    } catch (e) {
      debugPrint('Error sending welcome message: $e');
      return null;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/welcome_wagon_service.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/widgets/custom_snackbar.dart';
import 'package:oasis/core/utils/responsive_layout.dart';

class WelcomeWagonScreen extends StatefulWidget {
  const WelcomeWagonScreen({super.key});

  @override
  State<WelcomeWagonScreen> createState() => _WelcomeWagonScreenState();
}

class _WelcomeWagonScreenState extends State<WelcomeWagonScreen> {
  final _welcomeWagonService = WelcomeWagonService();
  
  WelcomeSettings? _settings;
  List<WelcomeTemplate> _templates = [];
  bool _isLoading = true;
  String? _selectedTemplateId;
  final _templateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    if (userId == null) return;

    try {
      final settings = await _welcomeWagonService.getSettings(userId);
      final templates = await _welcomeWagonService.getAllTemplates(userId);
      
      if (mounted) {
        setState(() {
          _settings = settings;
          _templates = templates;
          _selectedTemplateId = settings?.lastTemplateId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSettings({
    bool? welcomeEnabled,
    bool? sendOnFollow,
    bool? sendOnCircleJoin,
    bool? sendFirstDm,
    String? lastTemplateId,
  }) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    if (userId == null || _settings == null) return;

    try {
      await _welcomeWagonService.updateSettings(
        userId: userId,
        welcomeEnabled: welcomeEnabled ?? _settings!.welcomeEnabled,
        sendOnFollow: sendOnFollow ?? _settings!.sendOnFollow,
        sendOnCircleJoin: sendOnCircleJoin ?? _settings!.sendOnCircleJoin,
        sendFirstDm: sendFirstDm ?? _settings!.sendFirstDm,
        lastTemplateId: lastTemplateId ?? _settings!.lastTemplateId,
      );
      await _loadData();
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to save settings');
      }
    }
  }

  Future<void> _createTemplate() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    if (userId == null || _templateController.text.trim().isEmpty) return;

    try {
      final template = await _welcomeWagonService.createTemplate(
        userId: userId,
        templateText: _templateController.text.trim(),
      );
      
      if (template != null && mounted) {
        _templateController.clear();
        await _loadData();
        CustomSnackbar.showSuccess(context, 'Template created');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to create template');
      }
    }
  }

  Future<void> _deleteTemplate(String templateId) async {
    try {
      await _welcomeWagonService.deleteTemplate(templateId);
      if (_selectedTemplateId == templateId) {
        _selectedTemplateId = null;
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to delete template');
      }
    }
  }

  String _previewMessage(WelcomeTemplate template) {
    return _welcomeWagonService.previewMessage(template);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_settings == null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text('Failed to load Welcome Wagon settings'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      content = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Enable/Disable Toggle
          SwitchListTile(
            title: const Text('Welcome Wagon'),
            subtitle: const Text(
              'Send friendly welcome messages to new connections',
            ),
            value: _settings!.welcomeEnabled,
            onChanged: (value) => _updateSettings(welcomeEnabled: value),
          ),
          
          if (_settings!.welcomeEnabled) ...[
            const Divider(height: 32),
            
            // Trigger Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'When to send',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('On new follower'),
              subtitle: const Text(
                'Send welcome when someone follows you',
              ),
              value: _settings!.sendOnFollow,
              onChanged: (value) => _updateSettings(sendOnFollow: value),
            ),
            SwitchListTile(
              title: const Text('On Circle join'),
              subtitle: const Text(
                'Send welcome when someone joins your Circle',
              ),
              value: _settings!.sendOnCircleJoin,
              onChanged: (value) => _updateSettings(sendOnCircleJoin: value),
            ),
            SwitchListTile(
              title: const Text('First DM'),
              subtitle: const Text(
                'Include welcome with first direct message',
              ),
              value: _settings!.sendFirstDm,
              onChanged: (value) => _updateSettings(sendFirstDm: value),
            ),
            
            const Divider(height: 32),
            
            // Template Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Welcome Message',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            if (_templates.isNotEmpty) ...[
              // Template dropdown/list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedTemplateId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('Select a welcome message'),
                  items: _templates.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      t.templateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedTemplateId = value);
                    _updateSettings(lastTemplateId: value);
                  },
                ),
              ),
              
              // Preview
              if (_selectedTemplateId != null) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final selected = _templates.firstWhere(
                      (t) => t.id == _selectedTemplateId,
                      orElse: () => _templates.first,
                    );
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.preview,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Preview',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _previewMessage(selected),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              
              const Divider(height: 32),
              
              // Custom Template Creation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Create Custom Message',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _templateController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your custom welcome message...',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createTemplate,
                        icon: const Icon(Icons.add),
                        label: const Text('Create'),
                      ),
                    ),
                  ],
                ),
              ),
              
              // User Templates List
              Builder(
                builder: (context) {
                  final customTemplates = _templates.where((t) => !t.isDefault).toList();
                  if (customTemplates.isEmpty) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Your Custom Messages',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...customTemplates.map((t) => ListTile(
                        title: Text(
                          t.templateText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteTemplate(t.id!),
                        ),
                      )),
                    ],
                  );
                },
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No templates available. Create a custom message above.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ] else ...[
            // Welcome disabled
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.waving_hand,
                    size: 64,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Wagon is disabled',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable it above to start sending personalized welcome messages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    if (isDesktop) {
      return Material(color: Colors.transparent, child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Wagon'),
        centerTitle: true,
      ),
      body: content,
    );
  }
}
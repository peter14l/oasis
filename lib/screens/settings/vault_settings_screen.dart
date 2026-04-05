import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oasis/services/vault_service.dart';
import 'package:provider/provider.dart';

class VaultSettingsScreen extends StatefulWidget {
  const VaultSettingsScreen({super.key});

  @override
  State<VaultSettingsScreen> createState() => _VaultSettingsScreenState();
}

class _VaultSettingsScreenState extends State<VaultSettingsScreen> {
  bool _isLoading = true;
  bool _isEnabled = false;
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkVaultStatus();
  }

  Future<void> _checkVaultStatus() async {
    try {
      final service = Provider.of<VaultService>(context, listen: false);
      final enabled = await service.isVaultEnabled();
      if (mounted) {
        setState(() {
          _isEnabled = enabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking vault status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vault settings: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _enableVault() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<VaultService>(context, listen: false);
      await service.enableVault(pin: _pinController.text);
      await _checkVaultStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault enabled successfully')),
        );
        _pinController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error enabling vault: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disableVault() async {
    // Require PIN to disable
    final confirmed = await _showPinDialog(context);
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<VaultService>(context, listen: false);
      await service.disableVault();
      await _checkVaultStatus();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vault disabled')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error disabling vault: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showPinDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter PIN'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Current PIN',
                counterText: '',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final service = Provider.of<VaultService>(
                    context,
                    listen: false,
                  );
                  final isValid = await service.unlockVaultWithPin(
                    controller.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, isValid);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Future<void> _showChangePinDialog(
    BuildContext context,
    VaultService service,
  ) async {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Change PIN'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: currentPinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Current PIN',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: newPinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'New PIN',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Confirm New PIN',
                          counterText: '',
                        ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (currentPinController.text.length != 4) {
                          setDialogState(
                            () => errorMessage = 'Please enter current PIN',
                          );
                          return;
                        }
                        if (newPinController.text.length != 4) {
                          setDialogState(
                            () => errorMessage = 'New PIN must be 4 digits',
                          );
                          return;
                        }
                        if (newPinController.text !=
                            confirmPinController.text) {
                          setDialogState(
                            () => errorMessage = 'New PINs do not match',
                          );
                          return;
                        }
                        if (currentPinController.text ==
                            newPinController.text) {
                          setDialogState(
                            () => errorMessage = 'New PIN must be different',
                          );
                          return;
                        }

                        final success = await service.changePin(
                          currentPinController.text,
                          newPinController.text,
                        );

                        if (success) {
                          Navigator.pop(dialogContext, true);
                        } else {
                          setDialogState(
                            () => errorMessage = 'Current PIN is incorrect',
                          );
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
          ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final content = ListView(
      padding: EdgeInsets.all(isDesktop ? 40 : 16),
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _isEnabled ? Icons.lock : Icons.lock_open,
                        size: 64,
                        color:
                            _isEnabled
                                ? theme.colorScheme.primary
                                : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isEnabled ? 'Vault is Enabled' : 'Vault is Disabled',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEnabled
                            ? 'Your private content is secured locally'
                            : 'Enable vault to hide sensitive content',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (!_isEnabled) ...[
                  Text('Setup Vault', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Set a 4-digit PIN',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.length != 4) {
                          return 'Please enter a 4-digit PIN';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _enableVault,
                      icon: const Icon(Icons.shield),
                      label: const Text('Enable Vault'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.password),
                          title: const Text('Change PIN'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final service = Provider.of<VaultService>(
                              context,
                              listen: false,
                            );
                            _showChangePinDialog(context, service);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('Disable Vault'),
                          subtitle: const Text(
                            'This will unhide all secluded content',
                          ),
                          textColor: theme.colorScheme.error,
                          iconColor: theme.colorScheme.error,
                          onTap: _disableVault,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Material(color: Colors.transparent, child: content);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vault Settings')),
      body: content,
    );
  }
}

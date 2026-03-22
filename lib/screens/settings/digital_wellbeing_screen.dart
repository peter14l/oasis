import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis_v2/providers/user_settings_provider.dart';

class DigitalWellbeingScreen extends StatefulWidget {
  const DigitalWellbeingScreen({super.key});

  @override
  State<DigitalWellbeingScreen> createState() => _DigitalWellbeingScreenState();
}

class _DigitalWellbeingScreenState extends State<DigitalWellbeingScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userSettings = context.watch<UserSettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Digital Wellbeing'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildUsageCard(theme),
          const SizedBox(height: 32),
          
          Text(
            'Usage Limits',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildWellbeingTile(
            context,
            icon: FluentIcons.timer_24_regular,
            title: 'Daily Limit',
            subtitle: userSettings.dailyLimitMinutes > 0 
                ? '${userSettings.dailyLimitMinutes} minutes' 
                : 'Not set',
            trailing: Switch(
              value: userSettings.dailyLimitMinutes > 0,
              onChanged: (value) => _showLimitPicker(context, userSettings),
            ),
          ),
          
          _buildWellbeingTile(
            context,
            icon: FluentIcons.sleep_24_regular,
            title: 'Wind Down',
            subtitle: 'Remind me to check on my Circles before bed',
            trailing: Switch(
              value: userSettings.windDownEnabled,
              onChanged: (value) => userSettings.setWindDownEnabled(value),
            ),
          ),
          
          const SizedBox(height: 32),
          Text(
            'Positive Habits',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildWellbeingTile(
            context,
            icon: FluentIcons.approvals_app_24_regular,
            title: 'Circle Reminders',
            subtitle: 'Gentle nudges to stay consistent with your friends',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          
          const SizedBox(height: 40),
          _buildQuoteCard(theme),
        ],
      ),
    );
  }

  Widget _buildUsageCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            'TODAY\'S USAGE',
            style: TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text(
            '1h 24m',
            style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.6,
            backgroundColor: Colors.white10,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ve used 60% of your daily goal',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWellbeingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.blueAccent),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: trailing,
    );
  }

  Widget _buildQuoteCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withValues(alpha: 0.2), Colors.transparent],
          begin: Alignment.topLeft,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(FluentIcons.leaf_one_24_regular, color: Colors.greenAccent),
          SizedBox(height: 16),
          Text(
            '"Oasis is designed to connect you, not consume you. Take a break, breathe, and come back when you\'re ready."',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  void _showLimitPicker(BuildContext context, UserSettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F26),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set Daily Limit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('15 Minutes'),
              onTap: () { provider.setDailyLimit(15); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text('30 Minutes'),
              onTap: () { provider.setDailyLimit(30); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text('1 Hour'),
              onTap: () { provider.setDailyLimit(60); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text('No Limit'),
              onTap: () { provider.setDailyLimit(0); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }
}

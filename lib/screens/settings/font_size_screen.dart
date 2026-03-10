import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:morrow_v2/providers/user_settings_provider.dart';

class FontSizeScreen extends StatelessWidget {
  const FontSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<UserSettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Size'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.text_fields, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Preview Text',
                    style: TextStyle(
                      fontSize: 18 * settingsProvider.fontSizeFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is how the text will look across the Morrow app. You can adjust the scale below.',
                    style: TextStyle(
                      fontSize: 14 * settingsProvider.fontSizeFactor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                const Icon(Icons.text_fields, size: 16),
                Expanded(
                  child: Slider(
                    value: settingsProvider.fontSizeFactor,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    onChanged: (value) {
                      settingsProvider.setFontSizeFactor(value);
                    },
                  ),
                ),
                const Icon(Icons.text_fields, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Scale: ${(settingsProvider.fontSizeFactor * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

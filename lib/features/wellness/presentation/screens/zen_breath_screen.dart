import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis/features/wellness/presentation/widgets/zen_breath_widget.dart';

class ZenBreathScreen extends StatelessWidget {
  const ZenBreathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindful Breathing'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: ZenBreathWidget(
        onComplete: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/feed');
          }
        },
      ),
    );
  }
}

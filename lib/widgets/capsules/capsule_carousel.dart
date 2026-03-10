import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:morrow_v2/providers/capsule_provider.dart';
import 'package:morrow_v2/widgets/capsules/capsule_feed_item.dart';

class CapsuleCarousel extends StatefulWidget {
  const CapsuleCarousel({super.key});

  @override
  State<CapsuleCarousel> createState() => _CapsuleCarouselState();
}

class _CapsuleCarouselState extends State<CapsuleCarousel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CapsuleProvider>().loadCapsules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CapsuleProvider>(
      builder: (context, provider, child) {
        if (provider.capsules.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_empty, size: 20, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    'Time Capsules',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 250, // Fixed height for carousel
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: provider.capsules.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 300, // Fixed width for cards
                    child: CapsuleFeedItem(
                      capsule: provider.capsules[index],
                    ),
                  );
                },
              ),
            ),
             const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:oasis_v2/models/hashtag.dart';
import 'package:oasis_v2/services/hashtag_service.dart';
import 'package:go_router/go_router.dart';

class TrendingHashtagsWidget extends StatefulWidget {
  const TrendingHashtagsWidget({super.key});

  @override
  State<TrendingHashtagsWidget> createState() => _TrendingHashtagsWidgetState();
}

class _TrendingHashtagsWidgetState extends State<TrendingHashtagsWidget> {
  final _hashtagService = HashtagService();
  List<Hashtag> _trendingHashtags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendingHashtags();
  }

  Future<void> _loadTrendingHashtags() async {
    try {
      final hashtags = await _hashtagService.getTrendingHashtags(limit: 10);
      if (mounted) {
        setState(() {
          _trendingHashtags = hashtags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trendingHashtags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Trending',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _trendingHashtags.length,
            itemBuilder: (context, index) {
              final hashtag = _trendingHashtags[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  label: Text('#${hashtag.tag}'),
                  onPressed: () {
                    context.push('/hashtag/${hashtag.tag}');
                  },
                  backgroundColor: Theme.of(context).cardColor,
                  elevation: 1,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

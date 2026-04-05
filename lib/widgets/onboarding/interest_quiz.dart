import 'package:flutter/material.dart';
import 'package:oasis/core/utils/haptic_utils.dart';

/// Interest categories for onboarding discovery quiz
class InterestCategory {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final List<String> subcategories;

  const InterestCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.subcategories = const [],
  });
}

/// Predefined interest categories
class InterestCategories {
  static const List<InterestCategory> all = [
    InterestCategory(
      id: 'art',
      name: 'Art & Design',
      emoji: '🎨',
      color: Color(0xFFE91E63),
      subcategories: [
        'Digital Art',
        'Photography',
        'Illustration',
        'UI/UX',
        'Architecture',
      ],
    ),
    InterestCategory(
      id: 'music',
      name: 'Music',
      emoji: '🎵',
      color: Color(0xFF9C27B0),
      subcategories: [
        'Pop',
        'Hip Hop',
        'Rock',
        'Electronic',
        'Jazz',
        'Classical',
      ],
    ),
    InterestCategory(
      id: 'tech',
      name: 'Technology',
      emoji: '💻',
      color: Color(0xFF2196F3),
      subcategories: ['Programming', 'AI/ML', 'Startups', 'Gaming', 'Gadgets'],
    ),
    InterestCategory(
      id: 'fitness',
      name: 'Fitness & Health',
      emoji: '💪',
      color: Color(0xFF4CAF50),
      subcategories: ['Gym', 'Yoga', 'Running', 'Nutrition', 'Mental Health'],
    ),
    InterestCategory(
      id: 'travel',
      name: 'Travel',
      emoji: '✈️',
      color: Color(0xFF00BCD4),
      subcategories: ['Adventure', 'Beach', 'City', 'Nature', 'Culture'],
    ),
    InterestCategory(
      id: 'food',
      name: 'Food & Cooking',
      emoji: '🍕',
      color: Color(0xFFFF9800),
      subcategories: [
        'Recipes',
        'Restaurants',
        'Baking',
        'Healthy Eating',
        'Coffee',
      ],
    ),
    InterestCategory(
      id: 'fashion',
      name: 'Fashion & Style',
      emoji: '👗',
      color: Color(0xFFFF5722),
      subcategories: [
        'Streetwear',
        'Luxury',
        'Vintage',
        'Sustainable',
        'Accessories',
      ],
    ),
    InterestCategory(
      id: 'sports',
      name: 'Sports',
      emoji: '⚽',
      color: Color(0xFF795548),
      subcategories: ['Football', 'Basketball', 'Tennis', 'F1', 'Esports'],
    ),
    InterestCategory(
      id: 'entertainment',
      name: 'Entertainment',
      emoji: '🎬',
      color: Color(0xFF673AB7),
      subcategories: ['Movies', 'TV Shows', 'Anime', 'K-Drama', 'Podcasts'],
    ),
    InterestCategory(
      id: 'lifestyle',
      name: 'Lifestyle',
      emoji: '🌿',
      color: Color(0xFF8BC34A),
      subcategories: [
        'Minimalism',
        'Self-care',
        'Productivity',
        'Home Decor',
        'Pets',
      ],
    ),
    InterestCategory(
      id: 'business',
      name: 'Business',
      emoji: '💼',
      color: Color(0xFF607D8B),
      subcategories: [
        'Entrepreneurship',
        'Marketing',
        'Finance',
        'Career',
        'Investing',
      ],
    ),
    InterestCategory(
      id: 'science',
      name: 'Science',
      emoji: '🔬',
      color: Color(0xFF3F51B5),
      subcategories: [
        'Space',
        'Biology',
        'Psychology',
        'Physics',
        'Environment',
      ],
    ),
  ];
}

/// User's interest profile
class UserInterests {
  final List<String> selectedCategories;
  final Map<String, List<String>> selectedSubcategories;
  final List<String> customInterests;

  UserInterests({
    this.selectedCategories = const [],
    this.selectedSubcategories = const {},
    this.customInterests = const [],
  });

  factory UserInterests.fromJson(Map<String, dynamic> json) {
    return UserInterests(
      selectedCategories: (json['categories'] as List?)?.cast<String>() ?? [],
      selectedSubcategories:
          (json['subcategories'] as Map?)?.map(
            (k, v) => MapEntry(k as String, (v as List).cast<String>()),
          ) ??
          {},
      customInterests: (json['custom'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': selectedCategories,
      'subcategories': selectedSubcategories,
      'custom': customInterests,
    };
  }
}

/// Interest Discovery Quiz Widget
class InterestDiscoveryQuiz extends StatefulWidget {
  final Function(UserInterests) onComplete;
  final UserInterests? existingInterests;

  const InterestDiscoveryQuiz({
    super.key,
    required this.onComplete,
    this.existingInterests,
  });

  @override
  State<InterestDiscoveryQuiz> createState() => _InterestDiscoveryQuizState();
}

class _InterestDiscoveryQuizState extends State<InterestDiscoveryQuiz> {
  final Set<String> _selectedCategories = {};
  final Map<String, Set<String>> _selectedSubcategories = {};
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingInterests != null) {
      _selectedCategories.addAll(widget.existingInterests!.selectedCategories);
      for (final entry
          in widget.existingInterests!.selectedSubcategories.entries) {
        _selectedSubcategories[entry.key] = entry.value.toSet();
      }
    }
  }

  void _toggleCategory(String categoryId) {
    HapticUtils.selectionClick();
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
        _selectedSubcategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  void _toggleSubcategory(String categoryId, String subcategory) {
    HapticUtils.lightImpact();
    setState(() {
      _selectedSubcategories.putIfAbsent(categoryId, () => {});
      if (_selectedSubcategories[categoryId]!.contains(subcategory)) {
        _selectedSubcategories[categoryId]!.remove(subcategory);
      } else {
        _selectedSubcategories[categoryId]!.add(subcategory);
      }
    });
  }

  void _complete() {
    HapticUtils.success();
    widget.onComplete(
      UserInterests(
        selectedCategories: _selectedCategories.toList(),
        selectedSubcategories: _selectedSubcategories.map(
          (k, v) => MapEntry(k, v.toList()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: _currentStep == 0 ? 0.5 : 1.0,
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),

        Expanded(
          child:
              _currentStep == 0
                  ? _buildCategorySelection(theme, colorScheme)
                  : _buildSubcategorySelection(theme, colorScheme),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Back'),
                ),
              const Spacer(),
              FilledButton(
                onPressed:
                    _currentStep == 0 && _selectedCategories.isNotEmpty
                        ? () => setState(() => _currentStep = 1)
                        : _currentStep == 1
                        ? _complete
                        : null,
                child: Text(_currentStep == 0 ? 'Next' : 'Done'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelection(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you interested in?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least 3 topics to personalize your feed',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                InterestCategories.all.map((category) {
                  final isSelected = _selectedCategories.contains(category.id);
                  return GestureDetector(
                    onTap: () => _toggleCategory(category.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? category.color.withValues(alpha: 0.2)
                                : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              isSelected ? category.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategorySelection(ThemeData theme, ColorScheme colorScheme) {
    final selectedCategoryList =
        InterestCategories.all
            .where((c) => _selectedCategories.contains(c.id))
            .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: selectedCategoryList.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fine-tune your interests',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select specific topics you love',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final category = selectedCategoryList[index - 1];
        final selectedSubs = _selectedSubcategories[category.id] ?? {};

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    category.subcategories.map((sub) {
                      final isSelected = selectedSubs.contains(sub);
                      return FilterChip(
                        label: Text(sub),
                        selected: isSelected,
                        selectedColor: category.color.withValues(alpha: 0.3),
                        onSelected: (_) => _toggleSubcategory(category.id, sub),
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Common String extensions for formatting and validation.
extension StringX on String {
  /// Capitalize first letter of the string.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word.
  String get capitalizeWords {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Truncate string to max length, adding ellipsis if needed.
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  /// Check if string is a valid email format.
  bool get isEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  /// Check if string is a valid URL format.
  bool get isUrl {
    return RegExp(
      r'^https?:\/\/[^\s/$.?#].[^\s]*$',
      caseSensitive: false,
    ).hasMatch(this);
  }

  /// Convert string to URL-friendly slug.
  String get toSlug {
    return toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Check if string is empty or whitespace only.
  bool get isBlank => trim().isEmpty;

  /// Check if string contains only digits.
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Check if string contains only letters.
  bool get isAlphabetic => RegExp(r'^[a-zA-Z]+$').hasMatch(this);

  /// Check if string contains only alphanumeric characters.
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  /// Remove all HTML tags from string.
  String get stripHtml => replaceAll(RegExp(r'<[^>]*>'), '');

  /// Reverse the string.
  String get reversed => split('').reversed.join('');

  /// Count occurrences of a substring.
  int countOccurrences(String pattern) {
    if (pattern.isEmpty) return 0;
    return RegExp(RegExp.escape(pattern)).allMatches(this).length;
  }
}

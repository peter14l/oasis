import 'package:flutter/material.dart';
import 'package:oasis/core/utils/text_parser.dart';
import 'package:go_router/go_router.dart';

class ClickableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? hashtagStyle;
  final TextStyle? mentionStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const ClickableText({
    super.key,
    required this.text,
    this.style,
    this.hashtagStyle,
    this.mentionStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextParser.parseText(
        text,
        defaultStyle: style,
        hashtagStyle:
            hashtagStyle ??
            TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
        mentionStyle:
            mentionStyle ??
            TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
        onHashtagTap: (tag) {
          context.push('/hashtag/$tag');
        },
        onMentionTap: (username) {
          context.push('/profile/$username');
        },
      ),
    );
  }
}

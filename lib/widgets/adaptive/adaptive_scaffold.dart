import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:universal_io/io.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget? header;
  final Widget body;
  final Widget? footer;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final material.PreferredSizeWidget? appBar; // Only for Material
  final bool resizeToAvoidBottomInset;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.header,
    this.footer,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final useFluent = Provider.of<ThemeProvider>(context).useFluentUI;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (useFluent && isDesktop) {
      return fluent.ScaffoldPage(
        header: header, // Use provided header or null, but don't auto-build PageHeader
        content: body,
        bottomBar: footer,
      );
    }

    return material.Scaffold(
      appBar: appBar ?? (title != null
          ? material.AppBar(
              title: title,
              actions: actions,
              backgroundColor: material.Colors.transparent,
              elevation: 0,
            )
          : null),
      body: body,
      bottomNavigationBar: footer,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

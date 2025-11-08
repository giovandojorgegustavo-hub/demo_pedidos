import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

import 'package:demo_pedidos/widgets/app_drawer.dart';

/// Reusable scaffold that keeps the same structure across screens.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.currentSection,
    this.includeDrawer = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final AppSection? currentSection;
  final bool includeDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: includeDrawer && currentSection != null
          ? AppDrawer(current: currentSection!)
          : null,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

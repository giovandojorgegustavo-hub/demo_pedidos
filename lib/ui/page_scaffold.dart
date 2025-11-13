import 'package:flutter/material.dart';
import 'package:demo_pedidos/features/home/presentation/modules_dashboard_view.dart';
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
    this.showModulesButton = true,
    this.leading,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final AppSection? currentSection;
  final bool includeDrawer;
  final bool showModulesButton;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: includeDrawer && currentSection != null
          ? AppDrawer(current: currentSection!)
          : null,
      appBar: AppBar(
        leading: leading,
        title: Text(title),
        actions: actions,
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showModulesButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ModulesDashboardView(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    label: const Text('Panel de módulos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

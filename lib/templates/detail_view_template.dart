import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:flutter/material.dart';

typedef DetailViewBodyBuilder = Widget Function(BuildContext context);

class DetailViewTemplate extends StatelessWidget {
  const DetailViewTemplate({
    super.key,
    required this.title,
    required this.currentSection,
    required this.future,
    required this.builder,
    this.actions = const <Widget>[],
    this.includeDrawer = true,
    this.showModulesButton = true,
    this.floatingActionButton,
    this.onRetry,
    this.loadingBuilder,
    this.errorBuilder,
    this.errorTitle = 'No se pudo cargar la información.',
    this.errorMessageBuilder,
    this.retryLabel = 'Reintentar',
  });

  final String title;
  final AppSection currentSection;
  final Future<void> future;
  final DetailViewBodyBuilder builder;
  final List<Widget> actions;
  final bool includeDrawer;
  final bool showModulesButton;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRetry;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext context, Object? error)? errorBuilder;
  final String errorTitle;
  final String retryLabel;
  final String Function(Object? error)? errorMessageBuilder;

  @override
  Widget build(BuildContext context) {
    final Widget body = FutureBuilder<void>(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error);
          }
          final String message =
              errorMessageBuilder?.call(snapshot.error) ?? '${snapshot.error}';
          return _DetailTemplateError(
            title: errorTitle,
            message: message,
            retryLabel: retryLabel,
            onRetry: onRetry,
          );
        }
        return builder(context);
      },
    );

    return PageScaffold(
      title: title,
      currentSection: currentSection,
      actions: actions,
      includeDrawer: includeDrawer,
      showModulesButton: showModulesButton,
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class _DetailTemplateError extends StatelessWidget {
  const _DetailTemplateError({
    required this.title,
    required this.message,
    required this.retryLabel,
    this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  onRetry?.call();
                },
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

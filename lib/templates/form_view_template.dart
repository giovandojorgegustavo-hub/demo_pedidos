import 'package:flutter/material.dart';

class FormViewTemplate extends StatelessWidget {
  const FormViewTemplate({
    super.key,
    required this.title,
    required this.child,
    required this.isSaving,
    required this.onSave,
    this.onCancel,
    this.actions = const <Widget>[],
    this.cancelLabel = 'Cancelar',
    this.saveLabel = 'Guardar',
    this.savingLabel = 'Guardando...',
    this.showCancelButton = true,
    this.contentPadding = const EdgeInsets.all(16),
    this.wrapInScrollView = true,
  });

  final String title;
  final Widget child;
  final bool isSaving;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final List<Widget> actions;
  final String cancelLabel;
  final String saveLabel;
  final String savingLabel;
  final bool showCancelButton;
  final EdgeInsets contentPadding;
  final bool wrapInScrollView;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: contentPadding,
      child: child,
    );
    if (wrapInScrollView) {
      content = SingleChildScrollView(child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(child: content),
            SafeArea(
              top: false,
              child: _FormTemplateFooter(
                isSaving: isSaving,
                onCancel: showCancelButton ? onCancel : null,
                onSave: onSave,
                cancelLabel: cancelLabel,
                saveLabel: saveLabel,
                savingLabel: savingLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormTemplateFooter extends StatelessWidget {
  const _FormTemplateFooter({
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
    required this.cancelLabel,
    required this.saveLabel,
    required this.savingLabel,
  });

  final bool isSaving;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String cancelLabel;
  final String saveLabel;
  final String savingLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          if (onCancel != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: Text(cancelLabel),
              ),
            ),
          if (onCancel != null) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onSave,
              child: Text(isSaving ? savingLabel : saveLabel),
            ),
          ),
        ],
      ),
    );
  }
}

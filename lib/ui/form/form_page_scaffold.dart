import 'package:flutter/material.dart';

class FormPageScaffold extends StatelessWidget {
  const FormPageScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.onCancel,
    this.isSaving = false,
    this.saveLabel = 'Guardar',
    this.savingLabel = 'Guardando...',
    this.cancelLabel = 'Cancelar',
    this.actions,
    this.contentPadding = const EdgeInsets.all(16),
    this.bottomPadding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final bool isSaving;
  final String saveLabel;
  final String savingLabel;
  final String cancelLabel;
  final List<Widget>? actions;
  final EdgeInsets contentPadding;
  final EdgeInsets bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: contentPadding,
                child: child,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: bottomPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      child: Text(cancelLabel),
                    ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: isSaving ? null : onSave,
                    child: Text(isSaving ? savingLabel : saveLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

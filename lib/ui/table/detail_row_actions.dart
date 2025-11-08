import 'package:flutter/material.dart';

/// Standard action buttons for inline tables shown in detail pages.
class DetailRowActions extends StatelessWidget {
  const DetailRowActions({
    super.key,
    this.onEdit,
    this.onDelete,
    this.isDeleting = false,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[];
    if (onEdit != null) {
      buttons.add(
        TextButton(
          onPressed: onEdit,
          child: const Text('Editar'),
        ),
      );
    }
    if (onDelete != null || isDeleting) {
      buttons.add(
        TextButton(
          onPressed: isDeleting ? null : onDelete,
          child: isDeleting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Eliminar'),
        ),
      );
    }
    return Wrap(
      spacing: 4,
      children: buttons,
    );
  }
}

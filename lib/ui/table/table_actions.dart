import 'package:flutter/material.dart';

typedef TableActionHandler<T> = Future<void> Function(
  BuildContext context,
  List<T> items,
);

class TableAction<T> {
  const TableAction({
    required this.icon,
    required this.label,
    required this.handler,
    this.requiresSelection = false,
  });

  final IconData icon;
  final String label;
  final TableActionHandler<T> handler;
  final bool requiresSelection;
}

class TableActionsBar<T> extends StatelessWidget {
  const TableActionsBar({
    super.key,
    required this.actions,
    required this.selection,
  });

  final List<TableAction<T>> actions;
  final List<T> selection;

  @override
  Widget build(BuildContext context) {
    final List<TableAction<T>> visible = actions.where((TableAction<T> action) {
      if (!action.requiresSelection) {
        return true;
      }
      return selection.isNotEmpty;
    }).toList(growable: false);
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      children: visible.map((TableAction<T> action) {
        return ElevatedButton.icon(
          onPressed: () => action.handler(context, selection),
          icon: Icon(action.icon),
          label: Text(action.label),
        );
      }).toList(),
    );
  }
}

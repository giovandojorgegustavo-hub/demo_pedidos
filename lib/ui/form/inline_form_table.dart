import 'package:flutter/material.dart';

import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

/// Reusable inline table block for form screens.
class InlineFormTable<T> extends StatelessWidget {
  const InlineFormTable({
    super.key,
    required this.title,
    required this.items,
    required this.columns,
    this.minTableWidth = 560,
    this.onAdd,
    this.onRowTap,
    this.emptyMessage = 'Sin registros',
    this.helperText,
  });

  final String title;
  final List<T> items;
  final List<TableColumnConfig<T>> columns;
  final double minTableWidth;
  final VoidCallback? onAdd;
  final ValueChanged<T>? onRowTap;
  final String emptyMessage;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$title (${items.length})',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (onAdd != null)
                  TextButton(
                    onPressed: onAdd,
                    child: const Text('Nuevo'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TableSection<T>(
              items: items,
              columns: columns,
              onRowTap: onRowTap,
              minTableWidth: minTableWidth,
              dense: true,
              emptyMessage: emptyMessage,
              noResultsMessage: emptyMessage,
              shrinkWrap: true,
              showTableHeader: true,
              emptyBuilder: (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    emptyMessage,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            if (helperText != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(helperText!, style: secondaryStyle),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';

class DetailInlineSection<T> extends StatelessWidget {
  const DetailInlineSection({
    super.key,
    required this.title,
    required this.items,
    required this.columns,
    required this.minTableWidth,
    this.onAdd,
    this.onRowTap,
    this.onView,
    this.emptyMessage = 'Sin registros',
    this.showTableHeader = true,
  });

  final String title;
  final List<T> items;
  final List<TableColumnConfig<T>> columns;
  final double minTableWidth;
  final VoidCallback? onAdd;
  final ValueChanged<T>? onRowTap;
  final VoidCallback? onView;
  final String emptyMessage;
  final bool showTableHeader;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    if (onView != null)
                      TextButton(
                        onPressed: onView,
                        child: const Text('Ver'),
                      ),
                    if (onAdd != null)
                      TextButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                  ],
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
              emptyBuilder: (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(emptyMessage)),
              ),
              showTableHeader: showTableHeader,
              shrinkWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}

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
    this.rowMaxHeight,
    this.rowMaxHeightBuilder,
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
  final double? rowMaxHeight;
  final double? Function(List<T> items)? rowMaxHeightBuilder;

  bool get _hasActions => onAdd != null || onView != null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 520;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '$title (${items.length})',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (!compact && _hasActions) _buildActionsRow(),
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
                  dataRowMaxHeight:
                      rowMaxHeightBuilder?.call(items) ?? rowMaxHeight,
                ),
                if (compact && _hasActions) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildActionsRow(mainAxisAlignment: MainAxisAlignment.start),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionsRow(
      {MainAxisAlignment mainAxisAlignment = MainAxisAlignment.end}) {
    return Wrap(
      alignment: mainAxisAlignment == MainAxisAlignment.start
          ? WrapAlignment.start
          : WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
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
            label: const Text('Add'),
          ),
      ],
    );
  }
}

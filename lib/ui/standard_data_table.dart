import 'package:flutter/material.dart';

/// Describes how to render a single column inside [StandardDataTable].
class TableColumnConfig<T> {
  const TableColumnConfig({
    required this.label,
    required this.cellBuilder,
    this.isNumeric = false,
    this.sortAccessor,
    this.sortComparator,
  });

  final String label;
  final Widget Function(T item) cellBuilder;
  final bool isNumeric;
  final Comparable<Object?>? Function(T item)? sortAccessor;
  final int Function(T a, T b)? sortComparator;

  bool get isSortable => sortComparator != null || sortAccessor != null;
}

/// Consistent DataTable wrapper for both mobile and web targets.
class StandardDataTable<T> extends StatelessWidget {
  const StandardDataTable({
    super.key,
    required this.items,
    required this.columns,
    this.onRowTap,
    this.minWidth = 600,
    this.headingRowHeight = 38,
    this.dataRowHeight = 44,
    this.horizontalMargin = 12,
    this.columnSpacing = 24,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.showCheckboxColumn = false,
    this.selectedRowIndexes,
    this.onSelectRow,
    this.selectionMode = false,
    this.onRowLongPress,
    this.headerCheckboxValue,
    this.onHeaderCheckboxChanged,
  });

  final List<T> items;
  final List<TableColumnConfig<T>> columns;
  final ValueChanged<T>? onRowTap;
  final double minWidth;
  final double headingRowHeight;
  final double dataRowHeight;
  final double horizontalMargin;
  final double columnSpacing;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final bool showCheckboxColumn;
  final Set<int>? selectedRowIndexes;
  final void Function(int rowIndex, bool selected)? onSelectRow;
  final bool selectionMode;
  final void Function(int rowIndex)? onRowLongPress;
  final bool? headerCheckboxValue;
  final ValueChanged<bool?>? onHeaderCheckboxChanged;

  @override
  Widget build(BuildContext context) {
    final Color hoverColor =
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.06);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double targetWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : minWidth;
        final double effectiveMinWidth =
            targetWidth < minWidth ? minWidth : targetWidth;

        final Set<int> selectedIndexes = selectedRowIndexes ?? <int>{};
        final bool showHeaderCheckbox =
            showCheckboxColumn && selectionMode && headerCheckboxValue != null;
        Widget expandCell(Widget child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.centerLeft,
            child: child,
          );
        }

        final DataTable table = DataTable(
          showCheckboxColumn: false,
          headingRowHeight: headingRowHeight,
          dataRowMinHeight: dataRowHeight,
          dataRowMaxHeight: dataRowHeight,
          horizontalMargin: horizontalMargin,
          columnSpacing: columnSpacing,
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          columns: <DataColumn>[
            if (showCheckboxColumn)
              DataColumn(
                label: showHeaderCheckbox
                    ? Checkbox(
                        value: headerCheckboxValue,
                        tristate: true,
                        onChanged: onHeaderCheckboxChanged,
                      )
                    : const SizedBox.shrink(),
              ),
            ...columns.asMap().entries.map(
                  (MapEntry<int, TableColumnConfig<T>> entry) => DataColumn(
                    label: Text(entry.value.label),
                    numeric: entry.value.isNumeric,
                    onSort: entry.value.isSortable && onSort != null
                        ? (int columnIndex, bool ascending) =>
                            onSort!(entry.key, ascending)
                        : null,
                  ),
                ),
          ],
          rows: items.asMap().entries.map((MapEntry<int, T> entry) {
            final int rowIndex = entry.key;
            final T item = entry.value;
            final bool isSelected =
                selectionMode && selectedIndexes.contains(rowIndex);
            bool longPressHandled = false;

            Widget wrapLongPress(Widget child) {
              if (onRowLongPress == null) {
                return expandCell(child);
              }
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () {
                  if (longPressHandled) {
                    return;
                  }
                  longPressHandled = true;
                  onRowLongPress!(rowIndex);
                },
                child: expandCell(child),
              );
            }

            final List<DataCell> dataCells = <DataCell>[];
            if (showCheckboxColumn) {
              dataCells.add(
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      if (value == null) {
                        return;
                      }
                      onSelectRow?.call(rowIndex, value);
                    },
                  ),
                ),
              );
            }

            dataCells.addAll(
              columns.map(
                (TableColumnConfig<T> column) {
                  Widget cellContent = column.cellBuilder(item);
                  cellContent = wrapLongPress(cellContent);
                  return DataCell(
                    cellContent,
                    onTap: showCheckboxColumn && selectionMode
                        ? () => onSelectRow?.call(rowIndex, !isSelected)
                        : onRowTap == null
                            ? null
                            : () => onRowTap!(item),
                  );
                },
              ),
            );

            return DataRow(
              selected: isSelected,
              onSelectChanged: selectionMode && onSelectRow != null
                  ? (bool? selected) {
                      if (selected == null) {
                        return;
                      }
                      onSelectRow!(rowIndex, selected);
                    }
                  : null,
              color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)) {
                    return hoverColor;
                  }
                  return null;
                },
              ),
              cells: dataCells,
            );
          }).toList(growable: false),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: effectiveMinWidth),
            child: table,
          ),
        );
      },
    );
  }
}

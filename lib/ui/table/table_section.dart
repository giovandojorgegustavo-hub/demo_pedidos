import 'package:flutter/material.dart';

import 'package:demo_pedidos/ui/standard_data_table.dart';

typedef ItemPredicate<T> = bool Function(T item);
typedef GroupComparator = int Function(String a, String b);

class TableFilterOption<T> {
  const TableFilterOption({
    required this.label,
    this.predicate,
    this.isDefault = false,
  });

  final String label;
  final ItemPredicate<T>? predicate;
  final bool isDefault;
}

class TableFilterConfig<T> {
  const TableFilterConfig({
    required this.label,
    required this.options,
  });

  final String label;
  final List<TableFilterOption<T>> options;
}

class TableSelectionConfig<T> {
  const TableSelectionConfig({
    required this.isItemSelected,
    required this.onSelectionChange,
    this.selectionMode = false,
    this.showCheckboxColumn = true,
    this.onRequestSelectionStart,
  });

  final bool Function(T item) isItemSelected;
  final void Function(T item, bool selected) onSelectionChange;
  final bool selectionMode;
  final bool showCheckboxColumn;
  final void Function(T item)? onRequestSelectionStart;
}

class TableSection<T> extends StatefulWidget {
  const TableSection({
    super.key,
    required this.items,
    required this.columns,
    this.onRowTap,
    this.onRefresh,
    this.groupBy,
    this.groupLabelBuilder,
    this.groupComparator,
    this.filters = const [],
    this.searchTextBuilder,
    this.searchPlaceholder,
    this.emptyMessage = 'Sin registros',
    this.noResultsMessage = 'No hay coincidencias con los filtros.',
    this.minTableWidth = 600,
    this.dense = true,
    this.emptyBuilder,
    this.toolbarActions = const <Widget>[],
    this.showTableHeader = true,
    this.shrinkWrap = false,
    this.selectionConfig,
    this.dataRowMaxHeight,
    this.dataRowMaxHeightBuilder,
  });

  final List<T> items;
  final List<TableColumnConfig<T>> columns;
  final ValueChanged<T>? onRowTap;
  final Future<void> Function()? onRefresh;
  final String Function(T item)? groupBy;
  final String Function(String key)? groupLabelBuilder;
  final GroupComparator? groupComparator;
  final List<TableFilterConfig<T>> filters;
  final String Function(T item)? searchTextBuilder;
  final String? searchPlaceholder;
  final String emptyMessage;
  final String noResultsMessage;
  final double minTableWidth;
  final bool dense;
  final WidgetBuilder? emptyBuilder;
  final List<Widget> toolbarActions;
  final bool showTableHeader;
  final bool shrinkWrap;
  final TableSelectionConfig<T>? selectionConfig;
  final double? dataRowMaxHeight;
  final double? Function(List<T> items)? dataRowMaxHeightBuilder;

  @override
  State<TableSection<T>> createState() => _TableSectionState<T>();
}

class _TableSectionState<T> extends State<TableSection<T>> {
  late final TextEditingController _searchController;
  final Map<int, int> _selectedOptions = <int, int>{};
  final Set<String> _expandedGroups = <String>{};
  String _searchTerm = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  bool get _hasSearch => widget.searchTextBuilder != null;
  bool get _hasFilters => widget.filters.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() {
        setState(() {
          _searchTerm = _searchController.text.toLowerCase();
        });
      });
    _initSelectedOptions();
  }

  @override
  void didUpdateWidget(TableSection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filters.length != oldWidget.filters.length) {
      _initSelectedOptions();
    } else {
      for (int i = 0; i < widget.filters.length; i++) {
        final int optionCount = widget.filters[i].options.length;
        final int? selected = _selectedOptions[i];
        if (selected == null || selected >= optionCount) {
          _selectedOptions[i] =
              _defaultOptionIndex(widget.filters[i].options);
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initSelectedOptions() {
    _selectedOptions.clear();
    for (int i = 0; i < widget.filters.length; i++) {
      _selectedOptions[i] = _defaultOptionIndex(widget.filters[i].options);
    }
  }

  int _defaultOptionIndex(List<TableFilterOption<T>> options) {
    final int index =
        options.indexWhere((TableFilterOption<T> opt) => opt.isDefault);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final List<T> filteredItems = _applyFilters(widget.items);
    final List<T> sortedItems = _applySort(filteredItems);
    final bool isEmpty = filteredItems.isEmpty;
    final TableSelectionConfig<T>? selectionConfig = widget.selectionConfig;
    final bool selectionEnabled = selectionConfig != null;
    final Set<int>? selectedIndexes = selectionEnabled
        ? sortedItems
            .asMap()
            .entries
            .where(
              (MapEntry<int, T> entry) =>
                  selectionConfig.isItemSelected(entry.value),
            )
            .map((MapEntry<int, T> entry) => entry.key)
            .toSet()
        : null;

    final List<Widget> bodyChildren = <Widget>[];
    final bool showToolbar =
        _hasFilters || _hasSearch || widget.toolbarActions.isNotEmpty;
    if (showToolbar) {
      bodyChildren.add(_buildToolbar(context));
    }

    if (widget.items.isEmpty) {
      bodyChildren.add(
        widget.emptyBuilder?.call(context) ?? _buildMessage(widget.emptyMessage),
      );
    } else if (isEmpty) {
      bodyChildren.add(_buildMessage(widget.noResultsMessage));
    } else if (widget.groupBy != null) {
      bodyChildren.addAll(_buildGroupedTables(sortedItems));
    } else {
      bodyChildren.add(
        _buildTable(
          sortedItems,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          selectionConfig: selectionConfig,
          selectedIndexes: selectedIndexes,
        ),
      );
    }

    Widget content = ListView(
      shrinkWrap: widget.shrinkWrap,
      primary: !widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const ClampingScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      children: bodyChildren,
    );

    if (widget.onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: content,
      );
    }

    return content;
  }

  List<T> _applyFilters(List<T> source) {
    return source.where((T item) {
      for (final MapEntry<int, int> entry in _selectedOptions.entries) {
        final TableFilterOption<T> option =
            widget.filters[entry.key].options[entry.value];
        if (option.predicate != null && !option.predicate!(item)) {
          return false;
        }
      }
      if (_searchTerm.isNotEmpty && widget.searchTextBuilder != null) {
        final String haystack =
            widget.searchTextBuilder!(item).toLowerCase();
        if (!haystack.contains(_searchTerm)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  Widget _buildToolbar(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasActiveFilters = _hasFilters && _selectedOptions.entries.any(
      (MapEntry<int, int> entry) => !_isOptionDefault(entry.key, entry.value),
    );

    final List<Widget> trailing = <Widget>[]
      ..addAll(widget.toolbarActions);
    if (_hasFilters) {
      trailing.add(
        _ToolbarIconButton(
          icon: Icons.filter_list,
          indicatorColor: hasActiveFilters ? theme.colorScheme.primary : null,
          onTap: _openFiltersSheet,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: <Widget>[
          if (_hasSearch)
            Expanded(child: _buildSearchField())
          else if (trailing.isNotEmpty)
            const Spacer(),
          if (_hasSearch && trailing.isNotEmpty) const SizedBox(width: 8),
          ...trailing,
        ],
      ),
    );
  }

  bool _isOptionDefault(int filterIndex, int optionIndex) {
    final List<TableFilterOption<T>> options = widget.filters[filterIndex].options;
    final int defaultIndex = _defaultOptionIndex(options);
    return optionIndex == defaultIndex;
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, size: 18),
          hintText: widget.searchPlaceholder ?? 'Buscar',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTables(List<T> items) {
    final Map<String, List<T>> groups = <String, List<T>>{};
    for (final T item in items) {
      final String key = widget.groupBy!(item);
      groups.putIfAbsent(key, () => <T>[]).add(item);
    }

    final List<String> keys = groups.keys.toList(growable: false);
    keys.sort(widget.groupComparator ?? (String a, String b) => a.compareTo(b));
    _syncExpandedKeys(keys);

    final List<Widget> sections = <Widget>[];

    for (final String key in keys) {
      final String label = widget.groupLabelBuilder?.call(key) ?? key;
      final List<T> groupItems = groups[key]!;
      final List<T> sortedGroup = _applySort(groupItems);
      final TableSelectionConfig<T>? selectionConfig = widget.selectionConfig;
      final bool selectionEnabled = selectionConfig != null;
      final Set<int>? selectedIndexes = selectionEnabled
          ? sortedGroup
              .asMap()
              .entries
              .where(
                (MapEntry<int, T> entry) =>
                    selectionConfig.isItemSelected(entry.value),
              )
              .map((MapEntry<int, T> entry) => entry.key)
              .toSet()
          : null;
      final bool expanded = _expandedGroups.contains(key);

      sections.add(
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>(key),
            initiallyExpanded: expanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            title: Text(
              '$label (${groupItems.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onExpansionChanged: (bool value) {
              setState(() {
                if (value) {
                  _expandedGroups.add(key);
                } else {
                  _expandedGroups.remove(key);
                }
              });
            },
            children: <Widget>[
              _buildTable(
                sortedGroup,
                padding: EdgeInsets.zero,
                selectionConfig: selectionConfig,
                selectedIndexes: selectedIndexes,
              ),
            ],
          ),
        ),
      );
      if (key != keys.last) {
        sections.add(const Divider(height: 0, indent: 12, endIndent: 12));
      }
    }

    return sections;
  }

  Widget _buildTable(
    List<T> items, {
    required EdgeInsets padding,
    TableSelectionConfig<T>? selectionConfig,
    Set<int>? selectedIndexes,
  }) {
    final double headingHeight = widget.dense ? 32 : 48;
    final double rowHeight = widget.dense ? 36 : 52;
    final TableSelectionConfig<T>? config = selectionConfig;
    final bool selectionMode = config?.selectionMode ?? false;
    final bool showCheckboxColumn =
        selectionMode && (config?.showCheckboxColumn ?? false);
    final ValueChanged<T>? effectiveRowTap =
        selectionMode && config != null
            ? (T item) {
                final bool currentlySelected =
                    config.isItemSelected(item);
                config.onSelectionChange(item, !currentlySelected);
              }
            : widget.onRowTap;
    bool? headerCheckboxValue;
    if (showCheckboxColumn) {
      if (selectedIndexes != null && selectedIndexes.isNotEmpty) {
        if (selectedIndexes.length == items.length) {
          headerCheckboxValue = true;
        } else {
          headerCheckboxValue = null;
        }
      } else {
        headerCheckboxValue = false;
      }
    }

    return Padding(
      padding: padding,
      child: StandardDataTable<T>(
        items: items,
        columns: widget.columns,
        onRowTap: effectiveRowTap,
        minWidth: widget.minTableWidth,
        headingRowHeight: widget.showTableHeader ? headingHeight : 0,
        dataRowHeight: rowHeight,
        dataRowMaxHeight:
            widget.dataRowMaxHeightBuilder?.call(items) ??
                widget.dataRowMaxHeight,
        horizontalMargin: widget.dense ? 12 : 16,
        columnSpacing: widget.dense ? 20 : 24,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        onSort: widget.showTableHeader ? _handleSort : null,
        showCheckboxColumn: showCheckboxColumn,
        selectedRowIndexes: selectionMode ? selectedIndexes : null,
        onSelectRow: showCheckboxColumn && config != null
            ? (int index, bool selected) {
                final T item = items[index];
                config.onSelectionChange(item, selected);
              }
            : null,
        selectionMode: selectionMode,
        onRowLongPress: !selectionMode &&
                config?.onRequestSelectionStart != null
            ? (int index) {
                final T item = items[index];
                config?.onRequestSelectionStart?.call(item);
              }
            : null,
        headerCheckboxValue: headerCheckboxValue,
        onHeaderCheckboxChanged:
            showCheckboxColumn && config != null && items.isNotEmpty
                ? (bool? value) {
                    final bool shouldSelect = value ?? false;
                    for (final T item in items) {
                      final bool currently = config.isItemSelected(item);
                      if (currently != shouldSelect) {
                        config.onSelectionChange(item, shouldSelect);
                      }
                    }
                  }
                : null,
      ),
    );
  }

  void _openFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.filters.length,
                    itemBuilder: (BuildContext context, int index) {
                      final TableFilterConfig<T> filter = widget.filters[index];
                      final ThemeData sheetTheme = Theme.of(context);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: StatefulBuilder(
                          builder: (BuildContext context, StateSetter setModalState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  filter.label,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: filter.options.asMap().entries.map(
                                    (MapEntry<int, TableFilterOption<T>> optEntry) {
                                      final int optionIndex = optEntry.key;
                                      final TableFilterOption<T> option = optEntry.value;
                                      final bool isSelected = optionIndex == _selectedOptions[index];
                                      return ChoiceChip(
                                        label: Text(option.label),
                                        selected: isSelected,
                                        showCheckmark: false,
                                        backgroundColor:
                                            sheetTheme.colorScheme.surfaceContainerHighest,
                                        selectedColor: sheetTheme
                                            .colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? sheetTheme.colorScheme.primary
                                              : sheetTheme.colorScheme.onSurface,
                                          fontWeight: isSelected ? FontWeight.w600 : null,
                                        ),
                                        side: BorderSide(
                                          color: isSelected
                                              ? sheetTheme.colorScheme.primary
                                              : sheetTheme.dividerColor,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        onSelected: (bool value) {
                                          if (!value) {
                                            return;
                                          }
                                          setState(() {
                                            _selectedOptions[index] = optionIndex;
                                          });
                                          setModalState(() {});
                                        },
                                      );
                                    },
                                  ).toList(),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TextButton(
                      onPressed: () {
                        setState(_initSelectedOptions);
                      },
                      child: const Text('Limpiar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _syncExpandedKeys(List<String> keys) {
    _expandedGroups.removeWhere((String key) => !keys.contains(key));
    if (_expandedGroups.isEmpty && keys.isNotEmpty) {
      _expandedGroups.add(keys.first);
    }
  }

  List<T> _applySort(List<T> source) {
    final int? columnIndex = _sortColumnIndex;
    if (columnIndex == null) {
      return source;
    }
    if (columnIndex < 0 || columnIndex >= widget.columns.length) {
      return source;
    }
    final TableColumnConfig<T> column = widget.columns[columnIndex];
    if (!column.isSortable) {
      return source;
    }

    final Comparator<T>? comparator = column.sortComparator ??
        (column.sortAccessor != null
            ? (T a, T b) {
                final Comparable<Object?>? aValue = column.sortAccessor!(a);
                final Comparable<Object?>? bValue = column.sortAccessor!(b);
                if (aValue == null && bValue == null) {
                  return 0;
                }
                if (aValue == null) {
                  return -1;
                }
                if (bValue == null) {
                  return 1;
                }
                return aValue.compareTo(bValue);
              }
            : null);
    if (comparator == null) {
      return source;
    }

    final List<T> sorted = List<T>.from(source);
    sorted.sort((T a, T b) {
      final int result = comparator(a, b);
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  void _handleSort(int columnIndex, bool ascending) {
    final TableColumnConfig<T> column = widget.columns[columnIndex];
    if (!column.isSortable) {
      return;
    }
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.onTap,
    this.indicatorColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20),
          ),
        ),
        if (indicatorColor != null)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

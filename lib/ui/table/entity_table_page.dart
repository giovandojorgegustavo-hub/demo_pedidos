import 'dart:async';
import 'package:demo_pedidos/shared/app_sections.dart';

import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';

class EntityTablePage<T> extends StatefulWidget {
  EntityTablePage({
    super.key,
    required this.title,
    required this.loadItems,
    required this.columns,
    this.currentSection,
    this.includeDrawer = false,
    this.returnResult = false,
    this.onCreate,
    this.onRowTap,
    this.searchTextBuilder,
    this.searchPlaceholder,
    List<TableFilterConfig<T>>? filters,
    this.groupBy,
    this.groupLabelBuilder,
    this.groupComparator,
    this.minTableWidth = 600,
    this.emptyMessage,
    this.noResultsMessage,
    this.dense = true,
    this.fabLabel,
    this.fabIcon,
    this.extraActions,
    this.onDeleteSelected,
    this.bulkDeleteLabel = 'Eliminar',
    this.bulkDeleteIcon = Icons.delete_outline,
    this.bulkDeleteConfirmBuilder,
  }) : filters = filters ?? <TableFilterConfig<T>>[];

  final String title;
  final Future<List<T>> Function() loadItems;
  final List<TableColumnConfig<T>> columns;
  final AppSection? currentSection;
  final bool includeDrawer;
  final bool returnResult;
  final Future<bool?> Function(BuildContext context)? onCreate;
  final Future<bool?> Function(BuildContext context, T item)? onRowTap;
  final String Function(T item)? searchTextBuilder;
  final String? searchPlaceholder;
  final List<TableFilterConfig<T>> filters;
  final String Function(T item)? groupBy;
  final String Function(String key)? groupLabelBuilder;
  final int Function(String a, String b)? groupComparator;
  final double minTableWidth;
  final String? emptyMessage;
  final String? noResultsMessage;
  final bool dense;
  final String? fabLabel;
  final Widget? fabIcon;
  final List<Widget>? extraActions;
  final Future<void> Function(BuildContext context, List<T> items)?
      onDeleteSelected;
  final String bulkDeleteLabel;
  final IconData bulkDeleteIcon;
  final String Function(int count)? bulkDeleteConfirmBuilder;

  @override
  State<EntityTablePage<T>> createState() => _EntityTablePageState<T>();
}

class _EntityTablePageState<T> extends State<EntityTablePage<T>> {
  late Future<List<T>> _future;
  bool _hasChanges = false;
  List<T> _currentItems = <T>[];
  bool _selectionMode = false;
  bool _isDeletingSelection = false;
  Set<int> _selectedIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    _future = widget.loadItems();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.loadItems();
    });
    await _future;
  }

  Future<void> _handleCreate() async {
    if (widget.onCreate == null) {
      return;
    }
    final bool? result = await widget.onCreate!(context);
    if (result == true) {
      _hasChanges = true;
      await _reload();
    }
  }

  Future<void> _handleRowTap(T item) async {
    if (widget.onRowTap == null) {
      return;
    }
    final bool? result = await widget.onRowTap!(context, item);
    if (result == true) {
      _hasChanges = true;
      await _reload();
    }
  }

  bool get _hasSelection => _selectedIndexes.isNotEmpty;

  void _toggleSelection(int index, bool selected) {
    setState(() {
      if (selected) {
        _selectedIndexes.add(index);
        _selectionMode = true;
      } else {
        _selectedIndexes.remove(index);
        if (_selectedIndexes.isEmpty) {
          _selectionMode = false;
        }
      }
    });
  }

  void _startSelection(int index) {
    setState(() {
      _selectionMode = true;
      _selectedIndexes = <int>{index};
    });
  }

  void _exitSelection() {
    if (!_selectionMode) {
      return;
    }
    setState(() {
      _selectionMode = false;
      _selectedIndexes.clear();
    });
  }

  List<T> _selectedItems(List<T> items) {
    return _selectedIndexes
        .where((int index) => index >= 0 && index < items.length)
        .map((int index) => items[index])
        .toList(growable: false);
  }

  Future<void> _deleteSelected(
    BuildContext context,
    List<T> items,
  ) async {
    if (widget.onDeleteSelected == null || items.isEmpty) {
      return;
    }
    final String message =
        widget.bulkDeleteConfirmBuilder?.call(items.length) ??
            '¿Deseas eliminar ${items.length} '
                'registro${items.length == 1 ? '' : 's'}? '
                'Esta acción no se puede deshacer.';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.bulkDeleteLabel),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(widget.bulkDeleteLabel),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeletingSelection = true;
    });
    try {
      await widget.onDeleteSelected!(context, items);
      _hasChanges = true;
      _exitSelection();
      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron eliminar los registros: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingSelection = false;
        });
      }
    }
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (widget.onDeleteSelected != null &&
        _selectionMode &&
        _hasSelection) {
      return FloatingActionButton.extended(
        onPressed: _isDeletingSelection
            ? null
            : () {
                unawaited(
                  _deleteSelected(
                    context,
                    _selectedItems(_currentItems),
                  ),
                );
              },
        icon: _isDeletingSelection
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(widget.bulkDeleteIcon),
        label: Text(
          '${widget.bulkDeleteLabel} (${_selectedIndexes.length})',
        ),
      );
    }

    if (widget.onCreate == null) {
      return null;
    }
    return FloatingActionButton.extended(
      onPressed: () {
        unawaited(_handleCreate());
      },
      icon: widget.fabIcon ?? const Icon(Icons.add),
      label: Text(widget.fabLabel ?? 'Agregar'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = <Widget>[
      if (_selectionMode && widget.onDeleteSelected != null)
        IconButton(
          onPressed: _exitSelection,
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar selección',
        ),
      IconButton(
        onPressed: () {
          unawaited(_reload());
        },
        icon: const Icon(Icons.refresh),
        tooltip: 'Actualizar',
      ),
      if (widget.extraActions != null) ...widget.extraActions!,
    ];

    final Widget scaffold = PageScaffold(
      title: widget.title,
      currentSection: widget.currentSection,
      includeDrawer: widget.includeDrawer,
      actions: actions,
      floatingActionButton: _buildFloatingActionButton(context),
      body: FutureBuilder<List<T>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<T>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EntityErrorState(
              onRetry: () {
                unawaited(_reload());
              },
              message: 'No se pudieron cargar los registros',
              error: snapshot.error,
            );
          }

          final List<T> items = snapshot.data ?? <T>[];
          _currentItems = items;
          final bool selectionEnabled = widget.onDeleteSelected != null;
          if (_selectedIndexes.isNotEmpty) {
            final Set<int> trimmed =
                _selectedIndexes.where((int idx) => idx < items.length).toSet();
            if (trimmed.length != _selectedIndexes.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _selectedIndexes = trimmed;
                  if (_selectedIndexes.isEmpty) {
                    _selectionMode = false;
                  }
                });
              });
            }
          }

          final TableSelectionConfig<T>? selectionConfig = selectionEnabled
              ? TableSelectionConfig<T>(
                  isItemSelected: (T item) {
                    final int index = items.indexOf(item);
                    if (index == -1) {
                      return false;
                    }
                    return _selectedIndexes.contains(index);
                  },
                  onSelectionChange: (T item, bool selected) {
                    final int index = items.indexOf(item);
                    if (index == -1) {
                      return;
                    }
                    _toggleSelection(index, selected);
                  },
                  selectionMode: _selectionMode,
                  showCheckboxColumn: true,
                  onRequestSelectionStart: (T item) {
                    final int index = items.indexOf(item);
                    if (index == -1) {
                      return;
                    }
                    _startSelection(index);
                  },
                )
              : null;

          return TableSection<T>(
            items: items,
            columns: widget.columns,
            onRowTap: widget.onRowTap == null
                ? null
                : (T item) {
                    unawaited(_handleRowTap(item));
                  },
            onRefresh: _reload,
            searchTextBuilder: widget.searchTextBuilder,
            searchPlaceholder: widget.searchPlaceholder,
            filters: widget.filters,
            groupBy: widget.groupBy,
            groupLabelBuilder: widget.groupLabelBuilder,
            groupComparator: widget.groupComparator,
            minTableWidth: widget.minTableWidth,
            emptyMessage: widget.emptyMessage ?? 'Sin registros.',
            noResultsMessage: widget.noResultsMessage ??
                widget.emptyMessage ??
                'Sin registros.',
            dense: widget.dense,
            selectionConfig: selectionConfig,
          );
        },
      ),
    );

    if (!widget.returnResult) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, _hasChanges);
      },
      child: scaffold,
    );
  }
}

class _EntityErrorState extends StatelessWidget {
  const _EntityErrorState({
    required this.onRetry,
    required this.message,
    this.error,
  });

  final VoidCallback onRetry;
  final String message;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

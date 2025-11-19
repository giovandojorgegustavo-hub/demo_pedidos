import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/list_selection_state.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';

typedef ListViewRowTap<T> = Future<void> Function(
  T item,
  ListViewTemplateController<T> controller,
);

typedef ListViewCreateCallback<T> = Future<void> Function(
  ListViewTemplateController<T> controller,
);

typedef ListViewDeleteCallback<T> = Future<void> Function(
  ListViewTemplateController<T> controller,
  Set<String> ids,
);

typedef ListViewActionsBuilder<T> = List<Widget> Function(
  BuildContext context,
  ListViewTemplateController<T> controller,
);

typedef ListViewFloatingActionButtonBuilder<T> = Widget? Function(
  BuildContext context,
  ListViewTemplateController<T> controller,
  bool hasSelection,
  bool isDeleting,
);

class ListViewTemplateConfig<T> {
  ListViewTemplateConfig({
    required this.title,
    required this.currentSection,
    required this.loader,
    required this.idSelector,
    required this.columns,
    required this.searchTextBuilder,
    List<TableFilterConfig<T>>? filters,
    this.searchPlaceholder = 'Buscar',
    this.emptyMessage = 'Sin registros',
    this.noResultsMessage =
        'No hay resultados que coincidan con los filtros seleccionados.',
    this.minTableWidth = 640,
    this.denseTable = true,
    this.includeDrawer = true,
    this.showModulesButton = true,
    List<ListViewTemplateTab<T>>? tabs,
    this.showCreateShortcut = false,
    this.actions = const <Widget>[],
    this.actionsBuilder,
    this.onInit,
    this.onDispose,
    this.onRowTap,
    this.onCreate,
    this.onDeleteSelected,
    this.confirmDeleteBuilder,
    this.deleteSelectionLabelBuilder,
    this.deleteErrorMessageBuilder,
    this.floatingActionButtonBuilder,
    this.onErrorMessageBuilder,
    this.errorTitle = 'No se pudo cargar la información.',
    this.retryLabel = 'Reintentar',
    this.includeRefreshAction = true,
    this.loadingBuilder,
    this.showSelectionControls = true,
  })  : filters = filters ?? const [],
        tabs = tabs ?? const [];

  final String title;
  final AppSection currentSection;
  final Future<List<T>> Function() loader;
  final String Function(T item) idSelector;
  final List<TableColumnConfig<T>> columns;
  final List<TableFilterConfig<T>> filters;
  final String Function(T item) searchTextBuilder;
  final String searchPlaceholder;
  final String emptyMessage;
  final String noResultsMessage;
  final double minTableWidth;
  final bool denseTable;
  final bool includeDrawer;
  final bool showModulesButton;
  final List<ListViewTemplateTab<T>> tabs;
  final bool showCreateShortcut;
  final List<Widget> actions;
  final ListViewActionsBuilder<T>? actionsBuilder;
  final void Function(ListViewTemplateController<T> controller)? onInit;
  final VoidCallback? onDispose;
  final ListViewRowTap<T>? onRowTap;
  final ListViewCreateCallback<T>? onCreate;
  final ListViewDeleteCallback<T>? onDeleteSelected;
  final Future<bool> Function(BuildContext context, int count)?
      confirmDeleteBuilder;
  final String Function(int count)? deleteSelectionLabelBuilder;
  final String Function(Object error)? deleteErrorMessageBuilder;
  final ListViewFloatingActionButtonBuilder<T>? floatingActionButtonBuilder;
  final String Function(Object? error)? onErrorMessageBuilder;
  final String errorTitle;
  final String retryLabel;
  final bool includeRefreshAction;
  final WidgetBuilder? loadingBuilder;
  final bool showSelectionControls;
}

class ListViewTemplateTab<T> {
  const ListViewTemplateTab({
    required this.labelBuilder,
    this.predicate,
    this.emptyMessage,
    this.noResultsMessage,
    this.showCreateShortcut = false,
  });

  final String Function(List<T> items) labelBuilder;
  final bool Function(T item)? predicate;
  final String? emptyMessage;
  final String? noResultsMessage;
  final bool showCreateShortcut;
}

class ListViewTemplateController<T> {
  ListViewTemplateController({
    required Future<void> Function() reload,
    required VoidCallback clearSelection,
    required ListSelectionState<T> selection,
    required List<T> Function() itemsProvider,
    required BuildContext Function() contextProvider,
  })  : _reload = reload,
        _clearSelection = clearSelection,
        _itemsProvider = itemsProvider,
        _contextProvider = contextProvider,
        selection = selection;

  final Future<void> Function() _reload;
  final VoidCallback _clearSelection;
  final List<T> Function() _itemsProvider;
  final BuildContext Function() _contextProvider;
  final ListSelectionState<T> selection;

  Future<void> reload() => _reload();

  void clearSelection() => _clearSelection();

  List<T> get items => _itemsProvider();

  BuildContext get context => _contextProvider();

  bool get hasSelection => selection.hasSelection;

  int get selectionLength => selection.length;

  Set<String> get selectedIds => selection.ids;
}

class ListViewTemplate<T> extends StatefulWidget {
  const ListViewTemplate({super.key, required this.config});

  final ListViewTemplateConfig<T> config;

  @override
  State<ListViewTemplate<T>> createState() => _ListViewTemplateState<T>();
}

class _ListViewTemplateState<T> extends State<ListViewTemplate<T>> {
  late Future<List<T>> _future;
  late final ListSelectionState<T> _selection =
      ListSelectionState<T>(idSelector: widget.config.idSelector);
  late final ListViewTemplateController<T> _controller =
      ListViewTemplateController<T>(
    reload: _reload,
    clearSelection: _clearSelection,
    selection: _selection,
    itemsProvider: () => _items,
    contextProvider: () => context,
  );

  List<T> _items = <T>[];
  List<String> _tabLabels = <String>[];
  bool _isDeleting = false;

  bool get _hasTabs => widget.config.tabs.isNotEmpty;
  bool get _showTabBar => widget.config.tabs.length > 1;

  @override
  void initState() {
    super.initState();
    _tabLabels = _computeTabLabels(const []);
    widget.config.onInit?.call(_controller);
    _future = _load();
  }

  @override
  void dispose() {
    widget.config.onDispose?.call();
    super.dispose();
  }

  Future<List<T>> _load() async {
    final List<T> items = await widget.config.loader();
    if (!mounted) {
      return items;
    }
    setState(() {
      _items = items;
      _tabLabels = _computeTabLabels(items);
    });
    _selection.removeMissing(items);
    return items;
  }

  Future<void> _reload() {
    setState(() {
      _future = _load();
    });
    return _future;
  }

  void _clearSelection() {
    if (!_selection.hasSelection) {
      return;
    }
    setState(() {
      _selection.clear();
    });
  }

  List<String> _computeTabLabels(List<T> items) {
    if (!_hasTabs) {
      return const <String>[];
    }
    return widget.config.tabs
        .map(
          (ListViewTemplateTab<T> tab) => tab.labelBuilder(items),
        )
        .toList(growable: false);
  }

  List<T> _itemsForTab(int index) {
    if (!_hasTabs) {
      return _items;
    }
    final bool Function(T item)? predicate =
        widget.config.tabs[index].predicate;
    if (predicate == null) {
      return _items;
    }
    return _items.where(predicate).toList(growable: false);
  }

  Widget _buildTableSection(
    List<T> tabItems, {
    required String emptyMessage,
    required String noResultsMessage,
    required bool showCreateShortcut,
  }) {
    final bool enableSelection = widget.config.onDeleteSelected != null &&
        widget.config.showSelectionControls;
    return TableSection<T>(
      items: tabItems,
      columns: widget.config.columns,
      onRowTap: widget.config.onRowTap == null
          ? null
          : (T item) {
              widget.config.onRowTap!(item, _controller);
            },
      onRefresh: _reload,
      filters: widget.config.filters,
      searchTextBuilder: widget.config.searchTextBuilder,
      searchPlaceholder: widget.config.searchPlaceholder,
      emptyMessage: emptyMessage,
      noResultsMessage: noResultsMessage,
      minTableWidth: widget.config.minTableWidth,
      dense: widget.config.denseTable,
      selectionConfig: enableSelection
          ? TableSelectionConfig<T>(
              isItemSelected: (T item) => _selection.isSelected(item),
              onSelectionChange: (T item, bool selected) {
                setState(() {
                  _selection.setSelected(item, selected);
                });
              },
              selectionMode: _selection.hasSelection,
              showCheckboxColumn: true,
              onRequestSelectionStart: (T item) {
                setState(() {
                  _selection.setSelected(item, true);
                });
              },
            )
          : null,
      emptyBuilder: showCreateShortcut && widget.config.onCreate != null
          ? (BuildContext context) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(emptyMessage),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _handleCreate(),
                      child: const Text('Crear'),
                    ),
                  ],
                ),
              )
          : null,
    );
  }

  Future<void> _handleCreate() async {
    final ListViewCreateCallback<T>? onCreate = widget.config.onCreate;
    if (onCreate == null) {
      return;
    }
    try {
      await onCreate(_controller);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar la acción: $error')),
      );
    }
  }

  Future<void> _handleDeleteSelected() async {
    final ListViewDeleteCallback<T>? onDelete = widget.config.onDeleteSelected;
    if (onDelete == null || !_selection.hasSelection) {
      return;
    }
    final Future<bool> Function(BuildContext context, int count)?
        confirmDelete = widget.config.confirmDeleteBuilder;
    bool confirmed = true;
    if (confirmDelete != null) {
      confirmed = await confirmDelete(context, _selection.length);
    } else {
      confirmed = await _defaultConfirmDelete(_selection.length);
    }
    if (!confirmed) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });
    try {
      await onDelete(_controller, _selection.ids);
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeleting = false;
        _selection.clear();
      });
      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeleting = false;
      });
      final String message =
          widget.config.deleteErrorMessageBuilder?.call(error) ??
              'No se pudieron eliminar los registros: $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<bool> _defaultConfirmDelete(int count) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Eliminar registros'),
            content: Text(
              '¿Deseas eliminar $count registro'
              '${count == 1 ? '' : 's'}? Esta acción no se puede deshacer.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget? _buildFloatingActionButton() {
    final ListViewFloatingActionButtonBuilder<T>? builder =
        widget.config.floatingActionButtonBuilder;
    if (builder != null) {
      return builder(
        context,
        _controller,
        _selection.hasSelection,
        _isDeleting,
      );
    }

    if (_selection.hasSelection && widget.config.onDeleteSelected != null) {
      final String label =
          widget.config.deleteSelectionLabelBuilder?.call(_selection.length) ??
              'Eliminar (${_selection.length})';
      final Widget icon = _isDeleting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_outline);
      return FloatingActionButton.extended(
        onPressed: _isDeleting ? null : _handleDeleteSelected,
        icon: icon,
        label: Text(_isDeleting ? 'Eliminando...' : label),
      );
    }

    if (widget.config.onCreate != null) {
      return FloatingActionButton(
        onPressed: _handleCreate,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  List<Widget> _buildActions() {
    final List<Widget> actions = <Widget>[];
    actions.addAll(widget.config.actions);
    if (widget.config.actionsBuilder != null) {
      actions.addAll(widget.config.actionsBuilder!(context, _controller));
    }
    if (widget.config.includeRefreshAction) {
      actions.add(
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      );
    }
    return actions;
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<List<T>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return widget.config.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      final String message =
          widget.config.onErrorMessageBuilder?.call(snapshot.error) ??
              '${snapshot.error}';
      return _ListTemplateError(
        title: widget.config.errorTitle,
        message: message,
        retryLabel: widget.config.retryLabel,
        onRetry: _reload,
      );
    }

    final List<T> items = snapshot.data ?? _items;
    if (_hasTabs) {
      if (_showTabBar) {
        return TabBarView(
          children:
              List<Widget>.generate(widget.config.tabs.length, (int index) {
            final ListViewTemplateTab<T> tab = widget.config.tabs[index];
            final List<T> tabItems = _itemsForTab(index);
            return _buildTableSection(
              tabItems,
              emptyMessage: tab.emptyMessage ?? widget.config.emptyMessage,
              noResultsMessage:
                  tab.noResultsMessage ?? widget.config.noResultsMessage,
              showCreateShortcut: tab.showCreateShortcut,
            );
          }),
        );
      }
      final ListViewTemplateTab<T> tab = widget.config.tabs.first;
      final List<T> tabItems = _itemsForTab(0);
      return _buildTableSection(
        tabItems,
        emptyMessage: tab.emptyMessage ?? widget.config.emptyMessage,
        noResultsMessage:
            tab.noResultsMessage ?? widget.config.noResultsMessage,
        showCreateShortcut: tab.showCreateShortcut,
      );
    }

    return _buildTableSection(
      items,
      emptyMessage: widget.config.emptyMessage,
      noResultsMessage: widget.config.noResultsMessage,
      showCreateShortcut: widget.config.showCreateShortcut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final PreferredSizeWidget? bottom = _showTabBar
        ? TabBar(
            tabs: List<Widget>.generate(
              widget.config.tabs.length,
              (int index) => Tab(
                text: index < _tabLabels.length
                    ? _tabLabels[index]
                    : widget.config.tabs[index].labelBuilder(_items),
              ),
            ),
          )
        : null;

    final Widget scaffold = PageScaffold(
      title: widget.config.title,
      currentSection: widget.config.currentSection,
      includeDrawer: widget.config.includeDrawer,
      showModulesButton: widget.config.showModulesButton,
      actions: _buildActions(),
      bottom: bottom,
      floatingActionButton: _buildFloatingActionButton(),
      body: FutureBuilder<List<T>>(
        future: _future,
        builder: _buildBody,
      ),
    );

    if (_showTabBar) {
      return DefaultTabController(
        length: widget.config.tabs.length,
        child: scaffold,
      );
    }
    return scaffold;
  }
}

class _ListTemplateError extends StatelessWidget {
  const _ListTemplateError({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

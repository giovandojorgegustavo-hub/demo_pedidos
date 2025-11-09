import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/stock_movimiento.dart';
import 'package:demo_pedidos/models/stock_por_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class OperacionesDashboardView extends StatefulWidget {
  const OperacionesDashboardView({
    super.key,
    this.initialSection = AppSection.operacionesStock,
  }) : assert(
          initialSection == AppSection.operacionesStock ||
              initialSection == AppSection.operacionesHistorial,
        );

  final AppSection initialSection;

  @override
  State<OperacionesDashboardView> createState() =>
      _OperacionesDashboardViewState();
}

class _OperacionesDashboardViewState extends State<OperacionesDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  late AppSection _currentSection;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: _sectionToIndex(_currentSection),
    );
    _controller.addListener(_handleTabChange);
  }

  @override
  void didUpdateWidget(covariant OperacionesDashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _currentSection = widget.initialSection;
      _controller.index = _sectionToIndex(_currentSection);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTabChange);
    _controller.dispose();
    super.dispose();
  }

  int _sectionToIndex(AppSection section) {
    return section == AppSection.operacionesHistorial ? 1 : 0;
  }

  void _handleTabChange() {
    if (_controller.indexIsChanging) {
      return;
    }
    final AppSection nextSection = _controller.index == 0
        ? AppSection.operacionesStock
        : AppSection.operacionesHistorial;
    if (nextSection != _currentSection) {
      setState(() {
        _currentSection = nextSection;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Operaciones',
      currentSection: _currentSection,
      body: Column(
        children: <Widget>[
          TabBar(
            controller: _controller,
            tabs: const <Tab>[
              Tab(text: 'Stock total'),
              Tab(text: 'Historial'),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: const <Widget>[
                _StockTab(),
                _HistorialTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockTab extends StatefulWidget {
  const _StockTab();

  @override
  State<_StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<_StockTab> {
  late Future<_StockData> _future = _load();

  Future<_StockData> _load() async {
    final List<StockPorBase> items = await StockPorBase.fetchAll();
    return _StockData.fromItems(items);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StockData>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<_StockData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('No se pudo cargar el stock.'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _reload,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final _StockData data = snapshot.data ?? _StockData.empty();
        if (data.bases.isEmpty && data.general.isEmpty) {
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              children: const <Widget>[
                SizedBox(height: 80),
                Center(child: Text('No hay registros de stock.')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Resumen general',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _StockTable.general(data.general),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...data.bases.map(
                (_BaseStock base) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          base.baseNombre,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _StockTable.base(base.baseNombre, base.items),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockTable extends StatelessWidget {
  const _StockTable.general(this.general)
      : baseName = null,
        items = null;
  const _StockTable.base(this.baseName, this.items) : general = null;

  final List<_StockSummary>? general;
  final String? baseName;
  final List<StockPorBase>? items;

  @override
  Widget build(BuildContext context) {
    if (general != null) {
      return TableSection<_StockSummary>(
        items: general!,
        columns: _generalColumns,
        emptyMessage: 'Sin productos registrados.',
        searchPlaceholder: 'Buscar producto',
        searchTextBuilder: (_StockSummary item) => item.productoNombre,
        shrinkWrap: false,
      );
    }
    final List<StockPorBase> data = items ?? <StockPorBase>[];
    return TableSection<StockPorBase>(
      items: data,
      columns: _baseColumns,
      emptyMessage: 'Sin productos registrados en esta base.',
      searchPlaceholder: 'Buscar producto',
      searchTextBuilder: (StockPorBase item) => item.productoNombre,
      shrinkWrap: false,
    );
  }

  List<TableColumnConfig<_StockSummary>> get _generalColumns {
    return <TableColumnConfig<_StockSummary>>[
      TableColumnConfig<_StockSummary>(
        label: 'Producto',
        cellBuilder: (_StockSummary item) => Text(item.productoNombre),
        sortAccessor: (_StockSummary item) => item.productoNombre,
      ),
      TableColumnConfig<_StockSummary>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (_StockSummary item) => item.cantidadTotal,
        cellBuilder: (_StockSummary item) =>
            Text(item.cantidadTotal.toStringAsFixed(2)),
      ),
      TableColumnConfig<_StockSummary>(
        label: '# Bases',
        isNumeric: true,
        sortAccessor: (_StockSummary item) => item.baseCount,
        cellBuilder: (_StockSummary item) => Text('${item.baseCount}'),
      ),
    ];
  }

  List<TableColumnConfig<StockPorBase>> get _baseColumns {
    return <TableColumnConfig<StockPorBase>>[
      TableColumnConfig<StockPorBase>(
        label: 'Producto',
        cellBuilder: (StockPorBase item) => Text(item.productoNombre),
        sortAccessor: (StockPorBase item) => item.productoNombre,
      ),
      TableColumnConfig<StockPorBase>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (StockPorBase item) => item.cantidad,
        cellBuilder: (StockPorBase item) =>
            Text(item.cantidad.toStringAsFixed(2)),
      ),
    ];
  }
}

class _StockData {
  const _StockData({
    required this.general,
    required this.bases,
  });

  final List<_StockSummary> general;
  final List<_BaseStock> bases;

  static _StockData empty() => const _StockData(
        general: <_StockSummary>[],
        bases: <_BaseStock>[],
      );

  int get baseTabsLength => bases.isEmpty ? 1 : bases.length + 1;

  List<String> get tabTitles {
    if (bases.isEmpty) {
      return <String>['General'];
    }
    return <String>[
      'General',
      ...bases.map((_) => _.baseNombre),
    ];
  }

  factory _StockData.fromItems(List<StockPorBase> items) {
    final Map<String, _StockSummary> summary = <String, _StockSummary>{};
    final Map<String?, List<StockPorBase>> grouped =
        <String?, List<StockPorBase>>{};

    for (final StockPorBase item in items) {
      final _StockSummary? existing = summary[item.idproducto];
      final Set<String?> baseRefs = existing != null
          ? Set<String?>.from(existing.baseRefs)
          : <String?>{};
      baseRefs.add(item.idbase);
      summary[item.idproducto] = _StockSummary(
        idproducto: item.idproducto,
        productoNombre: item.productoNombre,
        cantidadTotal: (existing?.cantidadTotal ?? 0) + item.cantidad,
        baseRefs: baseRefs,
      );
      grouped.putIfAbsent(item.idbase, () => <StockPorBase>[]).add(item);
    }

    final List<_StockSummary> general = summary.values.toList()
      ..sort(
        (_StockSummary a, _StockSummary b) =>
            a.productoNombre.compareTo(b.productoNombre),
      );
    final List<_BaseStock> bases = grouped.entries
        .map(
          (MapEntry<String?, List<StockPorBase>> entry) => _BaseStock(
            idbase: entry.key,
            baseNombre:
                entry.value.isEmpty ? '-' : entry.value.first.baseNombre,
            items: entry.value
              ..sort(
                (StockPorBase a, StockPorBase b) =>
                    a.productoNombre.compareTo(b.productoNombre),
              ),
          ),
        )
        .toList()
      ..sort(
        (_BaseStock a, _BaseStock b) =>
            a.baseNombre.toLowerCase().compareTo(b.baseNombre.toLowerCase()),
      );

    return _StockData(general: general, bases: bases);
  }
}

class _StockSummary {
  const _StockSummary({
    required this.idproducto,
    required this.productoNombre,
    required this.cantidadTotal,
    required this.baseRefs,
  });

  final String idproducto;
  final String productoNombre;
  final double cantidadTotal;
  final Set<String?> baseRefs;

  int get baseCount => baseRefs.length;
}

class _BaseStock {
  const _BaseStock({
    required this.idbase,
    required this.baseNombre,
    required this.items,
  });

  final String? idbase;
  final String baseNombre;
  final List<StockPorBase> items;
}

class _HistorialTab extends StatefulWidget {
  const _HistorialTab();

  @override
  State<_HistorialTab> createState() => _HistorialTabState();
}

class _HistorialTabState extends State<_HistorialTab> {
  late Future<List<StockMovimiento>> _future = _load();

  Future<List<StockMovimiento>> _load() => StockMovimiento.fetchLatest();

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StockMovimiento>>(
      future: _future,
      builder:
          (BuildContext context, AsyncSnapshot<List<StockMovimiento>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('No se pudo cargar el historial.'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _reload,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final List<StockMovimiento> data = snapshot.data ?? <StockMovimiento>[];
        return RefreshIndicator(
          onRefresh: _reload,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TableSection<StockMovimiento>(
              items: data,
              columns: <TableColumnConfig<StockMovimiento>>[
                TableColumnConfig<StockMovimiento>(
                  label: 'Fecha',
                  sortAccessor: (StockMovimiento item) =>
                      item.registradoAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                  cellBuilder: (StockMovimiento item) =>
                      Text(_formatDate(item.registradoAt)),
                ),
                TableColumnConfig<StockMovimiento>(
                  label: 'Base',
                  sortAccessor: (StockMovimiento item) => item.baseNombre,
                  cellBuilder: (StockMovimiento item) => Text(item.baseNombre),
                ),
                TableColumnConfig<StockMovimiento>(
                  label: 'Producto',
                  sortAccessor: (StockMovimiento item) => item.productoNombre,
                  cellBuilder: (StockMovimiento item) =>
                      Text(item.productoNombre),
                ),
                TableColumnConfig<StockMovimiento>(
                  label: 'Cantidad',
                  isNumeric: true,
                  sortAccessor: (StockMovimiento item) => item.cantidad,
                  cellBuilder: (StockMovimiento item) =>
                      Text(item.cantidad.toStringAsFixed(2)),
                ),
                TableColumnConfig<StockMovimiento>(
                  label: 'Tipo',
                  sortAccessor: (StockMovimiento item) => item.tipomov,
                  cellBuilder: (StockMovimiento item) => Text(item.tipomov),
                ),
                TableColumnConfig<StockMovimiento>(
                  label: 'Operativo',
                  sortAccessor: (StockMovimiento item) => item.idoperativo,
                  cellBuilder: (StockMovimiento item) => Text(item.idoperativo),
                ),
              ],
              emptyMessage: 'Sin movimientos registrados.',
              searchPlaceholder: 'Buscar producto, base o tipo',
              searchTextBuilder: (StockMovimiento item) =>
                  '${item.productoNombre} ${item.baseNombre} ${item.tipomov} ${item.idoperativo}',
              shrinkWrap: false,
            ),
          ),
        );
      },
    );
  }
}

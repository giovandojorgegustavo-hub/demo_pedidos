import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/stock_movimiento.dart';
import 'package:demo_pedidos/models/stock_por_base.dart';
import 'package:demo_pedidos/services/module_access_service.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class OperacionesStockView extends StatefulWidget {
  const OperacionesStockView({super.key});

  @override
  State<OperacionesStockView> createState() => _OperacionesStockViewState();
}

class _OperacionesStockViewState extends State<OperacionesStockView> {
  late Future<_StockData> _future = _load();
  bool _showAllBaseProducts = false;
  final Set<String?> _visibleBaseIds = <String?>{};
  bool _canSeeCosts = false;

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
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    try {
      final Set<String> modules =
          await ModuleAccessService().loadModulesForCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() {
        _canSeeCosts = modules.contains('finanzas');
      });
    } catch (_) {
      // Ignore – default is false so sensitive info stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Operaciones',
      currentSection: AppSection.operacionesStock,
      body: FutureBuilder<_StockData>(
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
          _syncVisibleBases(data.bases);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          FilterChip(
                            label: const Text('Todas las bases'),
                            selected:
                                _visibleBaseIds.length == data.bases.length,
                            onSelected: (bool value) {
                              setState(() {
                                if (value) {
                                  _visibleBaseIds
                                    ..clear()
                                    ..addAll(data.bases.map((_) => _.idbase));
                                } else {
                                  _visibleBaseIds.clear();
                                }
                              });
                            },
                          ),
                          ...data.bases.map(
                            (_BaseStock base) => FilterChip(
                              label: Text(base.baseNombre),
                              selected: _visibleBaseIds.contains(base.idbase),
                              onSelected: (bool value) {
                                setState(() {
                                  if (value) {
                                    _visibleBaseIds.add(base.idbase);
                                  } else {
                                    _visibleBaseIds.remove(base.idbase);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _showAllBaseProducts
                              ? 'Todos los productos'
                              : 'Solo con stock',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 6),
                        Switch.adaptive(
                          value: _showAllBaseProducts,
                          onChanged: (bool value) {
                            setState(() {
                              _showAllBaseProducts = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
                        _StockTable.general(
                          data.general,
                          showCosts: _canSeeCosts,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...data.bases
                    .where(
                      (_BaseStock base) => _visibleBaseIds.contains(base.idbase),
                    )
                    .map(
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
                              _StockTable.base(
                                base.baseNombre,
                                base.items,
                                showCosts: _canSeeCosts,
                                showAll: _showAllBaseProducts,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _syncVisibleBases(List<_BaseStock> bases) {
    final Set<String?> ids = bases.map(( _BaseStock base) => base.idbase).toSet();
    _visibleBaseIds.removeWhere((String? id) => !ids.contains(id));
    if (_visibleBaseIds.isEmpty) {
      _visibleBaseIds.addAll(ids);
    }
  }
}

class _StockTable extends StatelessWidget {
  const _StockTable.general(
    this.general, {
    required this.showCosts,
  })  : baseName = null,
        items = null,
        showAll = true;

  const _StockTable.base(
    this.baseName,
    this.items, {
    required this.showCosts,
    this.showAll = false,
  }) : general = null;

  final List<_StockSummary>? general;
  final String? baseName;
  final List<StockPorBase>? items;
  final bool showAll;
  final bool showCosts;

  @override
  Widget build(BuildContext context) {
    if (general != null) {
      final double? totalValor = showCosts ? _generalTotalValue() : null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TableSection<_StockSummary>(
            items: general!,
            columns: _generalColumns,
            emptyMessage: 'Sin productos registrados.',
            searchPlaceholder: 'Buscar producto',
            searchTextBuilder: (_StockSummary item) => item.productoNombre,
            shrinkWrap: true,
          ),
          if (totalValor != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total inventario: ${_formatCurrency(totalValor)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      );
    }
    final List<StockPorBase> data = items ?? <StockPorBase>[];
    final List<StockPorBase> filtered = showAll
        ? data
        : data.where((StockPorBase item) => item.cantidad > 0).toList();
    final double? totalValor =
        showCosts ? _baseTotalValue(filtered) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TableSection<StockPorBase>(
          items: filtered,
          columns: _baseColumns,
          emptyMessage:
              showAll ? 'Sin productos registrados en esta base.' : 'Sin stock.',
          searchPlaceholder: 'Buscar producto',
          searchTextBuilder: (StockPorBase item) => item.productoNombre,
          shrinkWrap: true,
        ),
        if (totalValor != null) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal base: ${_formatCurrency(totalValor)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }

  double? _generalTotalValue() {
    final List<_StockSummary>? data = general;
    if (data == null) {
      return null;
    }
    return data.fold<double>(
      0,
      (double sum, _StockSummary item) => sum + item.valorTotal,
    );
  }

  double? _baseTotalValue(List<StockPorBase> data) {
    if (data.isEmpty) {
      return 0;
    }
    return data.fold<double>(
      0,
      (double sum, StockPorBase item) => sum + item.valorTotal,
    );
  }

  String _formatCurrency(double value) => 'S/ ${value.toStringAsFixed(2)}';

  List<TableColumnConfig<_StockSummary>> get _generalColumns {
    final List<TableColumnConfig<_StockSummary>> columns =
        <TableColumnConfig<_StockSummary>>[
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
    ];
    if (showCosts) {
      columns.addAll(<TableColumnConfig<_StockSummary>>[
        TableColumnConfig<_StockSummary>(
          label: 'Costo unitario',
          isNumeric: true,
          sortAccessor: (_StockSummary item) => item.costoUnitario,
          cellBuilder: (_StockSummary item) => Text(
            'S/ ${item.costoUnitario.toStringAsFixed(2)}',
          ),
        ),
        TableColumnConfig<_StockSummary>(
          label: 'Valor total',
          isNumeric: true,
          sortAccessor: (_StockSummary item) => item.valorTotal,
          cellBuilder: (_StockSummary item) => Text(
            'S/ ${item.valorTotal.toStringAsFixed(2)}',
          ),
        ),
      ]);
    }
    columns.add(
      TableColumnConfig<_StockSummary>(
        label: '# Bases',
        isNumeric: true,
        sortAccessor: (_StockSummary item) => item.baseCount,
        cellBuilder: (_StockSummary item) => Text('${item.baseCount}'),
      ),
    );
    return columns;
  }

  List<TableColumnConfig<StockPorBase>> get _baseColumns {
    final List<TableColumnConfig<StockPorBase>> columns =
        <TableColumnConfig<StockPorBase>>[
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
    if (showCosts) {
      columns.addAll(<TableColumnConfig<StockPorBase>>[
        TableColumnConfig<StockPorBase>(
          label: 'Costo unitario',
          isNumeric: true,
          sortAccessor: (StockPorBase item) => item.costoUnitario,
          cellBuilder: (StockPorBase item) =>
              Text('S/ ${item.costoUnitario.toStringAsFixed(2)}'),
        ),
        TableColumnConfig<StockPorBase>(
          label: 'Valor total',
          isNumeric: true,
          sortAccessor: (StockPorBase item) => item.valorTotal,
          cellBuilder: (StockPorBase item) =>
              Text('S/ ${item.valorTotal.toStringAsFixed(2)}'),
        ),
      ]);
    }
    return columns;
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
        costoUnitario: existing?.costoUnitario ?? item.costoUnitario,
        valorTotal: (existing?.valorTotal ?? 0) + item.valorTotal,
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
    required this.costoUnitario,
    required this.valorTotal,
    required this.baseRefs,
  });

  final String idproducto;
  final String productoNombre;
  final double cantidadTotal;
  final double costoUnitario;
  final double valorTotal;
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

class OperacionesHistorialView extends StatefulWidget {
  const OperacionesHistorialView({super.key});

  @override
  State<OperacionesHistorialView> createState() =>
      _OperacionesHistorialViewState();
}

class _OperacionesHistorialViewState extends State<OperacionesHistorialView> {
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
    return PageScaffold(
      title: 'Operaciones',
      currentSection: AppSection.operacionesHistorial,
      body: FutureBuilder<List<StockMovimiento>>(
        future: _future,
        builder: (BuildContext context,
            AsyncSnapshot<List<StockMovimiento>> snapshot) {
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
          final List<StockMovimiento> data =
              snapshot.data ?? <StockMovimiento>[];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                TableSection<StockMovimiento>(
                  items: data,
                  columns: <TableColumnConfig<StockMovimiento>>[
                    TableColumnConfig<StockMovimiento>(
                      label: 'Fecha',
                      sortAccessor: (StockMovimiento item) =>
                          item.registradoAt ??
                          DateTime.fromMillisecondsSinceEpoch(0),
                      cellBuilder: (StockMovimiento item) =>
                          Text(_formatDate(item.registradoAt)),
                    ),
                    TableColumnConfig<StockMovimiento>(
                      label: 'Base',
                      sortAccessor: (StockMovimiento item) => item.baseNombre,
                      cellBuilder: (StockMovimiento item) =>
                          Text(item.baseNombre),
                    ),
                    TableColumnConfig<StockMovimiento>(
                      label: 'Producto',
                      sortAccessor: (StockMovimiento item) =>
                          item.productoNombre,
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
                      cellBuilder: (StockMovimiento item) =>
                          Text(item.tipomov),
                    ),
                  ],
                  emptyMessage: 'Sin movimientos registrados.',
                  searchPlaceholder: 'Buscar producto, base o tipo',
                  searchTextBuilder: (StockMovimiento item) =>
                      '${item.productoNombre} ${item.baseNombre} ${item.tipomov} ${item.idoperativo}',
                  shrinkWrap: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

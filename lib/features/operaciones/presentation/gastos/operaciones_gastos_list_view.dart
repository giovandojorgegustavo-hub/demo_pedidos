import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/models/operaciones_gasto.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class OperacionesGastosListView extends StatefulWidget {
  const OperacionesGastosListView({
    super.key,
    this.currentSection = AppSection.operacionesGastos,
  });

  final AppSection currentSection;

  @override
  State<OperacionesGastosListView> createState() =>
      _OperacionesGastosListViewState();
}

class _OperacionesGastosListViewState
    extends State<OperacionesGastosListView> {
  late Future<List<OperacionesGasto>> _future = _load();
  DateTimeRange? _dateRange;
  String? _origenFilter;
  String? _baseFilter;
  List<LogisticaBase> _bases = <LogisticaBase>[];
  Future<void>? _basesFuture;

  final Map<String, String> _origenLabels = <String, String>{
    'transferencia': 'Transferencia',
    'fabricacion': 'Fabricación',
    'ajuste': 'Ajuste',
  };

  @override
  void initState() {
    super.initState();
    _basesFuture = _loadBases();
  }

  Future<void> _loadBases() async {
    final List<LogisticaBase> bases = await LogisticaBase.getBases();
    if (!mounted) {
      return;
    }
    setState(() {
      _bases = bases;
    });
  }

  Future<List<OperacionesGasto>> _load() {
    return OperacionesGasto.fetchAll(
      from: _dateRange?.start,
      to: _dateRange?.end,
      origen: _origenFilter,
      baseId: _baseFilter,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _selectDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange initialRange = _dateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Gastos operativos',
      currentSection: widget.currentSection,
      actions: <Widget>[
        IconButton(
          tooltip: 'Filtrar por fecha',
          onPressed: _selectDateRange,
          icon: const Icon(Icons.date_range_outlined),
        ),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Column(
        children: <Widget>[
          _Filters(
            dateLabel: _dateRangeLabel(),
            onDateTap: _selectDateRange,
            origenFilter: _origenFilter,
            origenLabels: _origenLabels,
            onOrigenChanged: (String? value) async {
              setState(() {
                _origenFilter = value;
              });
              await _reload();
            },
            baseFilter: _baseFilter,
            bases: _bases,
            onBaseChanged: (String? value) async {
              setState(() {
                _baseFilter = value;
              });
              await _reload();
            },
            basesFuture: _basesFuture,
          ),
          Expanded(
            child: FutureBuilder<List<OperacionesGasto>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<OperacionesGasto>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudieron cargar los gastos.'),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final List<OperacionesGasto> data =
                    snapshot.data ?? <OperacionesGasto>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('No hay gastos para los filtros seleccionados.'),
                  );
                }
                return TableSection<OperacionesGasto>(
                  items: data,
                  columns: _columns,
                  searchPlaceholder: 'Buscar por descripción, base o producto',
                  searchTextBuilder: (OperacionesGasto gasto) =>
                      '${gasto.descripcion} ${gasto.baseNombre ?? ''} ${gasto.productoNombre ?? ''}',
                  minTableWidth: 1000,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<OperacionesGasto>> get _columns {
    return <TableColumnConfig<OperacionesGasto>>[
      TableColumnConfig<OperacionesGasto>(
        label: 'Fecha',
        sortAccessor: (OperacionesGasto gasto) =>
            gasto.registradoAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (OperacionesGasto gasto) =>
            Text(_formatDate(gasto.registradoAt)),
      ),
      TableColumnConfig<OperacionesGasto>(
        label: 'Origen',
        sortAccessor: (OperacionesGasto gasto) => gasto.origen,
        cellBuilder: (OperacionesGasto gasto) =>
            Text(_origenLabels[gasto.origen] ?? gasto.origen),
      ),
      TableColumnConfig<OperacionesGasto>(
        label: 'Base',
        sortAccessor: (OperacionesGasto gasto) => gasto.baseNombre ?? '',
        cellBuilder: (OperacionesGasto gasto) =>
            Text(gasto.baseNombre ?? 'Sin base'),
      ),
      TableColumnConfig<OperacionesGasto>(
        label: 'Descripción',
        sortAccessor: (OperacionesGasto gasto) => gasto.descripcion,
        cellBuilder: (OperacionesGasto gasto) => Text(gasto.descripcion),
      ),
      TableColumnConfig<OperacionesGasto>(
        label: 'Producto',
        sortAccessor: (OperacionesGasto gasto) => gasto.productoNombre ?? '',
        cellBuilder: (OperacionesGasto gasto) =>
            Text(gasto.productoNombre ?? '-'),
      ),
      TableColumnConfig<OperacionesGasto>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (OperacionesGasto gasto) => gasto.monto,
        cellBuilder: (OperacionesGasto gasto) =>
            Text('S/ ${gasto.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<OperacionesGasto>(
        label: 'Registrado por',
        sortAccessor: (OperacionesGasto gasto) => gasto.registradoPor ?? '',
        cellBuilder: (OperacionesGasto gasto) =>
            Text(gasto.registradoPor ?? '-'),
      ),
    ];
  }

  String _dateRangeLabel() {
    if (_dateRange == null) {
      return 'Rango de fechas';
    }
    final DateTime start = _dateRange!.start;
    final DateTime end = _dateRange!.end;
    return '${_formatDate(start)} · ${_formatDate(end)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.dateLabel,
    required this.onDateTap,
    required this.origenFilter,
    required this.origenLabels,
    required this.onOrigenChanged,
    required this.baseFilter,
    required this.bases,
    required this.onBaseChanged,
    this.basesFuture,
  });

  final String dateLabel;
  final VoidCallback onDateTap;
  final String? origenFilter;
  final Map<String, String> origenLabels;
  final ValueChanged<String?> onOrigenChanged;
  final String? baseFilter;
  final List<LogisticaBase> bases;
  final ValueChanged<String?> onBaseChanged;
  final Future<void>? basesFuture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ElevatedButton.icon(
            onPressed: onDateTap,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(dateLabel),
          ),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String?>(
              key: ValueKey<String>('origen-${origenFilter ?? 'all'}'),
              initialValue: origenFilter,
              decoration: const InputDecoration(labelText: 'Origen'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...origenLabels.entries.map(
                  (MapEntry<String, String> entry) => DropdownMenuItem<String?>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
              ],
              onChanged: onOrigenChanged,
            ),
          ),
          SizedBox(
            width: 240,
            child: FutureBuilder<void>(
              future: basesFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                return DropdownButtonFormField<String?>(
                  key: ValueKey<String>('base-${baseFilter ?? 'all'}'),
                  initialValue: baseFilter,
                  decoration: const InputDecoration(labelText: 'Base'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...bases.map(
                      (LogisticaBase base) => DropdownMenuItem<String?>(
                        value: base.id,
                        child: Text(base.nombre),
                      ),
                    ),
                  ],
                  onChanged: onBaseChanged,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

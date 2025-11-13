import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/contabilidad_balance_mensual.dart';
import 'package:demo_pedidos/models/cuenta_contable.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class ContabilidadBalanceMensualView extends StatefulWidget {
  const ContabilidadBalanceMensualView({super.key});

  @override
  State<ContabilidadBalanceMensualView> createState() =>
      _ContabilidadBalanceMensualViewState();
}

class _ContabilidadBalanceMensualViewState
    extends State<ContabilidadBalanceMensualView> {
  late Future<List<ContabilidadBalanceMensual>> _future = _load();
  DateTimeRange? _dateRange;
  String? _tipoFilter;
  String? _cuentaFilter;
  List<CuentaContable> _cuentas = <CuentaContable>[];
  Future<void>? _cuentasFuture;

  final List<MapEntry<String, String>> _tipos = <MapEntry<String, String>>[
    const MapEntry<String, String>('activo', 'Activo'),
    const MapEntry<String, String>('pasivo', 'Pasivo'),
    const MapEntry<String, String>('patrimonio', 'Patrimonio'),
    const MapEntry<String, String>('ingreso', 'Ingreso'),
    const MapEntry<String, String>('gasto', 'Gasto'),
  ];

  @override
  void initState() {
    super.initState();
    _cuentasFuture = _loadCuentas();
  }

  Future<void> _loadCuentas() async {
    final List<CuentaContable> cuentas =
        await CuentaContable.fetchTerminales();
    if (!mounted) {
      return;
    }
    setState(() {
      _cuentas = cuentas;
    });
  }

  Future<List<ContabilidadBalanceMensual>> _load() {
    return ContabilidadBalanceMensual.fetchAll(
      from: _dateRange?.start,
      to: _dateRange?.end,
      tipo: _tipoFilter,
      cuentaContableId: _cuentaFilter,
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
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year, now.month, 1),
        );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
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
      title: 'Balance mensual',
      currentSection: AppSection.contabilidadBalanceMensual,
      actions: <Widget>[
        IconButton(
          tooltip: 'Filtrar por fechas',
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
            tipoFilter: _tipoFilter,
            tipos: _tipos,
            onTipoChanged: (String? value) async {
              setState(() {
                _tipoFilter = value;
              });
              await _reload();
            },
            cuentaFilter: _cuentaFilter,
            cuentas: _cuentas,
            cuentasFuture: _cuentasFuture,
            onCuentaChanged: (String? value) async {
              setState(() {
                _cuentaFilter = value;
              });
              await _reload();
            },
          ),
          Expanded(
            child: FutureBuilder<List<ContabilidadBalanceMensual>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<ContabilidadBalanceMensual>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudo cargar el balance.'),
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
                final List<ContabilidadBalanceMensual> data =
                    snapshot.data ?? <ContabilidadBalanceMensual>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin registros para los filtros actuales.'),
                  );
                }
                return TableSection<ContabilidadBalanceMensual>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 1000,
                  searchPlaceholder: 'Buscar por cuenta o código',
                  searchTextBuilder: (ContabilidadBalanceMensual item) =>
                      '${item.cuentaContableCodigo} ${item.cuentaContableNombre}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<ContabilidadBalanceMensual>> get _columns {
    return <TableColumnConfig<ContabilidadBalanceMensual>>[
      TableColumnConfig<ContabilidadBalanceMensual>(
        label: 'Periodo',
        sortAccessor: (ContabilidadBalanceMensual item) => item.periodo,
        cellBuilder: (ContabilidadBalanceMensual item) =>
            Text(_formatPeriod(item.periodo)),
      ),
      TableColumnConfig<ContabilidadBalanceMensual>(
        label: 'Código',
        sortAccessor: (ContabilidadBalanceMensual item) =>
            item.cuentaContableCodigo,
        cellBuilder: (ContabilidadBalanceMensual item) =>
            Text(item.cuentaContableCodigo),
      ),
      TableColumnConfig<ContabilidadBalanceMensual>(
        label: 'Cuenta contable',
        sortAccessor: (ContabilidadBalanceMensual item) =>
            item.cuentaContableNombre,
        cellBuilder: (ContabilidadBalanceMensual item) =>
            Text(item.cuentaContableNombre),
      ),
      TableColumnConfig<ContabilidadBalanceMensual>(
        label: 'Tipo',
        sortAccessor: (ContabilidadBalanceMensual item) => item.tipo,
        cellBuilder: (ContabilidadBalanceMensual item) =>
            Text(_tipoLabel(item.tipo)),
      ),
      TableColumnConfig<ContabilidadBalanceMensual>(
        label: 'Saldo',
        isNumeric: true,
        sortAccessor: (ContabilidadBalanceMensual item) => item.saldo,
        cellBuilder: (ContabilidadBalanceMensual item) =>
            Text('S/ ${item.saldo.toStringAsFixed(2)}'),
      ),
    ];
  }

  String _dateRangeLabel() {
    if (_dateRange == null) {
      return 'Último año';
    }
    return '${_formatDate(_dateRange!.start)} · ${_formatDate(_dateRange!.end)}';
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '01/$month/$year';
  }

  String _formatPeriod(DateTime date) {
    final List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _tipoLabel(String tipo) {
    final Map<String, String> labels = <String, String>{
      'activo': 'Activo',
      'pasivo': 'Pasivo',
      'patrimonio': 'Patrimonio',
      'ingreso': 'Ingreso',
      'gasto': 'Gasto',
    };
    return labels[tipo] ?? tipo;
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.dateLabel,
    required this.onDateTap,
    required this.tipoFilter,
    required this.tipos,
    required this.onTipoChanged,
    required this.cuentaFilter,
    required this.cuentas,
    required this.cuentasFuture,
    required this.onCuentaChanged,
  });

  final String dateLabel;
  final VoidCallback onDateTap;
  final String? tipoFilter;
  final List<MapEntry<String, String>> tipos;
  final ValueChanged<String?> onTipoChanged;
  final String? cuentaFilter;
  final List<CuentaContable> cuentas;
  final Future<void>? cuentasFuture;
  final ValueChanged<String?> onCuentaChanged;

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
              key: ValueKey<String>('tipo-${tipoFilter ?? 'todos'}'),
              initialValue: tipoFilter,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...tipos.map(
                  (MapEntry<String, String> entry) =>
                      DropdownMenuItem<String?>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
              ],
              onChanged: onTipoChanged,
            ),
          ),
          SizedBox(
            width: 260,
            child: FutureBuilder<void>(
              future: cuentasFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                return DropdownButtonFormField<String?>(
                  key: ValueKey<String>('cuenta-${cuentaFilter ?? 'todas'}'),
                  initialValue: cuentaFilter,
                  decoration:
                      const InputDecoration(labelText: 'Cuenta contable'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...cuentas.map(
                      (CuentaContable cuenta) => DropdownMenuItem<String?>(
                        value: cuenta.id,
                        child: Text('${cuenta.codigo} · ${cuenta.nombre}'),
                      ),
                    ),
                  ],
                  onChanged: onCuentaChanged,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

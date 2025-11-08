import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

import '../form/cuentas_form_view.dart';

class CuentasListView extends StatefulWidget {
  const CuentasListView({super.key});

  @override
  State<CuentasListView> createState() => _CuentasListViewState();
}

class _CuentasListViewState extends State<CuentasListView> {
  late Future<List<CuentaBancaria>> _future;
  final Set<String> _updating = <String>{};

  @override
  void initState() {
    super.initState();
    _future = CuentaBancaria.getTodas();
  }

  Future<void> _reload() async {
    setState(() {
      _future = CuentaBancaria.getTodas();
    });
    await _future;
  }

  Future<void> _toggleEstado(CuentaBancaria cuenta, bool value) async {
    setState(() {
      _updating.add(cuenta.id);
    });
    try {
      await CuentaBancaria.updateEstado(id: cuenta.id, activa: value);
      await _reload();
      if (mounted) {
        setState(() {
          _updating.remove(cuenta.id);
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la cuenta: $error')),
      );
      setState(() {
        _updating.remove(cuenta.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Cuentas bancarias',
      currentSection: AppSection.bancos,
      actions: <Widget>[
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
      body: FutureBuilder<List<CuentaBancaria>>(
        future: _future,
        builder: (BuildContext context,
            AsyncSnapshot<List<CuentaBancaria>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('No se pudo cargar la lista de cuentas.'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<CuentaBancaria> cuentas =
              snapshot.data ?? <CuentaBancaria>[];
          if (cuentas.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('Aún no has registrado cuentas bancarias.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _openNuevaCuenta,
                          child: const Text('Agregar cuenta'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return TableSection<CuentaBancaria>(
            items: cuentas,
            columns: <TableColumnConfig<CuentaBancaria>>[
              TableColumnConfig<CuentaBancaria>(
                label: 'Nombre',
                sortAccessor: (CuentaBancaria cuenta) => cuenta.nombre,
                cellBuilder: (CuentaBancaria cuenta) => Text(cuenta.nombre),
              ),
              TableColumnConfig<CuentaBancaria>(
                label: 'Banco',
                sortAccessor: (CuentaBancaria cuenta) => cuenta.banco ?? '',
                cellBuilder: (CuentaBancaria cuenta) =>
                    Text(cuenta.banco ?? '-'),
              ),
              TableColumnConfig<CuentaBancaria>(
                label: 'Activa',
                sortComparator: (CuentaBancaria a, CuentaBancaria b) {
                  if (a.activa == b.activa) {
                    return 0;
                  }
                  return a.activa ? -1 : 1;
                },
                cellBuilder: (CuentaBancaria cuenta) => _estadoSwitch(cuenta),
              ),
            ],
            onRefresh: _reload,
            searchTextBuilder: (CuentaBancaria c) =>
                '${c.nombre} ${c.banco ?? ''}',
            searchPlaceholder: 'Buscar cuenta',
            filters: <TableFilterConfig<CuentaBancaria>>[
              TableFilterConfig<CuentaBancaria>(
                label: 'Estado',
                options: <TableFilterOption<CuentaBancaria>>[
                  const TableFilterOption<CuentaBancaria>(
                    label: 'Todas',
                    isDefault: true,
                  ),
                  TableFilterOption<CuentaBancaria>(
                    label: 'Activas',
                    predicate: (CuentaBancaria c) => c.activa,
                  ),
                  TableFilterOption<CuentaBancaria>(
                    label: 'Inactivas',
                    predicate: (CuentaBancaria c) => !c.activa,
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNuevaCuenta,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openNuevaCuenta() async {
    final bool? created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const CuentasFormView(),
      ),
    );
    if (created == true) {
      _reload();
    }
  }

  Widget _estadoSwitch(CuentaBancaria cuenta) {
    final bool isUpdating = _updating.contains(cuenta.id);
    if (isUpdating) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Switch.adaptive(
      value: cuenta.activa,
      onChanged: (bool value) => _toggleEstado(cuenta, value),
    );
  }
}

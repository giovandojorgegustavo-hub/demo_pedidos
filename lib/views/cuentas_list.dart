import 'package:flutter/material.dart';

import '../models/cuenta_bancaria.dart';
import '../widgets/app_drawer.dart';
import 'cuentas_form.dart';

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
    return Scaffold(
      drawer: const AppDrawer(current: AppSection.bancos),
      appBar: AppBar(
        title: const Text('Cuentas bancarias'),
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<CuentaBancaria>>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<List<CuentaBancaria>> snapshot) {
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

          final List<CuentaBancaria> cuentas = snapshot.data ?? <CuentaBancaria>[];
          if (cuentas.isEmpty) {
            return Center(
              child: Padding(
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
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: cuentas.length,
              itemBuilder: (BuildContext context, int index) {
                final CuentaBancaria cuenta = cuentas[index];
                final bool isUpdating = _updating.contains(cuenta.id);
                return SwitchListTile(
                  title: Text(cuenta.nombre),
                  subtitle: Text(cuenta.banco ?? 'Sin banco'),
                  value: cuenta.activa,
                  onChanged: isUpdating
                      ? null
                      : (bool value) => _toggleEstado(cuenta, value),
                  secondary: const Icon(Icons.account_balance_wallet_outlined),
                );
              },
            ),
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
}

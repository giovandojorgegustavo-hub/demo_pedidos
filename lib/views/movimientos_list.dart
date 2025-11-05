import 'package:flutter/material.dart';

import '../models/movimiento_estado.dart';
import '../widgets/app_drawer.dart';
import 'pedidos_detalle.dart';

class MovimientosListView extends StatefulWidget {
  const MovimientosListView({super.key});

  @override
  State<MovimientosListView> createState() => _MovimientosListViewState();
}

class _MovimientosListViewState extends State<MovimientosListView> {
  late Future<List<MovimientoEstado>> _future;

  @override
  void initState() {
    super.initState();
    _future = MovimientoEstado.fetchAll();
  }

  Future<void> _reload() async {
    setState(() {
      _future = MovimientoEstado.fetchAll();
    });
    await _future;
  }

  String _statusLabel(MovimientoEstado estado) {
    return estado.estadoTexto.isEmpty
        ? 'Sin estado'
        : estado.estadoTexto[0].toUpperCase() + estado.estadoTexto.substring(1);
  }

  IconData _statusIcon(MovimientoEstado estado) {
    switch (estado.estadoCodigo) {
      case 1:
        return Icons.edit_note_outlined; // borrador
      case 2:
        return Icons.inventory_2_outlined; // preparado
      case 3:
        return Icons.delivery_dining_outlined; // asignado
      case 4:
        return Icons.check_circle_outline; // llegado
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(current: AppSection.movimientos),
      appBar: AppBar(
        title: const Text('Movimientos logísticos'),
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<MovimientoEstado>>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<List<MovimientoEstado>> snapshot) {
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
                    const Text('No se pudo cargar la lista de movimientos.'),
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

          final List<MovimientoEstado> movimientos =
              snapshot.data ?? <MovimientoEstado>[];
          if (movimientos.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No hay movimientos registrados.'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: movimientos.length,
              itemBuilder: (BuildContext context, int index) {
                final MovimientoEstado movimiento = movimientos[index];
                final IconData icon = _statusIcon(movimiento);
                return ListTile(
                  leading: Icon(icon),
                  title: Text('Movimiento ${movimiento.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Pedido: ${movimiento.idpedido}'),
                      Text('Estado: ${_statusLabel(movimiento)}'),
                      if (movimiento.asignadoAt != null)
                        Text(
                          'Asignado: ${_formatDateTime(movimiento.asignadoAt!)}',
                        ),
                      if (movimiento.llegadaAt != null)
                        Text(
                          'Llegada: ${_formatDateTime(movimiento.llegadaAt!)}',
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PedidosDetalleView(
                          pedidoId: movimiento.idpedido,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

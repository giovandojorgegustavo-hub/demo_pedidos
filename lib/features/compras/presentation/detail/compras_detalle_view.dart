import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/compra.dart';
import 'package:demo_pedidos/models/compra_detalle.dart';
import 'package:demo_pedidos/models/compra_pago.dart';
import 'package:demo_pedidos/models/compra_gasto.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

import '../form/compras_form_view.dart';

class ComprasDetalleView extends StatefulWidget {
  const ComprasDetalleView({super.key, required this.compraId});

  final String compraId;

  @override
  State<ComprasDetalleView> createState() => _ComprasDetalleViewState();
}

class _ComprasDetalleViewState extends State<ComprasDetalleView> {
  Compra? _compra;
  List<CompraDetalle> _detalles = <CompraDetalle>[];
  List<CompraPago> _pagos = <CompraPago>[];
  List<CompraGasto> _gastos = <CompraGasto>[];
  bool _loading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
    });
    try {
      final Compra? compra = await Compra.getById(widget.compraId);
      final List<CompraDetalle> detalles =
          await CompraDetalle.fetchByCompra(widget.compraId);
      final List<CompraPago> pagos =
          await CompraPago.fetchByCompra(widget.compraId);
      final List<CompraGasto> gastos =
          await CompraGasto.fetchByCompra(widget.compraId);
      if (!mounted) {
        return;
      }
      setState(() {
        _compra = compra;
        _detalles = detalles;
        _pagos = pagos;
        _gastos = gastos;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar la compra: $error')),
      );
    }
  }

  String _formatCurrency(double? value) {
    final double number = value ?? 0;
    return 'S/ ${number.toStringAsFixed(2)}';
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'parcial':
        return Colors.blue;
      case 'cancelada':
      case 'completo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _statusChip(String label, String? status) {
    final Color color = _statusColor(status);
    return Chip(
      label: Text(label),
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 6,
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color),
    );
  }

  Future<void> _openEdit() async {
    final Compra? compra = _compra;
    if (compra == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ComprasFormView(compra: compra),
      ),
    );
    if (changed == true) {
      setState(() {
        _hasChanges = true;
      });
      await _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Compra? compra = _compra;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        Navigator.pop(context, _hasChanges);
      },
      child: PageScaffold(
        title: 'Detalle de compra',
        currentSection: AppSection.operacionesCompras,
        actions: <Widget>[
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : compra == null
                ? const Center(
                    child: Text('La compra no existe o fue eliminada.'),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        _buildHeader(compra),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Detalle de compra',
                          child: _buildDetalleTable(),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Pagos',
                          child: _buildPagosTable(),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Gastos',
                          child: _buildGastosTable(),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader(Compra compra) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              compra.proveedorNombre ?? 'Proveedor sin nombre',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(compra.proveedorNumero ?? '-',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text('Base: ${compra.baseNombre ?? '-'}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _statusChip(
                  'Pago: ${compra.estadoPago ?? '-'}',
                  compra.estadoPago,
                ),
                _statusChip(
                  'Entrega: ${compra.estadoEntrega ?? '-'}',
                  compra.estadoEntrega,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Total: ${_formatCurrency(compra.totalDetalle)}'),
                Text('Pagado: ${_formatCurrency(compra.totalPagado)}'),
                Text('Saldo: ${_formatCurrency(compra.saldo)}'),
              ],
            ),
            if ((compra.observacion?.trim().isNotEmpty ?? false)) ...<Widget>[
              const SizedBox(height: 12),
              Text('Observación: ${compra.observacion}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleTable() {
    return TableSection<CompraDetalle>(
      items: _detalles,
      columns: <TableColumnConfig<CompraDetalle>>[
        TableColumnConfig<CompraDetalle>(
          label: 'Producto',
          sortAccessor: (CompraDetalle d) => d.productoNombre ?? '',
          cellBuilder: (CompraDetalle d) => Text(d.productoNombre ?? '-'),
        ),
        TableColumnConfig<CompraDetalle>(
          label: 'Cantidad',
          isNumeric: true,
          sortAccessor: (CompraDetalle d) => d.cantidad,
          cellBuilder: (CompraDetalle d) =>
              Text(d.cantidad.toStringAsFixed(2)),
        ),
        TableColumnConfig<CompraDetalle>(
          label: 'Costo total',
          isNumeric: true,
          sortAccessor: (CompraDetalle d) => d.costoTotal,
          cellBuilder: (CompraDetalle d) =>
              Text(_formatCurrency(d.costoTotal)),
        ),
      ],
      emptyMessage: 'No se registraron productos en esta compra.',
      shrinkWrap: true,
    );
  }

  Widget _buildPagosTable() {
    return TableSection<CompraPago>(
      items: _pagos,
      columns: <TableColumnConfig<CompraPago>>[
        TableColumnConfig<CompraPago>(
          label: 'Cuenta',
          sortAccessor: (CompraPago p) => p.cuentaNombre ?? '',
          cellBuilder: (CompraPago p) => Text(p.cuentaNombre ?? '-'),
        ),
        TableColumnConfig<CompraPago>(
          label: 'Monto',
          isNumeric: true,
          sortAccessor: (CompraPago p) => p.monto,
          cellBuilder: (CompraPago p) => Text(_formatCurrency(p.monto)),
        ),
      ],
      emptyMessage: 'Sin pagos registrados.',
      shrinkWrap: true,
    );
  }

  Widget _buildGastosTable() {
    return TableSection<CompraGasto>(
      items: _gastos,
      columns: <TableColumnConfig<CompraGasto>>[
        TableColumnConfig<CompraGasto>(
          label: 'Cuenta contable',
          sortAccessor: (CompraGasto g) => g.cuentaContable ?? '',
          cellBuilder: (CompraGasto g) => Text(g.cuentaContable ?? '-'),
        ),
        TableColumnConfig<CompraGasto>(
          label: 'Monto',
          isNumeric: true,
          sortAccessor: (CompraGasto g) => g.monto,
          cellBuilder: (CompraGasto g) => Text(_formatCurrency(g.monto)),
        ),
        TableColumnConfig<CompraGasto>(
          label: 'Observación',
          sortAccessor: (CompraGasto g) => g.observacion ?? '',
          cellBuilder: (CompraGasto g) => Text(g.observacion ?? '-'),
        ),
      ],
      emptyMessage: 'Sin gastos asociados.',
      shrinkWrap: true,
    );
  }
}

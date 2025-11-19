import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/clientes/presentation/form/clientes_form_view.dart';
import 'package:demo_pedidos/models/cliente.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';

class ClientesDetailView extends StatefulWidget {
  const ClientesDetailView({
    super.key,
    required this.clienteId,
  });

  final String clienteId;

  @override
  State<ClientesDetailView> createState() => _ClientesDetailViewState();
}

class _ClientesDetailViewState extends State<ClientesDetailView> {
  late Future<void> _future = _load();
  Cliente? _cliente;
  bool _hasChanges = false;

  Future<void> _load() async {
    final Cliente? cliente = await Cliente.getById(widget.clienteId);
    if (!mounted) {
      return;
    }
    setState(() {
      _cliente = cliente;
    });
  }

  Future<void> _reload() {
    final Future<void> future = _load();
    setState(() {
      _future = future;
    });
    return future;
  }

  Future<void> _edit() async {
    final Cliente? cliente = _cliente;
    if (cliente == null) {
      return;
    }
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => ClientesFormView(cliente: cliente),
      ),
    );
    if (result != null) {
      _hasChanges = true;
      await _reload();
    }
  }

  void _handlePop() {
    Navigator.pop(context, _hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _handlePop();
      },
      child: PageScaffold(
        title: 'Detalle cliente',
        currentSection: AppSection.clientes,
        includeDrawer: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handlePop,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: _cliente == null ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        ],
        floatingActionButton: _cliente == null
            ? null
            : FloatingActionButton(
                onPressed: _edit,
                tooltip: 'Editar cliente',
                child: const Icon(Icons.edit),
              ),
        body: FutureBuilder<void>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorPane(message: '${snapshot.error}', onRetry: _reload);
            }
            final Cliente? cliente = _cliente;
            if (cliente == null) {
              return _ErrorPane(
                message: 'No encontramos este cliente.',
                onRetry: _handlePop,
                actionLabel: 'Volver',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          cliente.nombre,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Número de contacto',
                          value: cliente.numero.isEmpty
                              ? 'Sin número'
                              : cliente.numero,
                        ),
                        _InfoRow(
                          label: 'Canal',
                          value: cliente.canal,
                        ),
                        _InfoRow(
                          label: 'Referido por',
                          value: cliente.referidoPor ?? '-',
                        ),
                        _InfoRow(
                          label: 'Registrado',
                          value: _formatDate(cliente.registradoAt),
                        ),
                        _InfoRow(
                          label: 'Editado',
                          value: _formatDate(cliente.editadoAt),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({
    required this.message,
    required this.onRetry,
    this.actionLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(actionLabel ?? 'Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

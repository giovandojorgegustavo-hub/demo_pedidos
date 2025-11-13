import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/cliente.dart';
import 'package:demo_pedidos/models/incidente.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';

class ComunicacionesIncidenteFormView extends StatefulWidget {
  const ComunicacionesIncidenteFormView({super.key, this.incidente});

  final Incidente? incidente;

  @override
  State<ComunicacionesIncidenteFormView> createState() =>
      _ComunicacionesIncidenteFormViewState();
}

class _ComunicacionesIncidenteFormViewState
    extends State<ComunicacionesIncidenteFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _categoriaCtrl;
  late final TextEditingController _pedidoCtrl;
  late final TextEditingController _movimientoCtrl;
  String _severidad = 'media';
  String _estado = 'abierto';
  String? _responsabilidad;
  String? _baseId;
  String? _clienteId;
  bool _isSaving = false;
  bool _isLoadingCatalogos = true;
  List<LogisticaBase> _bases = <LogisticaBase>[];
  List<Cliente> _clientes = <Cliente>[];

  @override
  void initState() {
    super.initState();
    final Incidente? incidente = widget.incidente;
    _tituloCtrl = TextEditingController(text: incidente?.titulo ?? '');
    _descripcionCtrl =
        TextEditingController(text: incidente?.descripcion ?? '');
    _categoriaCtrl = TextEditingController(text: incidente?.categoria ?? '');
    _pedidoCtrl = TextEditingController(text: incidente?.idPedido ?? '');
    _movimientoCtrl =
        TextEditingController(text: incidente?.idMovimiento ?? '');
    _severidad = incidente?.severidad ?? 'media';
    _estado = incidente?.estado ?? 'abierto';
    _responsabilidad = incidente?.responsabilidad;
    _baseId = incidente?.idBase;
    _clienteId = incidente?.idCliente;
    _loadCatalogos();
  }

  Future<void> _loadCatalogos() async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      LogisticaBase.getBases(),
      Cliente.getClientes(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _bases = results[0] as List<LogisticaBase>;
      _clientes = results[1] as List<Cliente>;
      _isLoadingCatalogos = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final Map<String, dynamic> payload = <String, dynamic>{
      'titulo': _tituloCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'categoria': _categoriaCtrl.text.trim().isEmpty
          ? null
          : _categoriaCtrl.text.trim(),
      'severidad': _severidad,
      'estado': _estado,
      'responsabilidad': _responsabilidad,
      'idbase': _baseId,
      'idcliente': _clienteId,
      'idpedido': _pedidoCtrl.text.trim().isEmpty
          ? null
          : _pedidoCtrl.text.trim(),
      'idmovimiento': _movimientoCtrl.text.trim().isEmpty
          ? null
          : _movimientoCtrl.text.trim(),
    }..removeWhere((String key, dynamic value) => value == null);

    try {
      if (widget.incidente == null) {
        await Incidente.create(payload);
      } else {
        await Incidente.update(widget.incidente!.id, payload);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: widget.incidente == null
          ? 'Nueva incidencia'
          : 'Editar incidencia',
      currentSection: AppSection.comunicacionesIncidentes,
      body: _isLoadingCatalogos
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _tituloCtrl,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Descripción'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoriaCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Categoría'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _severidad,
                      decoration: const InputDecoration(labelText: 'Severidad'),
                      items: kIncidenteSeveridades
                          .map(
                            (String item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _severidad = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _estado,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: kIncidenteEstados
                          .map(
                            (String item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _estado = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _responsabilidad,
                      decoration:
                          const InputDecoration(labelText: 'Responsable'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No definido'),
                        ),
                        ...kIncidenteResponsables.map(
                          (String item) => DropdownMenuItem<String?>(
                            value: item,
                            child: Text(item),
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() => _responsabilidad = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _baseId,
                      decoration: const InputDecoration(labelText: 'Base'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin base'),
                        ),
                        ..._bases.map(
                          (LogisticaBase base) => DropdownMenuItem<String?>(
                            value: base.id,
                            child: Text(base.nombre),
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() => _baseId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _clienteId,
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin cliente'),
                        ),
                        ..._clientes.map(
                          (Cliente cliente) => DropdownMenuItem<String?>(
                            value: cliente.id,
                            child: Text(cliente.nombre),
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() => _clienteId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pedidoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID Pedido (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _movimientoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID Movimiento (opcional)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          widget.incidente == null
                              ? 'Crear incidencia'
                              : 'Guardar cambios',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

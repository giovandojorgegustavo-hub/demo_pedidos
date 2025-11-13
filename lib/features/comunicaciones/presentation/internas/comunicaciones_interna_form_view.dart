import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/comunicacion_interna.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';

class ComunicacionesInternaFormView extends StatefulWidget {
  const ComunicacionesInternaFormView({super.key, this.comunicacion});

  final ComunicacionInterna? comunicacion;

  @override
  State<ComunicacionesInternaFormView> createState() =>
      _ComunicacionesInternaFormViewState();
}

class _ComunicacionesInternaFormViewState
    extends State<ComunicacionesInternaFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _asuntoCtrl;
  late final TextEditingController _mensajeCtrl;
  String _prioridad = 'media';
  String _estado = 'pendiente';
  String? _baseId;
  bool _isSaving = false;
  bool _isLoadingCatalogos = true;
  List<LogisticaBase> _bases = <LogisticaBase>[];

  @override
  void initState() {
    super.initState();
    final ComunicacionInterna? comunicacion = widget.comunicacion;
    _asuntoCtrl = TextEditingController(text: comunicacion?.asunto ?? '');
    _mensajeCtrl = TextEditingController(text: comunicacion?.mensaje ?? '');
    _prioridad = comunicacion?.prioridad ?? 'media';
    _estado = comunicacion?.estado ?? 'pendiente';
    _baseId = comunicacion?.idBase;
    _loadBases();
  }

  @override
  void dispose() {
    _asuntoCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBases() async {
    final List<LogisticaBase> bases = await LogisticaBase.getBases();
    if (!mounted) {
      return;
    }
    setState(() {
      _bases = bases;
      _isLoadingCatalogos = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final Map<String, dynamic> payload = <String, dynamic>{
      'idbase': _baseId,
      'asunto': _asuntoCtrl.text.trim(),
      'mensaje': _mensajeCtrl.text.trim(),
      'prioridad': _prioridad,
      'estado': _estado,
    }..removeWhere((String key, dynamic value) => value == null);

    try {
      if (widget.comunicacion == null) {
        await ComunicacionInterna.create(payload);
      } else {
        await ComunicacionInterna.update(widget.comunicacion!.id, payload);
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
      title: widget.comunicacion == null
          ? 'Nueva comunicación'
          : 'Editar comunicación',
      currentSection: AppSection.comunicacionesInternas,
      body: _isLoadingCatalogos
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _asuntoCtrl,
                      decoration: const InputDecoration(labelText: 'Asunto'),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un asunto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _baseId,
                      decoration:
                          const InputDecoration(labelText: 'Base (opcional)'),
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
                    TextFormField(
                      controller: _mensajeCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Descripción'),
                      maxLines: 5,
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _prioridad,
                      decoration:
                          const InputDecoration(labelText: 'Prioridad'),
                      items: kComunicacionPrioridades
                          .map(
                            (String item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _prioridad = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _estado,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: kComunicacionEstados
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          widget.comunicacion == null
                              ? 'Registrar comunicación'
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

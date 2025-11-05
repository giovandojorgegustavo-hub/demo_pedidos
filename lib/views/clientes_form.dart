import 'package:flutter/material.dart';

import '../models/cliente.dart';

class ClientesFormView extends StatefulWidget {
  const ClientesFormView({super.key});

  @override
  State<ClientesFormView> createState() => _ClientesFormViewState();
}

class _ClientesFormViewState extends State<ClientesFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingReferentes = false;
  final List<String> _canales = <String>['telegram', 'referido'];
  String _canal = 'telegram';
  List<Cliente> _clientes = <Cliente>[];
  String? _referidoPorId;

  @override
  void initState() {
    super.initState();
    _loadReferentes();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _loadReferentes() async {
    setState(() {
      _isLoadingReferentes = true;
    });
    try {
      final List<Cliente> clientes = await Cliente.getClientes();
      if (!mounted) {
        return;
      }
      setState(() {
        _clientes = clientes;
        _isLoadingReferentes = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingReferentes = false;
      });
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final Cliente payload = Cliente(
      id: '',
      nombre: _nombreController.text.trim(),
      numero: _numeroController.text.trim(),
      canal: _canal,
      referidoPor: _canal == 'referido' ? _referidoPorId : null,
    );

    try {
      final String id = await Cliente.insert(payload);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el cliente: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _canal,
                decoration: const InputDecoration(
                  labelText: 'Canal de origen',
                  border: OutlineInputBorder(),
                ),
                items: _canales
                    .map(
                      (String canal) => DropdownMenuItem<String>(
                        value: canal,
                        child: Text(canal),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _canal = value;
                    if (_canal != 'referido') {
                      _referidoPorId = null;
                    }
                  });
                },
              ),
              if (_canal == 'referido') ...<Widget>[
                const SizedBox(height: 16),
                if (_isLoadingReferentes)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String?>(
                    value: _referidoPorId,
                    decoration: const InputDecoration(
                      labelText: 'Cliente que refirió (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin referente'),
                      ),
                      ..._clientes.map(
                        (Cliente cliente) => DropdownMenuItem<String?>(
                          value: cliente.id,
                          child: Text(cliente.nombre),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _referidoPorId = value;
                      });
                    },
                  ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número de contacto',
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

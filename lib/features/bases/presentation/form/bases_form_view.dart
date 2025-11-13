import 'package:demo_pedidos/features/bases/presentation/form/base_packing_draft.dart';
import 'package:demo_pedidos/features/bases/presentation/form/base_packing_form_view.dart';
import 'package:demo_pedidos/models/base_packing.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:demo_pedidos/ui/form/inline_form_table.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:flutter/material.dart';

class BasesFormView extends StatefulWidget {
  const BasesFormView({super.key, this.base});

  final LogisticaBase? base;

  @override
  State<BasesFormView> createState() => _BasesFormViewState();
}

class _BasesFormViewState extends State<BasesFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingPackings = false;
  List<BasePackingDraft> _packings = <BasePackingDraft>[];
  List<BasePackingDraft> _originalPackings = <BasePackingDraft>[];
  bool get _isEditing => widget.base != null;

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.base?.nombre ?? '';
    if (_isEditing) {
      _loadPackings();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadPackings() async {
    final LogisticaBase? base = widget.base;
    if (base == null) {
      return;
    }
    setState(() {
      _isLoadingPackings = true;
    });
    try {
      final List<BasePacking> rows = await BasePacking.fetchByBase(base.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _packings = rows
            .map(
              (BasePacking item) => BasePackingDraft(
                id: item.id,
                nombre: item.nombre,
                activo: item.activo,
              ),
            )
            .toList();
        _originalPackings = _packings.map((_) => _.copy()).toList();
        _isLoadingPackings = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPackings = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los packing: $error')),
      );
    }
  }

  void _removePacking(BasePackingDraft item) {
    setState(() {
      _packings.remove(item);
    });
  }

  Future<void> _openPackingForm({BasePackingDraft? draft}) async {
    final BasePackingDraft? result = await Navigator.push<BasePackingDraft>(
      context,
      MaterialPageRoute<BasePackingDraft>(
        builder: (_) => BasePackingFormView(
          existing: _packings,
          draft: draft,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result == null) {
      return;
    }
    setState(() {
      if (draft == null) {
        _packings.add(result);
      } else {
        final int index = _packings.indexOf(draft);
        if (index >= 0) {
          _packings[index] = result;
        }
      }
    });
  }

  Future<void> _syncPackings(String baseId) async {
    final Set<String> originalIds = _originalPackings
        .where((BasePackingDraft item) => item.id != null)
        .map((BasePackingDraft item) => item.id!)
        .toSet();
    final Set<String> currentIds = _packings
        .where((BasePackingDraft item) => item.id != null)
        .map((BasePackingDraft item) => item.id!)
        .toSet();

    final List<String> toDelete = originalIds.difference(currentIds).toList();
    for (final String id in toDelete) {
      await BasePacking.delete(id);
    }

    final Map<String, BasePackingDraft> originalById =
        <String, BasePackingDraft>{
      for (final BasePackingDraft item in _originalPackings)
        if (item.id != null) item.id!: item
    };

    for (final BasePackingDraft draft in _packings) {
      if (draft.id == null) {
        final String newId = await BasePacking.create(
          baseId: baseId,
          nombre: draft.nombre,
          activo: draft.activo,
        );
        draft.id = newId;
      } else {
        final BasePackingDraft? original = originalById[draft.id!];
        if (original == null ||
            original.nombre != draft.nombre ||
            original.activo != draft.activo) {
          await BasePacking.update(
            id: draft.id!,
            nombre: draft.nombre,
            activo: draft.activo,
          );
        }
      }
    }

    _originalPackings = _packings.map((_) => _.copy()).toList();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final LogisticaBase base = LogisticaBase(
      id: widget.base?.id ?? '',
      nombre: _nombreController.text.trim(),
    );

    try {
      String baseId;
      if (_isEditing) {
        await LogisticaBase.update(base);
        baseId = base.id;
      } else {
        baseId = await LogisticaBase.insert(base);
      }
      await _syncPackings(baseId);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, baseId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la base: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: _isEditing ? 'Editar base' : 'Nueva base',
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      onSave: _onSave,
      isSaving: _isSaving,
      contentPadding: EdgeInsets.zero,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la base',
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
            Text(
              'Packings disponibles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_isLoadingPackings) ...<Widget>[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 12),
            InlineFormTable<BasePackingDraft>(
              title: 'Packings',
              items: _packings,
              columns: _packingColumns(),
              minTableWidth: 480,
              emptyMessage: 'Sin packings registrados.',
              helperText:
                  'Define las opciones de packing y desactiva las que ya no se usan.',
              onAdd: (_isSaving || _isLoadingPackings)
                  ? null
                  : () => _openPackingForm(),
            ),
          ],
        ),
      ),
    );
  }

  List<TableColumnConfig<BasePackingDraft>> _packingColumns() {
    return <TableColumnConfig<BasePackingDraft>>[
      TableColumnConfig<BasePackingDraft>(
        label: 'Nombre',
        cellBuilder: (BasePackingDraft item) => Text(item.nombre),
      ),
      TableColumnConfig<BasePackingDraft>(
        label: 'Activo',
        cellBuilder: (BasePackingDraft item) => Switch.adaptive(
          value: item.activo,
          onChanged: _isSaving
              ? null
              : (bool value) {
                  setState(() {
                    item.activo = value;
                  });
                },
        ),
      ),
      TableColumnConfig<BasePackingDraft>(
        label: 'Acciones',
        cellBuilder: (BasePackingDraft item) => Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            children: <Widget>[
              TextButton(
                onPressed:
                    _isSaving ? null : () => _openPackingForm(draft: item),
                child: const Text('Editar'),
              ),
              TextButton(
                onPressed: _isSaving ? null : () => _removePacking(item),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

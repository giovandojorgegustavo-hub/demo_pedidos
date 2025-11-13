import 'package:demo_pedidos/features/productos/presentation/form/categoria_form_view.dart';
import 'package:demo_pedidos/models/categoria.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';

class ProductosFormView extends StatefulWidget {
  const ProductosFormView({super.key});

  @override
  State<ProductosFormView> createState() => _ProductosFormViewState();
}

class _ProductosFormViewState extends State<ProductosFormView> {
  static const String _newCategoryValue = '__new_category__';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingCategorias = false;
  List<Categoria> _categorias = <Categoria>[];
  String? _categoriaId;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias({String? selectId}) async {
    setState(() {
      _isLoadingCategorias = true;
    });
    try {
      final List<Categoria> categorias = await Categoria.getCategorias();
      if (!mounted) {
        return;
      }
      setState(() {
        _categorias = categorias;
        if (selectId != null) {
          _categoriaId = selectId;
        } else if (_categorias
            .every((Categoria categoria) => categoria.id != _categoriaId)) {
          _categoriaId = null;
        }
        _isLoadingCategorias = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCategorias = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar las categorías: $error')),
      );
    }
  }

  Future<void> _crearCategoria() async {
    final String? newCategoryId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const CategoriaFormView(),
        fullscreenDialog: true,
      ),
    );
    if (newCategoryId == null) {
      return;
    }
    await _loadCategorias(selectId: newCategoryId);
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la categoría')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final Producto producto = Producto(
      id: '',
      nombre: _nombreController.text.trim(),
      categoriaId: _categoriaId,
      categoriaNombre: _categorias
          .firstWhere((Categoria item) => item.id == _categoriaId)
          .nombre,
    );

    try {
      final String id = await Producto.insert(producto);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el producto: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: 'Nuevo producto',
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
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre del producto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildCategoriaSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaSelector() {
    if (_isLoadingCategorias) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_categorias.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Aún no registras categorías. Crea una antes de guardar.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(_categoriaId),
      initialValue: _categoriaId,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<String>>[
        ..._categorias.map(
          (Categoria categoria) => DropdownMenuItem<String>(
            value: categoria.id,
            child: Text(categoria.nombre),
          ),
        ),
        const DropdownMenuItem<String>(
          value: _newCategoryValue,
          child: Text('➕ Nueva categoría'),
        ),
      ],
      onChanged: _isSaving
          ? null
          : (String? value) {
              if (value == _newCategoryValue) {
                _crearCategoria();
                return;
              }
              setState(() {
                _categoriaId = value;
              });
            },
      validator: (String? value) {
        if (_categorias.isEmpty) {
          return 'Crea una categoría primero';
        }
        if (value == null || value.isEmpty) {
          return 'Selecciona una categoría';
        }
        return null;
      },
    );
  }
}

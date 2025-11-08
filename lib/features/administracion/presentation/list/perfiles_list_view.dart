import 'package:demo_pedidos/features/administracion/presentation/form/perfiles_form_view.dart';
import 'package:demo_pedidos/models/perfil.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/entity_table_page.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

class PerfilesListView extends StatelessWidget {
  const PerfilesListView({super.key});

  Future<bool?> _openForm(BuildContext context, Perfil perfil) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PerfilesFormView(perfil: perfil),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EntityTablePage<Perfil>(
      title: 'Usuarios y roles',
      includeDrawer: true,
      currentSection: AppSection.usuarios,
      loadItems: Perfil.fetchAll,
      columns: _columns,
      searchTextBuilder: (Perfil perfil) =>
          '${perfil.nombre ?? ''} ${perfil.rol} ${perfil.userId}',
      searchPlaceholder: 'Buscar por nombre, rol o ID',
      emptyMessage: 'Sin usuarios visibles.',
      minTableWidth: 720,
      onRowTap: (BuildContext context, Perfil perfil) async {
        final bool? result = await _openForm(context, perfil);
        return result ?? false;
      },
    );
  }

  List<TableColumnConfig<Perfil>> get _columns {
    return <TableColumnConfig<Perfil>>[
      TableColumnConfig<Perfil>(
        label: 'Nombre',
        sortAccessor: (Perfil perfil) => perfil.nombre ?? '',
        cellBuilder: (Perfil perfil) => Text(
          (perfil.nombre ?? '').isEmpty ? '(sin nombre)' : perfil.nombre!,
        ),
      ),
      TableColumnConfig<Perfil>(
        label: 'Rol',
        sortAccessor: (Perfil perfil) => perfil.rol,
        cellBuilder: (Perfil perfil) => Chip(
          label: Text(
            perfil.rol[0].toUpperCase() + perfil.rol.substring(1),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
      TableColumnConfig<Perfil>(
        label: 'Activo',
        sortAccessor: (Perfil perfil) => perfil.activo ? 1 : 0,
        cellBuilder: (Perfil perfil) => Icon(
          perfil.activo ? Icons.check_circle : Icons.remove_circle_outline,
          color: perfil.activo ? Colors.green : Colors.redAccent,
        ),
      ),
      TableColumnConfig<Perfil>(
        label: 'Registrado',
        sortAccessor: (Perfil perfil) => perfil.registradoAt ?? DateTime(2000),
        cellBuilder: (Perfil perfil) =>
            Text(_formatDate(perfil.registradoAt)),
      ),
      TableColumnConfig<Perfil>(
        label: 'ID',
        sortAccessor: (Perfil perfil) => perfil.userId,
        cellBuilder: (Perfil perfil) => Text(
          perfil.userId,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    ];
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String y = date.year.toString().padLeft(4, '0');
    final String h = date.hour.toString().padLeft(2, '0');
    final String min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}

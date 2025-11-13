import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/asistencias/presentation/slots/asistencias_slot_form_view.dart';
import 'package:demo_pedidos/models/asistencia_slot.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class AsistenciasSlotsListView extends StatefulWidget {
  const AsistenciasSlotsListView({super.key});

  @override
  State<AsistenciasSlotsListView> createState() =>
      _AsistenciasSlotsListViewState();
}

class _AsistenciasSlotsListViewState
    extends State<AsistenciasSlotsListView> {
  late Future<List<AsistenciaSlot>> _future = AsistenciaSlot.fetchAll();

  Future<void> _reload() async {
    setState(() {
      _future = AsistenciaSlot.fetchAll();
    });
    await _future;
  }

  Future<void> _openForm({AsistenciaSlot? slot}) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AsistenciasSlotFormView(slot: slot),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Slots de asistencia',
      currentSection: AppSection.asistenciasSlots,
      actions: <Widget>[
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<AsistenciaSlot>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<AsistenciaSlot>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No se pudieron cargar los slots.'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final List<AsistenciaSlot> data =
              snapshot.data ?? <AsistenciaSlot>[];
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Aún no registras slots de asistencia.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openForm(),
                    child: const Text('Crear slot'),
                  ),
                ],
              ),
            );
          }
          return TableSection<AsistenciaSlot>(
            items: data,
            columns: _columns,
            minTableWidth: 700,
            searchPlaceholder: 'Buscar por nombre u hora',
            searchTextBuilder: (AsistenciaSlot slot) =>
                '${slot.nombre} ${slot.hora}',
            onRowTap: (AsistenciaSlot slot) => _openForm(slot: slot),
          );
        },
      ),
    );
  }

  List<TableColumnConfig<AsistenciaSlot>> get _columns {
    return <TableColumnConfig<AsistenciaSlot>>[
      TableColumnConfig<AsistenciaSlot>(
        label: 'Nombre',
        sortAccessor: (AsistenciaSlot slot) => slot.nombre,
        cellBuilder: (AsistenciaSlot slot) => Text(slot.nombre),
      ),
      TableColumnConfig<AsistenciaSlot>(
        label: 'Hora',
        sortAccessor: (AsistenciaSlot slot) => slot.hora,
        cellBuilder: (AsistenciaSlot slot) => Text(slot.hora.substring(0, 5)),
      ),
      TableColumnConfig<AsistenciaSlot>(
        label: 'Descripción',
        sortAccessor: (AsistenciaSlot slot) => slot.descripcion ?? '',
        cellBuilder: (AsistenciaSlot slot) =>
            Text(slot.descripcion ?? '-', maxLines: 2),
      ),
      TableColumnConfig<AsistenciaSlot>(
        label: 'Estado',
        sortAccessor: (AsistenciaSlot slot) => slot.activo ? '1' : '0',
        cellBuilder: (AsistenciaSlot slot) => Chip(
          label: Text(slot.activo ? 'Activo' : 'Inactivo'),
          backgroundColor:
              slot.activo ? Colors.green.shade100 : Colors.grey.shade300,
        ),
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/features/administracion/presentation/list/perfiles_list_view.dart';
import 'package:demo_pedidos/features/bases/presentation/list/bases_list_view.dart';
import 'package:demo_pedidos/features/cuentas/presentation/list/cuentas_list_view.dart';
import 'package:demo_pedidos/features/clientes/presentation/list/clientes_list_view.dart';
import 'package:demo_pedidos/features/compras/presentation/list/compras_list_view.dart';
import 'package:demo_pedidos/features/home/presentation/modules_dashboard_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/list/movimientos_list_view.dart';
import 'package:demo_pedidos/features/proveedores/presentation/list/proveedores_list_view.dart';
import 'package:demo_pedidos/features/pedidos/presentation/list/pedidos_list_view.dart';
import 'package:demo_pedidos/features/productos/presentation/list/productos_list_view.dart';
import 'package:demo_pedidos/features/viajes/presentation/list/viaje_detalles_list_view.dart';
import 'package:demo_pedidos/features/viajes/presentation/list/viajes_list_view.dart';
import 'package:demo_pedidos/features/operaciones/presentation/operaciones_dashboard_view.dart';
import 'package:demo_pedidos/features/operaciones/presentation/operaciones_placeholder_view.dart';
import 'package:demo_pedidos/services/module_access_service.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/shared/module_definitions.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.current,
  });

  final AppSection current;

  void _navigate(BuildContext context, AppSection target) {
    if (target == current) {
      Navigator.pop(context);
      return;
    }

    Widget builder() {
      switch (target) {
        case AppSection.pedidos:
          return const PedidosListView();
        case AppSection.movimientos:
          return const MovimientosListView();
        case AppSection.viajes:
          return const ViajesListView();
        case AppSection.viajesDetalle:
          return const ViajeDetallesListView();
        case AppSection.operacionesStock:
        case AppSection.operacionesHistorial:
          return OperacionesDashboardView(initialSection: target);
        case AppSection.operacionesCompras:
          return const ComprasListView();
        case AppSection.operacionesTransferencias:
          return const OperacionesTransferenciasView();
        case AppSection.operacionesFabricacion:
          return const OperacionesFabricacionView();
        case AppSection.operacionesAjustes:
          return const OperacionesAjustesView();
        case AppSection.proveedores:
          return const ProveedoresListView();
        case AppSection.operacionesBases:
          return const BasesListView(currentSection: AppSection.operacionesBases);
        case AppSection.operacionesProductos:
          return const ProductosListView(
            currentSection: AppSection.operacionesProductos,
          );
        case AppSection.productos:
          return const ProductosListView();
        case AppSection.clientes:
          return const ClientesListView();
        case AppSection.bases:
          return const BasesListView();
        case AppSection.bancos:
          return const CuentasListView();
        case AppSection.usuarios:
          return const PerfilesListView();
      }
    }

    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => builder()),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pop();
  }

  void _goToModules(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const ModulesDashboardView()),
    );
  }

  bool _canSeeSection(Set<String> modules, AppSection section) {
    final String? moduleId = kSectionModuleMap[section];
    if (moduleId == null) {
      return true;
    }
    return modules.contains(moduleId);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: FutureBuilder<Set<String>>(
          future: ModuleAccessService().loadModulesForCurrentUser(),
          builder: (
            BuildContext context,
            AsyncSnapshot<Set<String>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final Set<String> modules = snapshot.data ?? <String>{};
            final List<_DrawerEntry> moduleEntries =
                _moduleEntriesForCurrent(modules);
            final List<_DrawerEntry> extraEntries =
                _extraEntries(modules, moduleEntries);

            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Demo Pedidos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.apps),
                  title: const Text('Panel de módulos'),
                  onTap: () => _goToModules(context),
                ),
                const Divider(),
                if (moduleEntries.isEmpty)
                  const ListTile(
                    title: Text('Sin accesos configurados para este módulo.'),
                    subtitle: Text('Solicita permisos a un administrador.'),
                    enabled: false,
                  )
                else
                  ...moduleEntries
                      .map((entry) => _buildTile(context, entry: entry))
                      .toList(),
                if (extraEntries.isNotEmpty) ...<Widget>[
                  const Divider(),
                  ...extraEntries
                      .map((entry) => _buildTile(context, entry: entry))
                      .toList(),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar sesión'),
                  onTap: () => _signOut(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_DrawerEntry> _moduleEntriesForCurrent(Set<String> modules) {
    final String? moduleId = kSectionModuleMap[current];
    if (moduleId == null) {
      final _DrawerEntry? fallback = _entryFor(current);
      return fallback == null ? <_DrawerEntry>[] : <_DrawerEntry>[fallback];
    }

    final ModuleDefinition? definition = kModuleCatalog[moduleId];
    final List<AppSection> sections =
        definition?.sections ?? <AppSection>[current];

    return sections
        .where((AppSection section) => _canSeeSection(modules, section))
        .map(_entryFor)
        .whereType<_DrawerEntry>()
        .toList();
  }

  List<_DrawerEntry> _extraEntries(
    Set<String> modules,
    List<_DrawerEntry> moduleEntries,
  ) {
    final Set<AppSection> moduleSections =
        moduleEntries.map((_) => _.section).toSet();
    final List<_DrawerEntry> extras = <_DrawerEntry>[];

    for (final AppSection section in _extraSectionsForCurrent()) {
      if (moduleSections.contains(section)) {
        continue;
      }
      if (!_canSeeSection(modules, section)) {
        continue;
      }
      final _DrawerEntry? entry = _entryFor(section);
      if (entry != null) {
        extras.add(entry);
      }
    }
    return extras;
  }

  List<AppSection> _extraSectionsForCurrent() {
    final String? moduleId = kSectionModuleMap[current];
    if (moduleId == 'pedidos') {
      return const <AppSection>[
        AppSection.clientes,
        AppSection.bases,
        AppSection.productos,
        AppSection.bancos,
      ];
    }
    return const <AppSection>[];
  }

  _DrawerEntry? _entryFor(AppSection section) {
    switch (section) {
      case AppSection.pedidos:
        return _DrawerEntry(
          section,
          Icons.assignment_outlined,
          'Pedidos',
        );
      case AppSection.movimientos:
        return _DrawerEntry(
          section,
          Icons.local_shipping_outlined,
          'Movimientos',
        );
      case AppSection.viajes:
        return _DrawerEntry(
          section,
          Icons.route_outlined,
          'Viajes',
        );
      case AppSection.viajesDetalle:
        return _DrawerEntry(
          section,
          Icons.playlist_add_check_outlined,
          'Detalle de viajes',
        );
      case AppSection.operacionesStock:
        return _DrawerEntry(
          section,
          Icons.inventory_2_outlined,
          'Stock',
        );
      case AppSection.operacionesHistorial:
        return _DrawerEntry(
          section,
          Icons.history,
          'Historial',
        );
      case AppSection.operacionesCompras:
        return _DrawerEntry(
          section,
          Icons.receipt_long_outlined,
          'Compras',
        );
      case AppSection.operacionesTransferencias:
        return _DrawerEntry(
          section,
          Icons.compare_arrows_outlined,
          'Transferencias',
        );
      case AppSection.operacionesFabricacion:
        return _DrawerEntry(
          section,
          Icons.precision_manufacturing_outlined,
          'Fabricación',
        );
      case AppSection.operacionesAjustes:
        return _DrawerEntry(
          section,
          Icons.tune_outlined,
          'Ajustes',
        );
      case AppSection.operacionesBases:
        return _DrawerEntry(
          section,
          Icons.home_work_outlined,
          'Bases',
        );
      case AppSection.operacionesProductos:
        return _DrawerEntry(
          section,
          Icons.fastfood_outlined,
          'Productos',
        );
      case AppSection.productos:
        return _DrawerEntry(
          section,
          Icons.fastfood_outlined,
          'Productos',
        );
      case AppSection.clientes:
        return _DrawerEntry(
          section,
          Icons.people_alt_outlined,
          'Clientes',
        );
      case AppSection.bases:
        return _DrawerEntry(
          section,
          Icons.home_work_outlined,
          'Bases',
        );
      case AppSection.proveedores:
        return _DrawerEntry(
          section,
          Icons.store_mall_directory_outlined,
          'Proveedores',
        );
      case AppSection.bancos:
        return _DrawerEntry(
          section,
          Icons.account_balance_wallet_outlined,
          'Bancos',
        );
      case AppSection.usuarios:
        return _DrawerEntry(
          section,
          Icons.admin_panel_settings_outlined,
          'Usuarios',
        );
    }
  }

  Widget _buildTile(
    BuildContext context, {
    required _DrawerEntry entry,
  }) {
    final bool selected = entry.section == current;
    return ListTile(
      leading: Icon(entry.icon),
      title: Text(entry.title),
      selected: selected,
      onTap: () => _navigate(context, entry.section),
    );
  }
}

class _DrawerEntry {
  const _DrawerEntry(this.section, this.icon, this.title);

  final AppSection section;
  final IconData icon;
  final String title;
}

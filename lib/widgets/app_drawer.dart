import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/features/administracion/presentation/list/perfiles_list_view.dart';
import 'package:demo_pedidos/features/cuentas/presentation/list/cuentas_list_view.dart';
import 'package:demo_pedidos/features/clientes/presentation/list/clientes_list_view.dart';
import 'package:demo_pedidos/features/home/presentation/modules_dashboard_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/list/movimientos_list_view.dart';
import 'package:demo_pedidos/features/pedidos/presentation/list/pedidos_list_view.dart';
import 'package:demo_pedidos/features/productos/presentation/list/productos_list_view.dart';
import 'package:demo_pedidos/features/viajes/presentation/list/viaje_detalles_list_view.dart';
import 'package:demo_pedidos/features/viajes/presentation/list/viajes_list_view.dart';
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
        case AppSection.movimientos:
          return const MovimientosListView();
        case AppSection.viajes:
          return const ViajesListView();
        case AppSection.viajesDetalle:
          return const ViajeDetallesListView();
        case AppSection.productos:
          return const ProductosListView();
        case AppSection.bancos:
          return const CuentasListView();
        case AppSection.clientes:
          return const ClientesListView();
        case AppSection.usuarios:
          return const PerfilesListView();
        case AppSection.pedidos:
          return const PedidosListView();
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
                if (_canSeeSection(modules, AppSection.pedidos))
                  _buildTile(
                    context,
                    icon: Icons.assignment_outlined,
                    title: 'Pedidos',
                    section: AppSection.pedidos,
                  ),
                if (_canSeeSection(modules, AppSection.movimientos))
                  _buildTile(
                    context,
                    icon: Icons.local_shipping_outlined,
                    title: 'Movimientos',
                    section: AppSection.movimientos,
                  ),
                if (_canSeeSection(modules, AppSection.viajes))
                  _buildTile(
                    context,
                    icon: Icons.route_outlined,
                    title: 'Viajes',
                    section: AppSection.viajes,
                  ),
                if (_canSeeSection(modules, AppSection.viajesDetalle))
                  _buildTile(
                    context,
                    icon: Icons.playlist_add_check_outlined,
                    title: 'Detalle de viajes',
                    section: AppSection.viajesDetalle,
                  ),
                const Divider(),
                if (_canSeeSection(modules, AppSection.productos))
                  _buildTile(
                    context,
                    icon: Icons.fastfood_outlined,
                    title: 'Productos',
                    section: AppSection.productos,
                  ),
                if (_canSeeSection(modules, AppSection.clientes))
                  _buildTile(
                    context,
                    icon: Icons.people_alt_outlined,
                    title: 'Clientes',
                    section: AppSection.clientes,
                  ),
                if (_canSeeSection(modules, AppSection.bancos))
                  _buildTile(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Bancos',
                    section: AppSection.bancos,
                  ),
                const Divider(),
                if (_canSeeSection(modules, AppSection.usuarios))
                  _buildTile(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Usuarios',
                    section: AppSection.usuarios,
                  ),
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

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required AppSection section,
  }) {
    final bool selected = section == current;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      onTap: () => _navigate(context, section),
    );
  }
}

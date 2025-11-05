import 'package:flutter/material.dart';

import '../views/cuentas_list.dart';
import '../views/clientes_list.dart';
import '../views/movimientos_list.dart';
import '../views/pedidos_list.dart';
import '../views/productos_list.dart';

enum AppSection { pedidos, movimientos, productos, bancos, clientes }

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
        case AppSection.productos:
          return const ProductosListView();
        case AppSection.bancos:
          return const CuentasListView();
        case AppSection.clientes:
          return const ClientesListView();
        case AppSection.pedidos:
        default:
          return const PedidosListView();
      }
    }

    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => builder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
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
            _buildTile(
              context,
              icon: Icons.assignment_outlined,
              title: 'Pedidos',
              section: AppSection.pedidos,
            ),
            _buildTile(
              context,
              icon: Icons.local_shipping_outlined,
              title: 'Movimientos',
              section: AppSection.movimientos,
            ),
            const Divider(),
            _buildTile(
              context,
              icon: Icons.fastfood_outlined,
              title: 'Productos',
              section: AppSection.productos,
            ),
            _buildTile(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Bancos',
              section: AppSection.bancos,
            ),
            _buildTile(
              context,
              icon: Icons.people_alt_outlined,
              title: 'Clientes',
              section: AppSection.clientes,
            ),
          ],
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

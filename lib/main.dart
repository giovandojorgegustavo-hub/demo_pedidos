import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demo_pedidos/features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lwtplpfakbtlsgpxkydn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3dHBscGZha2J0bHNncHhreWRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NzYwODcsImV4cCI6MjA3ODU1MjA4N30.kTU5NT5nj5PviQvDf6EoTvOvC7TAEUx3aYgcs1o16Wk',
  );

  runApp(const DemoPedidosApp());
}

class DemoPedidosApp extends StatelessWidget {
  const DemoPedidosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Gestor de Pedidos',
      home: AuthGate(),
    );
  }
}

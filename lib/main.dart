import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demo_pedidos/features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ftcnmqsnerhsdykczrdo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0Y25tcXNuZXJoc2R5a2N6cmRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1MDgwNzIsImV4cCI6MjA3OTA4NDA3Mn0.sI7RBmWhnGGxH-QfAYvZFxrs_mMiMtQYb4mPNKtIreg',
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

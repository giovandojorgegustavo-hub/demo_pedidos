import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demo_pedidos/features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ayoapigbqckymgnvcfro.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF5b2FwaWdicWNreW1nbnZjZnJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2NDYwMDIsImV4cCI6MjA3ODIyMjAwMn0.iendMrCGRnvyUuMcYDIxGTEdpTUE21uyi-rZaJnqT4k',
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

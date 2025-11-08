import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demo_pedidos/features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ytectulgdvrdhrrovvpg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl0ZWN0dWxnZHZyZGhycm92dnBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1Mzk0MzQsImV4cCI6MjA3ODExNTQzNH0.Qq8P1hg1-vnt6k6j8wb-YeoDv1gDM5Un_3GlzRDYjPM',
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

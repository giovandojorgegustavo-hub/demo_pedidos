import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/pedidos_list.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sgepmrvtyhxecdfrgzxb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnZXBtcnZ0eWh4ZWNkZnJnenhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMDIzNjQsImV4cCI6MjA3Nzg3ODM2NH0.7ZplxzRuvlo7sC1NHdkZcIScxmGb-3zxqNq30gF5g5g',
  );

  runApp(const DemoPedidosApp());
}

class DemoPedidosApp extends StatelessWidget {
  const DemoPedidosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Gestor de Pedidos',
      home: PedidosListView(),
    );
  }
}

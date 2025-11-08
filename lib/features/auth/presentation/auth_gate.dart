import 'dart:async';

import 'package:demo_pedidos/features/auth/presentation/login_view.dart';
import 'package:demo_pedidos/features/home/presentation/modules_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final SupabaseClient client = Supabase.instance.client;
    _session = client.auth.currentSession;
    _authSubscription = client.auth.onAuthStateChange.listen((AuthState data) {
      if (!mounted) {
        return;
      }
      setState(() {
        _session = data.session;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const LoginView();
    }
    return const ModulesDashboardView();
  }
}

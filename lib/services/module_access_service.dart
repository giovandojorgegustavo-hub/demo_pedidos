import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

const List<String> kAllModules = <String>[
  'bases',
  'pedidos',
  'operaciones',
  'finanzas',
  'almacen',
  'administracion',
  'contabilidad',
  'asistencias',
  'comunicaciones',
  'reportes',
];

/// Simple helper to fetch the modules that the logged-in user can access.
class ModuleAccessService {
  ModuleAccessService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static Set<String>? _cachedModules;
  static Future<Set<String>>? _pendingLoad;

  Future<Set<String>> loadModulesForCurrentUser({bool forceRefresh = false}) {
    if (!forceRefresh && _cachedModules != null) {
      return Future<Set<String>>.value(_cachedModules);
    }
    if (!forceRefresh && _pendingLoad != null) {
      return _pendingLoad!;
    }

    final Completer<Set<String>> completer = Completer<Set<String>>();
    _pendingLoad = completer.future;

    _loadFromSupabase().then((Set<String> modules) {
      _cachedModules = modules;
      completer.complete(modules);
    }).catchError((Object error, StackTrace stackTrace) {
      completer.completeError(error, stackTrace);
    }).whenComplete(() {
      _pendingLoad = null;
    });

    return completer.future;
  }

  Future<Set<String>> _loadFromSupabase() async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      return <String>{};
    }

    final Map<String, dynamic>? perfil = await _client
        .from('perfiles')
        .select('rol')
        .eq('user_id', user.id)
        .maybeSingle();

    final String rol =
        (perfil?['rol'] as String?)?.trim().toLowerCase() ?? 'atencion';

    final List<dynamic> rows = await _client
        .from('role_modules')
        .select('modulo')
        .eq('rol', rol);

    final Set<String> modules = rows
        .map<String?>((dynamic row) => row['modulo'] as String?)
        .whereType<String>()
        .map((String module) => module.trim().toLowerCase())
        .toSet();

    if (modules.isEmpty && rol == 'admin') {
      // Safety net in case the seed data changes.
      modules.addAll(kAllModules);
    }

    return modules;
  }

  static void clearCache() {
    _cachedModules = null;
    _pendingLoad = null;
  }
}

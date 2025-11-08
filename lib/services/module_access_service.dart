import 'package:supabase_flutter/supabase_flutter.dart';

const List<String> kAllModules = <String>[
  'bases',
  'pedidos',
  'operaciones',
  'finanzas',
  'almacen',
  'administracion',
];

/// Simple helper to fetch the modules that the logged-in user can access.
class ModuleAccessService {
  ModuleAccessService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Set<String>> loadModulesForCurrentUser() async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      return <String>{};
    }

    final Map<String, dynamic>? perfil = await _client
        .from('perfiles')
        .select('rol')
        .eq('user_id', user.id)
        .maybeSingle();

    final String rol = (perfil?['rol'] as String?)?.trim().toLowerCase() ?? 'atencion';

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
}

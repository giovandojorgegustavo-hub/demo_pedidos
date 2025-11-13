import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

const List<String> kCuentaContableTipos = <String>[
  'activo',
  'pasivo',
  'patrimonio',
  'ingreso',
  'gasto',
];

class CuentaContable {
  const CuentaContable({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    this.parentId,
    this.esTerminal = true,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String tipo;
  final String? parentId;
  final bool esTerminal;

  factory CuentaContable.fromJson(Map<String, dynamic> json) {
    return CuentaContable(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      parentId: json['parent_id'] as String?,
      esTerminal: json['es_terminal'] as bool? ?? true,
    );
  }

  static Future<List<CuentaContable>> fetchTerminales({String? tipo}) async {
    PostgrestFilterBuilder<dynamic> query = _supabase
        .from('cuentas_contables')
        .select('id,codigo,nombre,tipo,parent_id,es_terminal')
        .eq('es_terminal', true);

    if (tipo != null && tipo.isNotEmpty) {
      query = query.eq('tipo', tipo);
    }

    final List<dynamic> rows = await query.order('codigo');
    return rows
        .map((dynamic row) =>
            CuentaContable.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<List<CuentaContable>> fetchAll() async {
    final List<dynamic> rows = await _supabase
        .from('cuentas_contables')
        .select('id,codigo,nombre,tipo,parent_id,es_terminal')
        .order('codigo');
    return rows
        .map((dynamic row) =>
            CuentaContable.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> create({
    required String codigo,
    required String nombre,
    required String tipo,
    String? parentId,
    bool esTerminal = true,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo,
      'parent_id': parentId,
      'es_terminal': esTerminal,
    };

    final Map<String, dynamic> inserted = await _supabase
        .from('cuentas_contables')
        .insert(payload)
        .select('id')
        .single();

    if (parentId != null) {
      await _refreshParentTerminality(parentId);
    }
    return inserted['id'] as String;
  }

  static Future<void> update({
    required String id,
    required String codigo,
    required String nombre,
    required String tipo,
    String? parentId,
    required bool esTerminal,
    String? previousParentId,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo,
      'parent_id': parentId,
      'es_terminal': esTerminal,
    };

    await _supabase.from('cuentas_contables').update(payload).eq('id', id);

    if (parentId != null) {
      await _refreshParentTerminality(parentId);
    }
    if (previousParentId != null && previousParentId != parentId) {
      await _refreshParentTerminality(previousParentId);
    }
  }

  static Future<void> delete(String id, {String? parentId}) async {
    await _supabase.from('cuentas_contables').delete().eq('id', id);
    if (parentId != null) {
      await _refreshParentTerminality(parentId);
    }
  }

  static Future<void> _refreshParentTerminality(String parentId) async {
    final List<dynamic> children = await _supabase
        .from('cuentas_contables')
        .select('id')
        .eq('parent_id', parentId)
        .limit(1);
    final bool hasChildren = children.isNotEmpty;
    await _supabase
        .from('cuentas_contables')
        .update(<String, dynamic>{'es_terminal': !hasChildren})
        .eq('id', parentId);
  }
}

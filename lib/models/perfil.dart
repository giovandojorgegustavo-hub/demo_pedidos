import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

/// Representa un registro de la tabla `perfiles`.
class Perfil {
  const Perfil({
    required this.userId,
    this.nombre,
    required this.rol,
    required this.activo,
    this.registradoAt,
    this.editadoAt,
    this.registradoPor,
    this.editadoPor,
  });

  final String userId;
  final String? nombre;
  final String rol;
  final bool activo;
  final DateTime? registradoAt;
  final DateTime? editadoAt;
  final String? registradoPor;
  final String? editadoPor;

  static const List<String> availableRoles = <String>[
    'admin',
    'despacho',
    'atencion',
  ];

  factory Perfil.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Perfil(
      userId: json['user_id'] as String,
      nombre: json['nombre'] as String?,
      rol: json['rol'] as String? ?? 'atencion',
      activo: json['activo'] as bool? ?? true,
      registradoAt: _parseDate(json['registrado_at']),
      editadoAt: _parseDate(json['editado_at']),
      registradoPor: json['registrado_por'] as String?,
      editadoPor: json['editado_por'] as String?,
    );
  }

  Perfil copyWith({
    String? userId,
    String? nombre,
    String? rol,
    bool? activo,
    DateTime? registradoAt,
    DateTime? editadoAt,
    String? registradoPor,
    String? editadoPor,
  }) {
    return Perfil(
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      registradoAt: registradoAt ?? this.registradoAt,
      editadoAt: editadoAt ?? this.editadoAt,
      registradoPor: registradoPor ?? this.registradoPor,
      editadoPor: editadoPor ?? this.editadoPor,
    );
  }

  static Future<List<Perfil>> fetchAll() async {
    final List<dynamic> data = await _supabase
        .from('perfiles')
        .select(
          'user_id,nombre,rol,activo,registrado_at,editado_at,registrado_por,editado_por',
        )
        .order('rol')
        .order('nombre', ascending: true);
    return data
        .map((dynamic item) => Perfil.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<void> update(Perfil perfil) async {
    await _supabase.from('perfiles').update(<String, dynamic>{
      'nombre': perfil.nombre,
      'rol': perfil.rol,
      'activo': perfil.activo,
    }).eq('user_id', perfil.userId);
  }
}

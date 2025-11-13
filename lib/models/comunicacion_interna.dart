import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

const List<String> kComunicacionEstados =
    <String>['pendiente', 'en_proceso', 'atendido', 'cerrado'];
const List<String> kComunicacionPrioridades = <String>['baja', 'media', 'alta'];

class ComunicacionInterna {
  const ComunicacionInterna({
    required this.id,
    this.idBase,
    this.baseNombre,
    required this.asunto,
    required this.mensaje,
    required this.prioridad,
    required this.estado,
    this.registradoAt,
    this.registradoPor,
  });

  final String id;
  final String? idBase;
  final String? baseNombre;
  final String asunto;
  final String mensaje;
  final String prioridad;
  final String estado;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory ComunicacionInterna.fromJson(Map<String, dynamic> json) {
    return ComunicacionInterna(
      id: json['id'] as String,
      idBase: json['idbase'] as String?,
      baseNombre: json['base_nombre'] as String?,
      asunto: json['asunto'] as String,
      mensaje: json['mensaje'] as String,
      prioridad: json['prioridad'] as String? ?? 'media',
      estado: json['estado'] as String? ?? 'pendiente',
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<ComunicacionInterna>> fetchAll({
    String? estado,
    String? baseId,
    String? prioridad,
  }) async {
    var query = _supabase.from('v_comunicaciones_internas').select(
          'id,idbase,base_nombre,asunto,mensaje,prioridad,estado,registrado_at,registrado_por',
        );
    if (estado != null && estado.isNotEmpty) {
      query = query.eq('estado', estado);
    }
    if (baseId != null && baseId.isNotEmpty) {
      query = query.eq('idbase', baseId);
    }
    if (prioridad != null && prioridad.isNotEmpty) {
      query = query.eq('prioridad', prioridad);
    }

    final List<dynamic> rows =
        await query.order('registrado_at', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              ComunicacionInterna.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static Future<String> create(Map<String, dynamic> payload) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('comunicaciones_internas')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(String id, Map<String, dynamic> payload) async {
    await _supabase
        .from('comunicaciones_internas')
        .update(payload)
        .eq('id', id);
  }
}

class ComunicacionRespuesta {
  const ComunicacionRespuesta({
    required this.id,
    required this.idComunicacion,
    required this.mensaje,
    this.registradoAt,
    this.registradoPor,
  });

  final String id;
  final String idComunicacion;
  final String mensaje;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory ComunicacionRespuesta.fromJson(Map<String, dynamic> json) {
    return ComunicacionRespuesta(
      id: json['id'] as String,
      idComunicacion: json['idcomunicacion'] as String,
      mensaje: json['mensaje'] as String,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<ComunicacionRespuesta>> fetch(String comunicacionId) async {
    final List<dynamic> rows = await _supabase
        .from('v_comunicaciones_respuestas')
        .select('id,idcomunicacion,mensaje,registrado_at,registrado_por')
        .eq('idcomunicacion', comunicacionId)
        .order('registrado_at', ascending: true);
    return rows
        .map(
          (dynamic row) =>
              ComunicacionRespuesta.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static Future<void> create({
    required String comunicacionId,
    required String mensaje,
  }) async {
    await _supabase.from('comunicaciones_internas_respuestas').insert(<String, dynamic>{
      'idcomunicacion': comunicacionId,
      'mensaje': mensaje,
    });
  }
}

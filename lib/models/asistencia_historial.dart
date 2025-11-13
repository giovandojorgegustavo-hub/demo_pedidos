import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/models/asistencia_estado.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class AsistenciaHistorial {
  const AsistenciaHistorial({
    required this.id,
    required this.idBase,
    required this.baseNombre,
    required this.idSlot,
    required this.slotNombre,
    required this.slotHora,
    required this.fecha,
    required this.estado,
    this.observacion,
    this.registradoPor,
    this.registradoAt,
    this.editadoPor,
    this.editadoAt,
  });

  final String id;
  final String idBase;
  final String baseNombre;
  final String idSlot;
  final String slotNombre;
  final String slotHora;
  final DateTime fecha;
  final AsistenciaEstado estado;
  final String? observacion;
  final String? registradoPor;
  final DateTime? registradoAt;
  final String? editadoPor;
  final DateTime? editadoAt;

  factory AsistenciaHistorial.fromJson(Map<String, dynamic> json) {
    return AsistenciaHistorial(
      id: json['id'] as String,
      idBase: json['idbase'] as String,
      baseNombre: json['base_nombre'] as String,
      idSlot: json['idslot'] as String,
      slotNombre: json['slot_nombre'] as String,
      slotHora: json['slot_hora'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      estado: asistenciaEstadoFromString(json['estado'] as String),
      observacion: json['observacion'] as String?,
      registradoPor: json['registrado_por'] as String?,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      editadoPor: json['editado_por'] as String?,
      editadoAt: json['editado_at'] == null
          ? null
          : DateTime.tryParse(json['editado_at'] as String),
    );
  }

  static Future<List<AsistenciaHistorial>> fetch({
    DateTime? from,
    DateTime? to,
    String? baseId,
    AsistenciaEstado? estado,
  }) async {
    PostgrestFilterBuilder<dynamic> query = _supabase
        .from('v_asistencias_historial')
        .select(
          'id,idbase,base_nombre,idslot,slot_nombre,slot_hora,fecha,estado,observacion,registrado_por,registrado_at,editado_por,editado_at',
        );

    if (from != null) {
      query = query.gte('fecha', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('fecha', to.toIso8601String());
    }
    if (baseId != null && baseId.isNotEmpty) {
      query = query.eq('idbase', baseId);
    }
    if (estado != null) {
      query = query.eq('estado', asistenciaEstadoToString(estado));
    }

    final List<dynamic> rows =
        await query.order('fecha', ascending: false).order('slot_hora');
    return rows
        .map(
          (dynamic row) =>
              AsistenciaHistorial.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}

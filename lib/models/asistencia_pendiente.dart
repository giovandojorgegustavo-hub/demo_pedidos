import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/models/asistencia_estado.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class AsistenciaPendiente {
  const AsistenciaPendiente({
    required this.idBase,
    required this.baseNombre,
    required this.idSlot,
    required this.slotNombre,
    required this.slotHora,
    required this.fecha,
    required this.estado,
    this.registroId,
  });

  final String idBase;
  final String baseNombre;
  final String idSlot;
  final String slotNombre;
  final String slotHora;
  final DateTime fecha;
  final AsistenciaEstado estado;
  final String? registroId;

  factory AsistenciaPendiente.fromJson(Map<String, dynamic> json) {
    return AsistenciaPendiente(
      idBase: json['idbase'] as String,
      baseNombre: json['base_nombre'] as String,
      idSlot: json['idslot'] as String,
      slotNombre: json['slot_nombre'] as String,
      slotHora: json['slot_hora'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      estado: asistenciaEstadoFromString(json['estado'] as String),
      registroId: json['registro_id'] as String?,
    );
  }

  static Future<List<AsistenciaPendiente>> fetch({
    DateTime? fecha,
    String? baseId,
  }) async {
    if (fecha != null) {
      await _supabase.rpc(
        'fn_asistencias_generar_registros',
        params: <String, dynamic>{
          'p_fecha': fecha.toIso8601String().split('T').first,
        },
      );
    }

    var query = _supabase
        .from('v_asistencias_pendientes')
        .select(
          'idbase,base_nombre,idslot,slot_nombre,slot_hora,fecha,estado,registro_id',
        );

    if (fecha != null) {
      query = query.eq('fecha', fecha.toIso8601String());
    }
    if (baseId != null && baseId.isNotEmpty) {
      query = query.eq('idbase', baseId);
    }

    final List<dynamic> rows = await query.order('fecha').order('slot_hora');
    return rows
        .map(
          (dynamic row) =>
              AsistenciaPendiente.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static Future<void> marcar({
    required String idBase,
    required String idSlot,
    required DateTime fecha,
    required AsistenciaEstado estado,
    String? observacion,
    String? registroId,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'idbase': idBase,
      'idslot': idSlot,
      'fecha': fecha.toIso8601String(),
      'estado': asistenciaEstadoToString(estado),
      'observacion': observacion,
    };

    if (registroId == null) {
      await _supabase.from('asistencias_registro').insert(payload);
    } else {
      await _supabase
          .from('asistencias_registro')
          .update(payload)
          .eq('id', registroId);
    }
  }
}

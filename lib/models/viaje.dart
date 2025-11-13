import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Viaje {
  const Viaje({
    required this.id,
    required this.nombreMotorizado,
    required this.numLlamadas,
    required this.numPago,
    required this.link,
    required this.registradoAt,
    this.numWsp,
    this.monto,
    this.editadoAt,
    this.packingId,
    this.packingNombre,
    this.packingBaseId,
    this.totalItems = 0,
    this.pendientes = 0,
    this.estadoTexto,
    this.estadoCodigo,
  });

  final String id;
  final String nombreMotorizado;
  final String numLlamadas;
  final String numPago;
  final String link;
  final DateTime registradoAt;
  final String? numWsp;
  final double? monto;
  final DateTime? editadoAt;
  final String? packingId;
  final String? packingNombre;
  final String? packingBaseId;
  final int totalItems;
  final int pendientes;
  final String? estadoTexto;
  final int? estadoCodigo;

  bool get estaTerminado => pendientes == 0 && totalItems > 0;

  factory Viaje.fromJson(Map<String, dynamic> json) {
    final dynamic registradoRaw =
        json['registrado_at'] ?? json['fecharegistro'] ?? json['created_at'];
    final dynamic editadoRaw = json['editado_at'];

    return Viaje(
      id: json['id'] as String,
      nombreMotorizado: json['nombre_motorizado'] as String,
      numLlamadas: json['num_llamadas'] as String,
      numPago: json['num_pago'] as String,
      link: (json['link'] as String?) ?? '',
      numWsp: json['num_wsp'] as String?,
      monto: _parseDouble(json['monto']),
      registradoAt: _parseDateTime(registradoRaw),
      editadoAt: editadoRaw == null ? null : _parseDateTime(editadoRaw),
      packingId: json['idpacking'] as String?,
      packingNombre: json['packing_nombre'] as String?,
      packingBaseId: json['packing_base_id'] as String?,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      pendientes: (json['pendientes'] as num?)?.toInt() ?? 0,
      estadoTexto: json['estado_texto'] as String?,
      estadoCodigo: (json['estado_codigo'] as num?)?.toInt(),
    );
  }

  Viaje copyWith({
    String? id,
    String? nombreMotorizado,
    String? numLlamadas,
    String? numPago,
    String? link,
    DateTime? registradoAt,
    String? numWsp,
    double? monto,
    DateTime? editadoAt,
    String? packingId,
    String? packingNombre,
    String? packingBaseId,
  }) {
    return Viaje(
      id: id ?? this.id,
      nombreMotorizado: nombreMotorizado ?? this.nombreMotorizado,
      numLlamadas: numLlamadas ?? this.numLlamadas,
      numPago: numPago ?? this.numPago,
      link: link ?? this.link,
      registradoAt: registradoAt ?? this.registradoAt,
      numWsp: numWsp ?? this.numWsp,
      monto: monto ?? this.monto,
      editadoAt: editadoAt ?? this.editadoAt,
      packingId: packingId ?? this.packingId,
      packingNombre: packingNombre ?? this.packingNombre,
      packingBaseId: packingBaseId ?? this.packingBaseId,
      totalItems: totalItems,
      pendientes: pendientes,
      estadoTexto: estadoTexto,
      estadoCodigo: estadoCodigo,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'nombre_motorizado': nombreMotorizado,
      'num_llamadas': numLlamadas,
      'num_wsp': numWsp,
      'num_pago': numPago,
      'link': link,
      'idpacking': packingId,
      'monto': monto,
      'registrado_at': registradoAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'nombre_motorizado': nombreMotorizado,
      'num_llamadas': numLlamadas,
      'num_wsp': numWsp,
      'num_pago': numPago,
      'link': link,
      'idpacking': packingId,
      'monto': monto,
      'registrado_at': registradoAt.toIso8601String(),
      'editado_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<Viaje>> fetchAll() async {
    final List<dynamic> data = await _supabase
        .from('v_viaje_vistageneral')
        .select()
        .order('registrado_at', ascending: false);
    return data
        .map((dynamic item) => Viaje.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<Viaje?> fetchById(String id) async {
    final Map<String, dynamic>? data = await _supabase
        .from('v_viaje_vistageneral')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return Viaje.fromJson(data);
  }

  static Future<String> insert(Viaje viaje) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('viajes')
        .insert(viaje.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(Viaje viaje) async {
    await _supabase
        .from('viajes')
        .update(viaje.toUpdateJson())
        .eq('id', viaje.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('viajes').delete().eq('id', id);
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value');
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('Fecha inválida: $value');
  }
}

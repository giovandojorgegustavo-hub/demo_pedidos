import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class ViajeDetalle {
  const ViajeDetalle({
    required this.id,
    required this.idViaje,
    required this.idMovimiento,
    required this.createdAt,
    this.llegadaAt,
    this.clienteNombre,
    this.contactoNumero,
    this.direccionTexto,
    this.direccionReferencia,
    this.esProvincia = false,
    this.provinciaDestino,
    this.provinciaDestinatario,
    this.provinciaDni,
    this.baseNombre,
  });

  final String id;
  final String idViaje;
  final String idMovimiento;
  final DateTime createdAt;
  final DateTime? llegadaAt;
  final String? clienteNombre;
  final String? contactoNumero;
  final String? direccionTexto;
  final String? direccionReferencia;
  final bool esProvincia;
  final String? provinciaDestino;
  final String? provinciaDestinatario;
  final String? provinciaDni;
  final String? baseNombre;

  bool get entregado => llegadaAt != null;

  factory ViajeDetalle.fromJson(Map<String, dynamic> json) {
    return ViajeDetalle(
      id: json['id'] as String,
      idViaje: json['idviaje'] as String,
      idMovimiento: json['idmovimiento'] as String,
      createdAt: DateTime.parse(json['registrado_at'] as String),
      llegadaAt: json['llegada_at'] == null
          ? null
          : DateTime.parse(json['llegada_at'] as String),
      clienteNombre: json['cliente_nombre'] as String?,
      contactoNumero: json['contacto_numero'] as String?,
      direccionTexto: json['direccion_texto'] as String?,
      direccionReferencia: json['direccion_referencia'] as String?,
      esProvincia: json['es_provincia'] as bool? ?? false,
      provinciaDestino: json['provincia_destino'] as String?,
      provinciaDestinatario: json['provincia_destinatario'] as String?,
      provinciaDni: json['provincia_dni'] as String?,
      baseNombre: json['base_nombre'] as String?,
    );
  }

  static Future<List<ViajeDetalle>> getByViaje(String viajeId) async {
    final List<dynamic> data = await _supabase
        .from('v_viaje_detalle_vistageneral')
        .select()
        .eq('idviaje', viajeId)
        .order('registrado_at');
    return data
        .map((dynamic item) => ViajeDetalle.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<List<ViajeDetalle>> fetchAll() async {
    final List<dynamic> data = await _supabase
        .from('v_viaje_detalle_vistageneral')
        .select()
        .order('registrado_at', ascending: false);
    return data
        .map((dynamic item) => ViajeDetalle.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<ViajeDetalle> insert({
    required String idViaje,
    required String idMovimiento,
  }) async {
    final Map<String, dynamic> data = await _supabase
        .from('viajesdetalles')
        .insert(<String, dynamic>{
          'idviaje': idViaje,
          'idmovimiento': idMovimiento,
        })
        .select()
        .single();
    return ViajeDetalle.fromJson(data);
  }

  static Future<void> delete(String id) async {
    await _supabase.from('viajesdetalles').delete().eq('id', id);
  }

  static Future<void> marcarLlegada({
    required String id,
    required String usuario,
    DateTime? fecha,
  }) async {
    await _supabase.from('viajesdetalles').update(<String, dynamic>{
      'llegada_at': (fecha ?? DateTime.now()).toIso8601String(),
    }).eq('id', id);
  }

  static Future<Set<String>> movimientosAsignados() async {
    final List<dynamic> data = await _supabase
        .from('viajesdetalles')
        .select('idmovimiento');
    return data
        .map((dynamic item) => (item as Map<String, dynamic>)['idmovimiento'] as String)
        .toSet();
  }

  static Future<void> actualizarMovimiento({
    required String id,
    required String idMovimiento,
  }) async {
    await _supabase.from('viajesdetalles').update(<String, dynamic>{
      'idmovimiento': idMovimiento,
      'llegada_at': null,
    }).eq('id', id);
  }
}

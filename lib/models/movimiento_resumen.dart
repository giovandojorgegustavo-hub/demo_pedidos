import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class MovimientoResumen {
  const MovimientoResumen({
    required this.id,
    required this.idPedido,
    required this.fecha,
    required this.esProvincia,
    required this.clienteNombre,
    required this.estadoTexto,
    required this.estadoCodigo,
    this.idBase,
    this.baseNombre,
    this.clienteNumero,
    this.contactoNumero,
    this.direccion,
    this.direccionReferencia,
    this.provinciaDestino,
    this.provinciaDestinatario,
    this.provinciaDni,
    this.observacion,
  });

  final String id;
  final String idPedido;
  final DateTime fecha;
  final bool esProvincia;
  final String clienteNombre;
  final String estadoTexto;
  final int estadoCodigo;
  final String? idBase;
  final String? baseNombre;
  final String? clienteNumero;
  final String? contactoNumero;
  final String? direccion;
  final String? direccionReferencia;
  final String? provinciaDestino;
  final String? provinciaDestinatario;
  final String? provinciaDni;
  final String? observacion;

  factory MovimientoResumen.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return MovimientoResumen(
      id: json['id'] as String,
      idPedido: json['idpedido'] as String,
      fecha: _parseDate(json['fecharegistro']),
      esProvincia: json['es_provincia'] as bool? ?? false,
      idBase: json['idbase'] as String?,
      baseNombre: json['base_nombre'] as String?,
      estadoTexto: json['estado_texto'] as String? ?? 'desconocido',
      estadoCodigo: json['estado_codigo'] as int? ?? 0,
      clienteNombre:
          (json['cliente_nombre'] as String?) ?? 'Cliente sin nombre',
      clienteNumero: json['cliente_numero'] as String?,
      contactoNumero: json['contacto_numero'] as String?,
      direccion: json['direccion_texto'] as String?,
      provinciaDestino: json['provincia_destino'] as String?,
      direccionReferencia: json['direccion_referencia'] as String?,
      provinciaDestinatario: json['provincia_destinatario'] as String?,
      provinciaDni: json['provincia_dni'] as String?,
      observacion: json['observacion'] as String?,
    );
  }

  static Future<List<MovimientoResumen>> fetchAll() async {
    final List<dynamic> data =
        await _supabase.from('v_movimiento_vistageneral').select('''
          id,
          idpedido,
          fecharegistro,
          es_provincia,
          idbase,
          base_nombre,
          cliente_numero,
          estado_texto,
          estado_codigo,
          cliente_nombre,
          contacto_numero,
          direccion_texto,
          direccion_referencia,
          provincia_destino,
          provincia_destinatario,
          provincia_dni,
          observacion
        ''').order('estado_codigo').order('fecharegistro', ascending: false);

    return data
        .map((dynamic item) =>
            MovimientoResumen.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<List<MovimientoResumen>> fetchByPedido(String pedidoId) async {
    final List<dynamic> data = await _supabase
        .from('v_movimiento_vistageneral')
        .select('''
          id,
          idpedido,
          fecharegistro,
          es_provincia,
          idbase,
          base_nombre,
          cliente_numero,
          estado_texto,
          estado_codigo,
          cliente_nombre,
          contacto_numero,
          direccion_texto,
          direccion_referencia,
          provincia_destino,
          provincia_destinatario,
          provincia_dni,
          observacion
        ''')
        .eq('idpedido', pedidoId)
        .order('estado_codigo')
        .order('fecharegistro', ascending: false);

    return data
        .map((dynamic item) =>
            MovimientoResumen.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<MovimientoResumen?> fetchById(String id) async {
    final Map<String, dynamic>? data =
        await _supabase.from('v_movimiento_vistageneral').select('''
          id,
          idpedido,
          fecharegistro,
          es_provincia,
          idbase,
          base_nombre,
          cliente_numero,
          estado_texto,
          estado_codigo,
          cliente_nombre,
          contacto_numero,
          direccion_texto,
          direccion_referencia,
          provincia_destino,
          provincia_destinatario,
          provincia_dni,
          observacion
        ''').eq('id', id).maybeSingle();
    if (data == null) {
      return null;
    }
    return MovimientoResumen.fromJson(data);
  }
}

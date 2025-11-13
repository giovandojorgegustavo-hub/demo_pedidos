import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

const List<String> kIncidenteSeveridades = <String>['baja', 'media', 'alta', 'critica'];
const List<String> kIncidenteEstados = <String>['abierto', 'investigacion', 'resuelto', 'cerrado'];
const List<String> kIncidenteResponsables = <String>['cliente', 'base', 'operador', 'externo'];

class Incidente {
  const Incidente({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.categoria,
    required this.severidad,
    required this.estado,
    this.responsabilidad,
    this.idPedido,
    this.idMovimiento,
    this.idCliente,
    this.clienteNombre,
    this.idBase,
    this.baseNombre,
    this.idUsuario,
    this.registradoAt,
    this.registradoPor,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final String? categoria;
  final String severidad;
  final String estado;
  final String? responsabilidad;
  final String? idPedido;
  final String? idMovimiento;
  final String? idCliente;
  final String? clienteNombre;
  final String? idBase;
  final String? baseNombre;
  final String? idUsuario;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory Incidente.fromJson(Map<String, dynamic> json) {
    return Incidente(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      categoria: json['categoria'] as String?,
      severidad: json['severidad'] as String? ?? 'media',
      estado: json['estado'] as String? ?? 'abierto',
      responsabilidad: json['responsabilidad'] as String?,
      idPedido: json['idpedido'] as String?,
      idMovimiento: json['idmovimiento'] as String?,
      idCliente: json['idcliente'] as String?,
      clienteNombre: json['cliente_nombre'] as String?,
      idBase: json['idbase'] as String?,
      baseNombre: json['base_nombre'] as String?,
      idUsuario: json['idusuario'] as String?,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<Incidente>> fetchAll({
    String? estado,
    String? responsabilidad,
    String? baseId,
  }) async {
    var query = _supabase.from('v_incidencias_general').select(
          'id,titulo,descripcion,categoria,severidad,estado,responsabilidad,'
          'idpedido,idmovimiento,idcliente,cliente_nombre,idbase,base_nombre,'
          'idusuario,registrado_at,registrado_por',
        );

    if (estado != null && estado.isNotEmpty) {
      query = query.eq('estado', estado);
    }
    if (responsabilidad != null && responsabilidad.isNotEmpty) {
      query = query.eq('responsabilidad', responsabilidad);
    }
    if (baseId != null && baseId.isNotEmpty) {
      query = query.eq('idbase', baseId);
    }

    final List<dynamic> rows =
        await query.order('registrado_at', ascending: false);
    return rows
        .map((dynamic row) => Incidente.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> create(Map<String, dynamic> payload) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('incidentes')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(String id, Map<String, dynamic> payload) async {
    await _supabase.from('incidentes').update(payload).eq('id', id);
  }
}

class IncidenteHistorial {
  const IncidenteHistorial({
    required this.id,
    required this.idIncidente,
    this.comentario,
    this.estado,
    this.registradoAt,
    this.registradoPor,
  });

  final String id;
  final String idIncidente;
  final String? comentario;
  final String? estado;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory IncidenteHistorial.fromJson(Map<String, dynamic> json) {
    return IncidenteHistorial(
      id: json['id'] as String,
      idIncidente: json['idincidente'] as String,
      comentario: json['comentario'] as String?,
      estado: json['estado'] as String?,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<IncidenteHistorial>> fetch(String incidenteId) async {
    final List<dynamic> rows = await _supabase
        .from('v_incidencias_historial')
        .select('id,idincidente,comentario,estado,registrado_at,registrado_por')
        .eq('idincidente', incidenteId)
        .order('registrado_at', ascending: false);
    return rows
        .map((dynamic row) =>
            IncidenteHistorial.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<void> add({
    required String incidenteId,
    required String comentario,
    String? estado,
  }) async {
    await _supabase.from('incidentes_historial').insert(<String, dynamic>{
      'idincidente': incidenteId,
      'comentario': comentario,
      if (estado != null) 'estado': estado,
    });
  }
}

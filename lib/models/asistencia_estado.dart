enum AsistenciaEstado { falta, asistio, justificado }

String asistenciaEstadoToString(AsistenciaEstado estado) {
  switch (estado) {
    case AsistenciaEstado.asistio:
      return 'asistio';
    case AsistenciaEstado.justificado:
      return 'justificado';
    case AsistenciaEstado.falta:
      return 'falta';
  }
}

AsistenciaEstado asistenciaEstadoFromString(String value) {
  switch (value) {
    case 'asistio':
      return AsistenciaEstado.asistio;
    case 'justificado':
      return AsistenciaEstado.justificado;
    default:
      return AsistenciaEstado.falta;
  }
}

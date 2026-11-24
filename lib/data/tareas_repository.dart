import '../models/tarea.dart';

/// Contrato de la capa de datos. La UI solo conoce este contrato, no SQL.
abstract class TareasRepository {
  /// Consulta reactiva: emite la lista completa cuando la tabla cambia.
  Stream<List<Tarea>> watchTareas();

  Future<void> agregarTarea(String titulo);

  Future<void> actualizarTitulo(int id, String titulo);

  Future<void> cambiarEstado(int id, bool completada);

  Future<void> eliminarTarea(int id);

  /// Libera el executor cuando la app o la prueba ya no necesita la base.
  Future<void> close();
}

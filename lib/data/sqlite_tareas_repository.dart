import 'package:drift/drift.dart';

import '../models/tarea.dart';
import 'app_database.dart';
import 'tareas_repository.dart';

/// Implementación real: todas las operaciones se ejecutan en SQLite.
class SqliteTareasRepository implements TareasRepository {
  SqliteTareasRepository(this._db);

  final AppDatabase _db;

  static const int _longitudMaxima = 200;

  @override
  Stream<List<Tarea>> watchTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return consulta.map(_mapear).watch();
  }

  @override
  Future<void> agregarTarea(String titulo) async {
    await _db.into(_db.tareas).insert(
          TareasCompanion.insert(titulo: _validar(titulo)),
        );
  }

  @override
  Future<void> actualizarTitulo(int id, String titulo) async {
    _validarId(id);
    final filas = await (_db.update(_db.tareas)
          ..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(_validar(titulo))));
    _verificarFilas(filas, id);
  }

  @override
  Future<void> cambiarEstado(int id, bool completada) async {
    _validarId(id);
    final filas = await (_db.update(_db.tareas)
          ..where((t) => t.id.equals(id)))
        .write(TareasCompanion(completada: Value(completada)));
    _verificarFilas(filas, id);
  }

  @override
  Future<void> eliminarTarea(int id) async {
    _validarId(id);
    final filas = await (_db.delete(_db.tareas)
          ..where((t) => t.id.equals(id)))
        .go();
    _verificarFilas(filas, id);
  }

  @override
  Future<void> close() => _db.close();

  String _validar(String titulo) {
    final normalizado = titulo.trim();
    if (normalizado.isEmpty) {
      throw ArgumentError('El título no puede estar vacío');
    }
    if (normalizado.length > _longitudMaxima) {
      throw ArgumentError('El título no puede superar $_longitudMaxima caracteres');
    }
    return normalizado;
  }

  void _validarId(int id) {
    if (id <= 0) {
      throw ArgumentError('ID de tarea inválido');
    }
  }

  void _verificarFilas(int filas, int id) {
    if (filas == 0) {
      throw StateError('No se encontró la tarea con ID $id');
    }
  }

  Tarea _mapear(TareaRow fila) => Tarea(
        id: fila.id,
        titulo: fila.titulo,
        completada: fila.completada,
      );
}

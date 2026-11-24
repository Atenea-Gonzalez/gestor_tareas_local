import 'dart:async';

import 'package:gestor_tareas_local/data/tareas_repository.dart';
import 'package:gestor_tareas_local/models/tarea.dart';

/// Doble en memoria para probar la interfaz sin abrir SQLite.
class FakeTareasRepository implements TareasRepository {
  final List<Tarea> _tareas = <Tarea>[];
  final StreamController<List<Tarea>> _controlador =
      StreamController<List<Tarea>>.broadcast();
  int _siguienteId = 1;

  List<Tarea> get tareas => List<Tarea>.unmodifiable(_tareas);

  @override
  Stream<List<Tarea>> watchTareas() async* {
    // Un StreamBuilder necesita un primer evento para salir de "waiting".
    yield List<Tarea>.unmodifiable(_tareas);
    yield* _controlador.stream;
  }

  @override
  Future<void> agregarTarea(String titulo) async {
    final normalizado = titulo.trim();
    if (normalizado.isEmpty) {
      throw ArgumentError('El título no puede estar vacío');
    }
    if (normalizado.length > 200) {
      throw ArgumentError('El título no puede superar 200 caracteres');
    }
    _tareas.add(
      Tarea(id: _siguienteId++, titulo: normalizado, completada: false),
    );
    _notificar();
  }

  @override
  Future<void> actualizarTitulo(int id, String titulo) async {
    final normalizado = titulo.trim();
    if (normalizado.isEmpty) {
      throw ArgumentError('El título no puede estar vacío');
    }
    final indice = _indice(id);
    _tareas[indice] = Tarea(
      id: id,
      titulo: normalizado,
      completada: _tareas[indice].completada,
    );
    _notificar();
  }

  @override
  Future<void> cambiarEstado(int id, bool completada) async {
    final indice = _indice(id);
    _tareas[indice] = Tarea(
      id: id,
      titulo: _tareas[indice].titulo,
      completada: completada,
    );
    _notificar();
  }

  @override
  Future<void> eliminarTarea(int id) async {
    _tareas.removeAt(_indice(id));
    _notificar();
  }

  @override
  Future<void> close() => _controlador.close();

  int _indice(int id) {
    final indice = _tareas.indexWhere((tarea) => tarea.id == id);
    if (indice == -1) throw StateError('No se encontró la tarea con ID $id');
    return indice;
  }

  void _notificar() => _controlador.add(List<Tarea>.unmodifiable(_tareas));
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/sqlite_tareas_repository.dart';
import 'package:gestor_tareas_local/models/tarea.dart';

/// Prueba de SQLite real sobre un archivo: cierra y vuelve a abrir la base para
/// comprobar que los datos sobreviven, igual que al cerrar/reabrir la app.
void main() {
  late Directory directorio;
  late File archivo;

  setUp(() async {
    directorio = await Directory.systemTemp.createTemp('gestor_tareas_test_');
    archivo = File('${directorio.path}${Platform.pathSeparator}db.sqlite');
  });

  tearDown(() async {
    if (directorio.existsSync()) {
      directorio.deleteSync(recursive: true);
    }
  });

  SqliteTareasRepository abrirRepositorio() =>
      SqliteTareasRepository(AppDatabase(NativeDatabase(archivo)));

  test('CRUD persiste tras cerrar y reabrir el archivo SQLite', () async {
    var repositorio = abrirRepositorio();

    // P1: tres altas y lectura tras reapertura.
    await repositorio.agregarTarea('Comprar leche');
    await repositorio.agregarTarea('Hacer la práctica');
    await repositorio.agregarTarea('Llamar a casa');
    await repositorio.close();

    repositorio = abrirRepositorio();
    List<Tarea> tareas = await repositorio.watchTareas().first;
    expect(tareas.map((t) => t.titulo), [
      'Comprar leche',
      'Hacer la práctica',
      'Llamar a casa',
    ]);
    expect(tareas.every((t) => !t.completada), isTrue);

    final id = tareas[1].id;
    final idEliminado = tareas[2].id;

    // P2: estado.
    await repositorio.cambiarEstado(id, true);

    // P3: edición de título.
    await repositorio.actualizarTitulo(id, 'Hacer la práctica SQLite');

    // P4: eliminación.
    await repositorio.eliminarTarea(idEliminado);

    await repositorio.close();

    repositorio = abrirRepositorio();
    tareas = await repositorio.watchTareas().first;
    expect(tareas, hasLength(2));
    expect(
      tareas.firstWhere((t) => t.id == id).titulo,
      'Hacer la práctica SQLite',
    );
    expect(tareas.firstWhere((t) => t.id == id).completada, isTrue);
    expect(tareas.any((t) => t.id == idEliminado), isFalse);
    await repositorio.close();
  });

  test('Valida entradas y falla con ID inexistente', () async {
    final repositorio = abrirRepositorio();
    addTearDown(repositorio.close);

    expect(repositorio.agregarTarea('   '), throwsArgumentError);
    expect(repositorio.actualizarTitulo(1, ''), throwsArgumentError);
    expect(repositorio.eliminarTarea(999), throwsStateError);

    final tareas = await repositorio.watchTareas().first;
    expect(tareas, isEmpty);
  });
}

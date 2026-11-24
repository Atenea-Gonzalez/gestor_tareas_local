import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tareas_table.dart';

part 'app_database.g.dart';

/// Base SQLite única para las seis plataformas.
///
/// En nativo, `drift_flutter` crea `gestor_tareas.sqlite` en el directorio de
/// documentos de la app. En web, usa WebAssembly + un worker y guarda los datos
/// en el almacenamiento local del navegador para el mismo origen y perfil.
@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }

  @override
  int get schemaVersion => 1;
}

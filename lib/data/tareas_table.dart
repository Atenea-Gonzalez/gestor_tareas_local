import 'package:drift/drift.dart';

/// Tabla SQLite de tareas. El ID autoincremental identifica cada registro.
@DataClassName('TareaRow')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get titulo => text().withLength(min: 1, max: 200)();

  /// SQLite no tiene booleano nativo: 0 = pendiente, 1 = completada.
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

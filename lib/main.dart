import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'data/sqlite_tareas_repository.dart';
import 'data/tareas_repository.dart';
import 'screens/tareas_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = SqliteTareasRepository(AppDatabase());
  runApp(GestorTareasApp(repository: repository));
}

/// Punto de entrada de la aplicación. El repositorio se inyecta para poder
/// sustituirlo por un doble en las pruebas de widgets.
class GestorTareasApp extends StatelessWidget {
  const GestorTareasApp({super.key, required this.repository});

  final TareasRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(repository: repository),
    );
  }
}

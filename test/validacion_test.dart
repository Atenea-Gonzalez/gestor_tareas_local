import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/main.dart';

import 'helpers/fake_tareas_repository.dart';

void main() {
  testWidgets(
    'Rechaza títulos vacíos o de solo espacios (P5)',
    (tester) async {
      final repositorio = FakeTareasRepository();
      addTearDown(repositorio.close);
      await tester.pumpWidget(GestorTareasApp(repository: repositorio));

      for (final titulo in ['', '   ', '\t\n']) {
        await tester.enterText(find.byType(TextField), titulo);
        await tester.tap(find.text('Agregar tarea'));
        await tester.pumpAndSettle();
        expect(
          find.text('El título no puede estar vacío'),
          findsOneWidget,
          reason: 'El título «$titulo» debió ser rechazado',
        );
      }

      expect(repositorio.tareas, isEmpty);
      expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
      expect(find.text('Tarea guardada'), findsNothing);
    },
  );

  testWidgets(
    'Una tarea válida aparece en la lista y normaliza el título',
    (tester) async {
      final repositorio = FakeTareasRepository();
      addTearDown(repositorio.close);
      await tester.pumpWidget(GestorTareasApp(repository: repositorio));

      await tester.enterText(find.byType(TextField), '  Estudiar SQLite  ');
      await tester.tap(find.text('Agregar tarea'));
      await tester.pumpAndSettle();

      expect(repositorio.tareas, hasLength(1));
      expect(repositorio.tareas.single.titulo, 'Estudiar SQLite');
      expect(find.text('Estudiar SQLite'), findsOneWidget);
      expect(find.text('Tarea guardada'), findsOneWidget);
      expect(find.text('ID: 1 · Pendiente'), findsOneWidget);
    },
  );
}

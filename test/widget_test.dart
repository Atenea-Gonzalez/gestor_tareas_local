import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/main.dart';

import 'helpers/fake_tareas_repository.dart';

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    final repositorio = FakeTareasRepository();
    addTearDown(repositorio.close);

    await tester.pumpWidget(GestorTareasApp(repository: repositorio));
    await tester.pumpAndSettle();
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
  });
}

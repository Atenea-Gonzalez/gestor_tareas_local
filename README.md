# Gestor de tareas locales con SQLite

Práctica de **Programación de Dispositivos Móviles** — persistencia local
multiplataforma con Flutter. La app guarda tareas en SQLite local: alta,
consulta, edición de título, cambio de estado y eliminación. No hay servidor,
API REST ni MySQL; cada instalación conserva sus propios datos.

## Ejecutar y verificar

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d chrome        # o: flutter run -d windows
flutter build web --release
```

En web, los recursos `web/sqlite3.wasm` y `web/drift_worker.dart.js` deben
servirse desde la raíz de la app. `flutter run` envía el MIME
`application/wasm` correcto; un servidor propio debe configurarlo también.
Opcionalmente se pueden añadir las cabeceras
`Cross-Origin-Opener-Policy: same-origin` y
`Cross-Origin-Embedder-Policy: require-corp` para usar OPFS en navegadores
compatibles; sin ellas Drift usa IndexedDB y sigue persistiendo.

## Decisión tecnológica (investigación I1–I4, I6)

Elegí **Drift 2.35.4 + drift_flutter 0.3.1** (versiones fijadas en
`pubspec.lock`) porque una sola capa Dart abre una base SQLite real en las seis
plataformas. `drift_flutter` decide la ruta nativa (`gestor_tareas.sqlite` en
el directorio de documentos de la app) y, en web, configura `WasmDatabase`.
`drift_dev` + `build_runner` generan los companions y el código de tabla a
partir de anotaciones; por eso `lib/data/app_database.g.dart` está versionado.

- Una `List` en memoria se pierde al reiniciar el proceso; SQLite persiste en
  un archivo (o en el almacenamiento del navegador). Por eso las pruebas
  cierran y reabren la base.
- SQLite representa el ID como `INTEGER PRIMARY KEY AUTOINCREMENT`, el título
  como `TEXT NOT NULL` y el booleano como `INTEGER` (0/1). Drift genera
  `INSERT`, `SELECT`, `UPDATE` y `DELETE` tipados desde methods Dart.
- WebAssembly es necesario porque el navegador no trae sqlite3: el módulo
  `sqlite3.wasm` ejecuta SQLite y `drift_worker.dart.js` aloja la base en un
  worker. Ambos se descargaron del release `drift-2.35.4` del repo oficial.
- La UI usa `watch()` (stream reactivo, I5): nunca consulta la base en
  `build()`. El repositorio inyecta el `QueryExecutor`, por lo que las pruebas
  pueden abrir un archivo temporal o un doble en memoria.

## Organización

| Archivo | Responsabilidad |
|---|---|
| `lib/models/tarea.dart` | entidad inmutable `id`, `titulo`, `completada` |
| `lib/data/tareas_table.dart` | tabla Drift con validación de longitud |
| `lib/data/app_database.dart` | base persistente multiplataforma, `schemaVersion = 1` |
| `lib/data/app_database.g.dart` | código generado (companions, mapeos) |
| `lib/data/tareas_repository.dart` | contrato consumido por la UI |
| `lib/data/sqlite_tareas_repository.dart` | CRUD, validación y consulta reactiva |
| `lib/screens/tareas_page.dart` | interfaz; muestra errores y estados |
| `test/` | 5 pruebas: inicio, validación, alta y persistencia SQLite |

### Esquema de `tareas`

| Columna | Tipo SQLite | Regla |
|---|---|---|
| `id` | `INTEGER PRIMARY KEY AUTOINCREMENT` | identifica cada fila |
| `titulo` | `TEXT NOT NULL` | 1–200 caracteres (se recorta con `trim`) |
| `completada` | `INTEGER NOT NULL DEFAULT 0` | 0 pendiente, 1 completada |

## Plataformas (I7)

| Plataforma | Estado | Dónde queda la base |
|---|---|---|
| Windows | código previsto; compilación bloqueada en este equipo por falta de Developer Mode (symlinks de plugins). Persistencia nativa verificada con `NativeDatabase` en Windows dentro de `flutter test`. | `Application Documents/gestor_tareas.sqlite` |
| Web (Chrome) | **ejecutada**: CRUD y persistencia comprobados | OPFS/IndexedDB del origen y perfil del navegador |
| Android | prevista (mismo código; `sqlite3_flutter_libs`) | directorio de documentos de la app |
| iOS | prevista; requiere macOS + Xcode | directorio de documentos de la app |
| Linux | prevista; requiere Linux | `~/.local/share` de la app |
| macOS | prevista; requiere macOS + Xcode | `~/Library/Application Support` |

Modo privado o borrar datos del sitio elimina la base web; no hay
sincronización entre dispositivos (I8: solo cerrar/reabrir y reiniciar prueban
persistencia; hot reload no).

## Pruebas P1–P6

| ID | Resultado | Evidencia |
|---|---|---|
| P1 | 3 tareas agregadas, persisten tras cerrar/reabrir | `test/persistencia_test.dart`; web: 3 tareas visibles tras cerrar y abrir pestaña |
| P2 | estado completada conservado | prueba SQLite tras reapertura; web: checkbox `checked=true` |
| P3 | título editado conservado | prueba SQLite tras reapertura; web: «Hacer la práctica SQLite» |
| P4 | tarea eliminada no reaparece | prueba SQLite tras reapertura; web: ID 4 ausente |
| P5 | título vacío/espacios rechazado | `test/validacion_test.dart`; web: snackbar «El título no puede estar vacío» |
| P6 | datos web intactos tras recargar y tras cerrar/abrir pestaña | Chrome sobre `http://localhost:8081`, mismo perfil |

`flutter test` → **5/5 pruebas en verde**. `flutter analyze` → sin issues.
`flutter build web --release` → correcto.

### Dificultad real encontrada

En la primera ejecución de `flutter test`, la pantalla se quedaba en el
indicador de carga y `pumpAndSettle` agotaba el tiempo: el doble del
repositorio usaba un `StreamController.broadcast()` que no emitía ningún
evento inicial. Se corrigió haciendo que `watchTareas()` emitiera primero el
estado actual y luego el broadcast. En web, además, hacían falta los archivos
del release exacto de Drift; con la versión equivocada el worker no coincide.
Durante las pruebas de pestañas se observó que el storage `sharedIndexedDb`
mantiene un shared worker vivo: con varias pestañas abiertas, una nueva
instancia podía quedar esperando, por lo que la verificación final se hizo
cerrando la pestaña anterior antes de abrir la siguiente.

## Fuentes

- [Drift — documentación general](https://drift.simonbinder.eu/): justificó el ORM tipado y el uso de `build_runner`.
- [Drift en web](https://drift.simonbinder.eu/platforms/web/): explicó `sqlite3.wasm`, `drift_worker.dart.js`, OPFS/IndexedDB y las cabeceras COOP/COEP.
- [drift_flutter en pub.dev](https://pub.dev/packages/drift_flutter): mostró que `driftDatabase()` unifica nativo y web.
- [Flutter — SQLite local](https://docs.flutter.dev/cookbook/persistence/sqlite): comparó la lista en memoria con la base persistente.
- [Flutter — pruebas](https://docs.flutter.dev/testing/overview): base para `testWidgets` y pruebas de integración con archivo temporal.

## Uso de IA

Se usó **OpenCode (modelo Big Pickle)** como apoyo para revisar la consigna y
la documentación oficial, proponer la estructura de archivos y revisar las
pruebas. Yo verifiqué por mi cuenta `flutter analyze`, `flutter test`,
`flutter build web --release` y la ejecución en Chrome; corregí los errores
reales del stream inicial y de la descarga de los recursos web. El código y
los resultados fueron comprobados localmente antes de subirlos.

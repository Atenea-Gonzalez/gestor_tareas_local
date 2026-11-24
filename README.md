# Gestor de tareas locales con SQLite

Práctica de **Programación de Dispositivos Móviles** — persistencia local
multiplataforma con Flutter. La aplicación permite agregar, consultar, editar,
marcar como completada y eliminar tareas. No hay servidor, API REST ni MySQL:
cada instalación guarda sus propios datos.

## Etapa 1: decisión de persistencia

Elegí **Drift + `drift_flutter`** porque permiten escribir una sola capa de
datos en Dart y abrir una base SQLite real en Android, iOS, Windows, Linux,
macOS y web. `drift_flutter` resuelve la ruta del archivo en nativo y configura
el motor WebAssembly en el navegador; con eso evito conditional imports
manuales y mantengo un único `QueryExecutor` inyectable.

- `drift`: ORM asíncrono con consultas tipadas, streams reactivos y migraciones.
- `drift_flutter`: abre la base persistente en todas las plataformas.
- `drift_dev` + `build_runner`: generan el código de tablas/companions a partir
  de anotaciones; se ejecutan con
  `dart run build_runner build --delete-conflicting-outputs`.
- En web se agregan `sqlite3.wasm` y `drift_worker.dart.js` a `web/` para que
  el navegador pueda ejecutar SQLite y alojar la base en un worker.

### Esquema previsto

| Columna | Tipo SQLite | Regla |
|---|---|---|
| `id` | `INTEGER PRIMARY KEY AUTOINCREMENT` | identifica cada fila |
| `titulo` | `TEXT NOT NULL` | no vacío (1..200 caracteres) |
| `completada` | `INTEGER NOT NULL DEFAULT 0` | booleano: 0 pendiente, 1 completada |

La interfaz no ejecutará SQL: consultará un repositorio que expondrá un
`Stream<List<Tarea>>`, de modo que la UI se reconstruya sola tras cada escritura
sin consultar la base dentro de `build()`.

## Estado del trabajo

- [x] Etapa 1 — proyecto base ejecutable y decisión tecnológica documentada.
- [ ] Etapa 2 — apertura de la base, alta y consulta persistentes.
- [ ] Etapa 3 — edición, cambio de estado, eliminación y validación.
- [ ] Etapa 4 — web, pruebas automatizadas y evidencias.

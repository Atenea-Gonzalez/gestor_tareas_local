"""Genera el reporte PDF (maximo 2 paginas) de la practica SQLite."""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

SALIDA = Path(__file__).parent / "Reporte_Practica_SQLite.pdf"

styles = getSampleStyleSheet()
base = ParagraphStyle(
    "base",
    parent=styles["BodyText"],
    fontName="Helvetica",
    fontSize=8.3,
    leading=10.6,
    alignment=TA_JUSTIFY,
    spaceAfter=5,
)
titulo = ParagraphStyle(
    "titulo",
    parent=styles["Title"],
    fontName="Helvetica-Bold",
    fontSize=14,
    leading=16,
    spaceAfter=2,
)
subtitulo = ParagraphStyle(
    "subtitulo",
    parent=base,
    fontSize=8,
    textColor=colors.HexColor("#444444"),
    alignment=0,
    spaceAfter=8,
)
h = ParagraphStyle(
    "h",
    parent=base,
    fontName="Helvetica-Bold",
    fontSize=9.6,
    leading=11,
    spaceBefore=7,
    spaceAfter=3,
)
celda = ParagraphStyle("celda", parent=base, fontSize=7.5, leading=9, alignment=0, spaceAfter=0)
celdaHead = ParagraphStyle("celdaHead", parent=celda, fontName="Helvetica-Bold")


def tabla(datos, anchos):
    t = Table(datos, colWidths=anchos, repeatRows=1, hAlign="LEFT")
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E8EAF6")),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 7.5),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#9E9E9E")),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 2.5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5),
            ]
        )
    )
    return t


def P(texto, estilo=celda):
    return Paragraph(texto, estilo)


historia = []
historia.append(Paragraph("Práctica: Gestor de tareas con SQLite", titulo))
historia.append(
    Paragraph(
        "Atenea Gonzalez · Programación de Dispositivos Móviles, 7.º semestre · "
        "Repositorio: gestor_tareas_local (Flutter 3.47.9 / Dart 3.13.7)",
        subtitulo,
    )
)

historia.append(Paragraph("1. Qué se implementó y organización de la persistencia", h))
historia.append(
    Paragraph(
        "Aplicación Flutter con SQLite <b>local real</b> (sin servidor, API REST ni MySQL) "
        "que permite agregar, listar, editar el título, marcar como completada y eliminar "
        "tareas. Se usó <b>Drift 2.35.4 + drift_flutter 0.3.1</b> porque una sola capa Dart "
        "abre la base en Android, iOS, Windows, Linux, macOS y web. La capa de datos está en "
        "<font face='Courier'>lib/data/</font>: <i>tareas_table.dart</i> define la tabla, "
        "<i>app_database.dart</i> abre la conexión persistente, "
        "<i>sqlite_tareas_repository.dart</i> concentra INSERT/SELECT/UPDATE/DELETE y "
        "validaciones, y <i>tareas_repository.dart</i> es el contrato que consume la UI. "
        "El código generado <i>app_database.g.dart</i> también está versionado. La pantalla "
        "usa la consulta reactiva <font face='Courier'>watch()</font>: no ejecuta SQL dentro "
        "de build() y muestra mensajes de error comprensibles. El executor es inyectable, lo "
        "que permite probar con un archivo SQLite temporal.",
        base,
    )
)
historia.append(
    tabla(
        [
            [P("Columna", celdaHead), P("Tipo SQLite", celdaHead), P("Regla", celdaHead)],
            [P("id"), P("INTEGER PRIMARY KEY AUTOINCREMENT"), P("identifica cada registro")],
            [P("titulo"), P("TEXT NOT NULL"), P("1–200 caracteres; se aplica trim")],
            [P("completada"), P("INTEGER NOT NULL DEFAULT 0"), P("booleano: 0 pendiente, 1 completada")],
        ],
        [2.6 * cm, 6.4 * cm, 8.0 * cm],
    )
)

historia.append(Paragraph("2. Dificultad técnica real, investigación y verificación", h))
historia.append(
    Paragraph(
        "En el primer <font face='Courier'>flutter test</font>, la interfaz se quedó en el "
        "indicador de carga y <font face='Courier'>pumpAndSettle</font> agotó el tiempo. "
        "Causa: el doble del repositorio usaba un "
        "<font face='Courier'>StreamController.broadcast()</font> sin evento inicial, así que "
        "el StreamBuilder nunca salía del estado <i>waiting</i>. Lo corregí emitiendo primero "
        "el estado actual y luego el broadcast; las 5 pruebas quedaron en verde. En web, Drift "
        "exige <font face='Courier'>sqlite3.wasm</font> y un worker compilados de la "
        "<b>misma versión</b> del paquete; descargué ambos del release oficial "
        "<i>drift-2.35.4</i>. Al probar con varias pestañas, el storage "
        "<i>sharedIndexedDb</i> mantuvo un shared worker vivo y una nueva instancia podía "
        "quedar esperando; la verificación final se hizo cerrando la pestaña anterior antes "
        "de abrir la siguiente. Esto quedó documentado como limitación.",
        base,
    )
)

historia.append(Paragraph("3. Plataformas ejecutadas y pruebas P1–P6", h))
historia.append(
    Paragraph(
        "<b>Ejecutadas:</b> Chrome/web (CRUD y persistencia comprobados en el navegador) y "
        "Windows nativo (la persistencia se validó con <font face='Courier'>NativeDatabase"
        "</font> sobre un archivo real dentro de <font face='Courier'>flutter test</font>; el "
        "build del ejecutable Windows se bloqueó en este equipo por falta de Developer Mode "
        "para symlinks de plugins). <b>Previstas:</b> Android, iOS, Linux y macOS: comparten "
        "la misma base de código, pero no se compilaron aquí (iOS/macOS requieren Xcode).",
        base,
    )
)
historia.append(
    tabla(
        [
            [P("ID", celdaHead), P("Acción", celdaHead), P("Resultado y evidencia", celdaHead)],
            [P("P1"), P("3 altas + cerrar/abrir"), P("Permanecen: prueba SQLite y web (3 tareas visibles tras cerrar pestaña).")],
            [P("P2"), P("Marcar completada + reiniciar"), P("Estado conservado: checkbox en true tras reapertura.")],
            [P("P3"), P("Editar título + reiniciar"), P("Aparece «Hacer la práctica SQLite».")],
            [P("P4"), P("Eliminar + reiniciar"), P("El ID eliminado no reaparece.")],
            [P("P5"), P("Título vacío/espacios"), P("Rechazado: snackbar «El título no puede estar vacío».")],
            [P("P6"), P("Web: recargar y cerrar/abrir pestaña"), P("Datos intactos en el mismo origen y perfil (Chrome, localhost:8081).")],
        ],
        [1.0 * cm, 5.0 * cm, 11.0 * cm],
    )
)
historia.append(
    Paragraph(
        "Verificación reproducible: <font face='Courier'>flutter analyze</font> sin issues; "
        "<font face='Courier'>flutter test</font> 5/5; "
        "<font face='Courier'>flutter build web --release</font> correcto. Limitaciones: en el "
        "modo privado del navegador o al borrar datos del sitio se pierde la base web; no hay "
        "sincronización entre dispositivos; la segunda recarga en el navegador de pruebas "
        "headless fue inestable por el shared worker indicado.",
        base,
    )
)

historia.append(Paragraph("4. Resumen de la investigación (I1–I8)", h))
historia.append(
    Paragraph(
        "I1: una List muere con el proceso; SQLite persiste. I2: ID entero autoincremental, "
        "título TEXT, booleano INTEGER 0/1; INSERT/SELECT/UPDATE/DELETE son las operaciones "
        "de escritura/lectura. I3: Drift + drift_flutter unifican plataformas con consultas "
        "tipadas. I4: build_runner genera companions y mapeos a partir de anotaciones; la base "
        "se abre de forma asíncrona con schemaVersion 1. I5: elegí un Stream reactivo para "
        "actualizar la UI tras cada escritura sin recargar manualmente. I6: el navegador no "
        "incluye sqlite3, por eso se necesitan WebAssembly y un worker de la versión "
        "compatible. I7: en nativo, archivo en el directorio de documentos de la app; en web, "
        "OPFS/IndexedDB ligados al origen y perfil. I8: hot reload no prueba persistencia; "
        "sí la prueban reiniciar, cerrar/abrir la app o la pestaña; desinstalar o limpiar el "
        "sitio borra los datos.",
        base,
    )
)

historia.append(Paragraph("5. Fuentes utilizadas", h))
historia.append(
    Paragraph(
        "<b>Drift general</b> (https://drift.simonbinder.eu/): me mostró las consultas tipadas "
        "y el papel de build_runner. <b>Drift en web</b> "
        "(https://drift.simonbinder.eu/platforms/web/): explicó sqlite3.wasm, el worker, "
        "OPFS/IndexedDB y las cabeceras COOP/COEP. <b>drift_flutter</b> "
        "(https://pub.dev/packages/drift_flutter): permitió un único "
        "<font face='Courier'>driftDatabase()</font> para las seis plataformas. "
        "<b>Flutter SQLite</b> (https://docs.flutter.dev/cookbook/persistence/sqlite): "
        "aclaró la diferencia entre memoria y base persistente. <b>Flutter testing</b> "
        "(https://docs.flutter.dev/testing/overview): base para las pruebas de widgets y de "
        "archivo temporal.",
        base,
    )
)

historia.append(Paragraph("6. Uso de IA", h))
historia.append(
    Paragraph(
        "Utilicé <b>OpenCode (modelo Big Pickle)</b> como apoyo para revisar la consigna y la "
        "documentación oficial, proponer la estructura de archivos y revisar el código y las "
        "pruebas. Verifiqué por mi cuenta con flutter analyze, flutter test, el build web y la "
        "ejecución en Chrome, y corregí los errores reales del stream inicial y de los "
        "recursos web. No se entregó una respuesta generada sin comprobación local.",
        base,
    )
)

doc = SimpleDocTemplate(
    str(SALIDA),
    pagesize=A4,
    leftMargin=1.5 * cm,
    rightMargin=1.5 * cm,
    topMargin=1.3 * cm,
    bottomMargin=1.3 * cm,
    title="Reporte Practica SQLite",
    author="Atenea Gonzalez",
)
doc.build(historia)
print(f"Generado: {SALIDA}")

import 'package:flutter/material.dart';

import '../data/tareas_repository.dart';
import '../models/tarea.dart';

/// Pantalla de tareas. No contiene SQL: solo habla con [TareasRepository].
class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.repository});

  final TareasRepository repository;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  late final Stream<List<Tarea>> _tareasStream;

  @override
  void initState() {
    super.initState();
    // La consulta reactiva se crea una sola vez, nunca dentro de build().
    _tareasStream = widget.repository.watchTareas();
  }

  Future<void> _agregarTarea() async {
    final titulo = _tituloController.text;
    FocusScope.of(context).unfocus();
    try {
      await widget.repository.agregarTarea(titulo);
      if (!mounted) return;
      _tituloController.clear();
      _mostrarMensaje('Tarea guardada');
    } catch (error) {
      _mostrarError(error);
    }
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    try {
      await widget.repository.cambiarEstado(tarea.id, completada);
    } catch (error) {
      _mostrarError(error);
    }
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final controlador = TextEditingController(text: tarea.titulo);
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Editar título'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Título',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (valor) => Navigator.pop(contexto, valor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, controlador.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controlador.dispose();

    if (nuevoTitulo == null) return;
    try {
      await widget.repository.actualizarTitulo(tarea.id, nuevoTitulo);
      if (!mounted) return;
      _mostrarMensaje('Título actualizado');
    } catch (error) {
      _mostrarError(error);
    }
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar «${tarea.titulo}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await widget.repository.eliminarTarea(tarea.id);
      if (!mounted) return;
      _mostrarMensaje('Tarea eliminada');
    } catch (error) {
      _mostrarError(error);
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _mostrarError(Object error) {
    String mensaje;
    if (error is ArgumentError) {
      mensaje = error.message.toString();
    } else if (error is StateError) {
      mensaje = error.message;
    } else {
      mensaje = 'No se pudo completar la operación: $error';
    }
    _mostrarMensaje(mensaje);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _agregarTarea(),
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Tarea>>(
                stream: _tareasStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al leer la base: ${snapshot.error}'),
                    );
                  }
                  final tareas = snapshot.data ?? const <Tarea>[];
                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }
                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: tarea.completada,
                            onChanged: (valor) {
                              if (valor != null) {
                                _alternarCompletada(tarea, valor);
                              }
                            },
                          ),
                          title: Text(tarea.titulo),
                          subtitle: Text(
                            'ID: ${tarea.id} · '
                            '${tarea.completada ? 'Completada' : 'Pendiente'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarTarea(tarea),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _eliminarTarea(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

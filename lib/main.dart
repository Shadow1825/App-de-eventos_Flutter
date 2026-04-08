import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(MyApp());
}

class Evento {
  String nombre, lugar, fecha, hora, tipo;

  Evento(this.nombre, this.lugar, this.fecha, this.hora, this.tipo);

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'lugar': lugar,
    'fecha': fecha,
    'hora': hora,
    'tipo': tipo,
  };

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      json['nombre'],
      json['lugar'],
      json['fecha'],
      json['hora'],
      json['tipo'],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ListaEventos(),
    );
  }
}

class ListaEventos extends StatefulWidget {
  @override
  _ListaEventosState createState() => _ListaEventosState();
}

class _ListaEventosState extends State<ListaEventos> {
  List<Evento> eventos = [];

  @override
  void initState() {
    super.initState();
    cargarEventos();
  }

  Future<void> guardarEventos() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('eventos', jsonEncode(eventos));
  }

  Future<void> cargarEventos() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('eventos');

    if (data != null) {
      List decoded = jsonDecode(data);
      eventos = decoded.map((e) => Evento.fromJson(e)).toList();
      setState(() {});
    }
  }

  void irCrear({Evento? evento, int? index}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearEvento(evento: evento),
      ),
    );

    if (resultado != null) {
      setState(() {
        if (index != null) {
          eventos[index] = resultado;
        } else {
          eventos.add(resultado);
        }
      });
      guardarEventos();
    }
  }

  Color getColor(String tipo) {
    switch (tipo) {
      case "Cumpleaños":
        return Colors.cyan;
      case "Reunión":
        return Colors.grey;
      case "Salida":
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData getIcon(String tipo) {
    switch (tipo) {
      case "Cumpleaños":
        return Icons.cake;
      case "Reunión":
        return Icons.work;
      case "Salida":
        return Icons.park;
      default:
        return Icons.calendar_today;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Eventos")),
      body: ListView.builder(
        itemCount: eventos.length,
        itemBuilder: (context, i) {
          final e = eventos[i];

          return Card(
            color: getColor(e.tipo),
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(getIcon(e.tipo), size: 28),
                      SizedBox(width: 8),
                      Text(e.tipo,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(e.nombre, style: TextStyle(fontSize: 20)),
                  Text("${e.fecha} - ${e.hora}"),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.share),
                        onPressed: () {
                          Share.share(
                              "${e.nombre}\n${e.lugar}\n${e.fecha} ${e.hora}");
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.map),
                        onPressed: () async {
                          final url = Uri.parse(
                              "https://www.google.com/maps/search/?api=1&query=${e.lugar}");
                          await launchUrl(url);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => irCrear(evento: e, index: i),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Eliminar evento"),
                              content: Text(
                                  "¿Seguro que quieres eliminar este evento?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Cancelar"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      eventos.removeAt(i);
                                    });
                                    guardarEventos();
                                    Navigator.pop(context);
                                  },
                                  child: Text("Eliminar"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => irCrear(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class CrearEvento extends StatefulWidget {
  final Evento? evento;

  CrearEvento({this.evento});

  @override
  _CrearEventoState createState() => _CrearEventoState();
}

class _CrearEventoState extends State<CrearEvento> {
  final nombre = TextEditingController();
  final lugar = TextEditingController();
  final fecha = TextEditingController();
  final hora = TextEditingController();

  String tipo = "Cumpleaños";

  @override
  void initState() {
    super.initState();

    if (widget.evento != null) {
      nombre.text = widget.evento!.nombre;
      lugar.text = widget.evento!.lugar;
      fecha.text = widget.evento!.fecha;
      hora.text = widget.evento!.hora;
      tipo = widget.evento!.tipo;
    }
  }

  void guardar() {
    if (nombre.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Nombre obligatorio")));
      return;
    }

    Navigator.pop(
      context,
      Evento(
        nombre.text,
        lugar.text,
        fecha.text,
        hora.text,
        tipo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crear / Editar Evento")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: nombre,
                decoration: InputDecoration(labelText: "Nombre")),
            TextField(
                controller: lugar,
                decoration: InputDecoration(labelText: "Lugar")),

            // DATE PICKER
            TextField(
              controller: fecha,
              readOnly: true,
              decoration: InputDecoration(labelText: "Fecha"),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  fecha.text =
                  "${picked.day}/${picked.month}/${picked.year}";
                }
              },
            ),

            // TIME PICKER
            TextField(
              controller: hora,
              readOnly: true,
              decoration: InputDecoration(labelText: "Hora"),
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (picked != null) {
                  hora.text = picked.format(context);
                }
              },
            ),

            DropdownButton<String>(
              value: tipo,
              isExpanded: true,
              items: ["Cumpleaños", "Reunión", "Salida", "Otro"]
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => tipo = v!),
            ),

            SizedBox(height: 20),
            ElevatedButton(onPressed: guardar, child: Text("Guardar"))
          ],
        ),
      ),
    );
  }
}
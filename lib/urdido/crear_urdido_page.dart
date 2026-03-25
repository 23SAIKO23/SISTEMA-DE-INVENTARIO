import 'package:flutter/material.dart';
import 'urdido_models.dart';
import 'matriz_visual_widget.dart';

const cRojo = Color(0xFFE11D48);
const cNegro = Color(0xFF0F172A);
const cVerde = Color(0xFF059669);
const cBlanco = Color(0xFFF8FAFC);
const cVacio = Color(0xFF334155); // Color gris oscuro para "vacío"

class CrearUrdidoPage extends StatefulWidget {
  final Armada? armadaEdicion;
  
  const CrearUrdidoPage({super.key, this.armadaEdicion});

  @override
  State<CrearUrdidoPage> createState() => _CrearUrdidoPageState();
}

class _CrearUrdidoPageState extends State<CrearUrdidoPage> {
  final _tituloCtrl = TextEditingController(text: 'Nueva Armada');
  final _repeticionesCtrl = TextEditingController(text: '1');
  final _posicionesCtrl = TextEditingController(text: 'U1');
  
  int _repeticiones = 1;
  String _posiciones = 'U1';

  List<Color> _paleta = [
    cRojo, cVerde, cBlanco, cNegro, 
    Colors.orange, Colors.purple, Colors.blue, Colors.yellow
  ];
  
  Color _colorSeleccionado = cRojo;
  late List<List<Color>> _matrizActual;

  @override
  void initState() {
    super.initState();
    if (widget.armadaEdicion != null) {
      _tituloCtrl.text = widget.armadaEdicion!.titulo;
      _repeticiones = widget.armadaEdicion!.repeticiones;
      _posiciones = widget.armadaEdicion!.posicionesUrdidor.join(', ');
      
      _repeticionesCtrl.text = _repeticiones.toString();
      _posicionesCtrl.text = _posiciones;
      
      // Copiar la matriz para no alterar la original hasta guardar
      _matrizActual = widget.armadaEdicion!.matrizHilos
          .map((row) => List<Color>.from(row))
          .toList();
    } else {
      // Inicializar matriz vacía (gris)
      _matrizActual = List.generate(
        10, (_) => List.generate(6, (_) => cVacio)
      );
    }
  }

  void _pintarCono(int r, int c) {
    setState(() {
      _matrizActual[r][c] = _colorSeleccionado;
    });
  }

  void _guardarArmada() {
    final armada = Armada(
      titulo: _tituloCtrl.text,
      descripcion: 'Armada personalizada creada desde la app',
      repeticiones: _repeticiones,
      posicionesUrdidor: _posiciones.split(',').map((e) => e.trim()).toList(),
      matrizHilos: _matrizActual,
    );
    Navigator.pop(context, armada);
  }

  void _agregarColorLibre() {
    List<Color> allColors = [];
    for (var primary in Colors.primaries) {
      allColors.addAll([primary[300]!, primary, primary[700]!, primary[900]!]);
    }
    for (var accent in Colors.accents) {
      allColors.addAll([accent[100]!, accent, accent[700]!]);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Elegir Nuevo Color', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: allColors.map((c) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (!_paleta.contains(c)) _paleta.add(c);
                            _colorSeleccionado = c;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Pintar Nueva Armada', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
            onPressed: _guardarArmada,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Formulario simple
              TextField(
                controller: _tituloCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre de la Armada',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _repeticionesCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => _repeticiones = int.tryParse(val) ?? 1,
                      decoration: InputDecoration(
                        labelText: 'Repeticiones',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _posicionesCtrl,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => _posiciones = val,
                      decoration: InputDecoration(
                        labelText: 'Posiciones (Ej: U1, U3)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Paleta de Colores
              const Text('SELECCIONA UN COLOR (PINCEL)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ..._paleta.map((color) {
                    bool isSelected = _colorSeleccionado == color;
                    return GestureDetector(
                      onTap: () => setState(() => _colorSeleccionado = color),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)] : null,
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _agregarColorLibre,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lienzo interactivo
              const Text('TOCA PARA PINTAR CONOS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 12),
              MatrizFileteraWidget(
                matrizHilos: _matrizActual,
                conoSize: 18.0, // Tamaño cómodo para tocar con el dedo
                fontSize: 12.0,
                onConoTap: _pintarCono,
              ),
              const SizedBox(height: 40),
              
              ElevatedButton.icon(
                onPressed: _guardarArmada,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Guardar Secuencia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

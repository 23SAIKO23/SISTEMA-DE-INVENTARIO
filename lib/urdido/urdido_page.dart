import 'package:flutter/material.dart';
import 'urdido_models.dart';
import 'matriz_visual_widget.dart';
import 'crear_urdido_page.dart';

// Colores del Aguayo para la interfaz
const _kNaranja = Color(0xFFF97316); 
const _kNaranjaDark = Color(0xFFC2410C);
const _kFondo = Color(0xFF0F172A); // Slate 900
const _kFondoCard = Color(0xFF1E293B); // Slate 800

// Colores de hilo para el demo
const cRojo = Color(0xFFE11D48); // Rose 600
const cNegro = Color(0xFF0F172A); // Slate 900 (casi negro)
const cVerde = Color(0xFF059669); // Emerald 600
const cBlanco = Color(0xFFF8FAFC); // Slate 50

class UrdidoPage extends StatefulWidget {
  const UrdidoPage({super.key});

  @override
  State<UrdidoPage> createState() => _UrdidoPageState();
}

class _UrdidoPageState extends State<UrdidoPage> {
  // Datos quemados para la demostración del Modelo "Colorado"
  late RecetaUrdido recetaActual;

  @override
  void initState() {
    super.initState();
    _cargarModeloColorado();
  }

  void _cargarModeloColorado() {
    // Generar matrices 10 filas x 6 columnas

    // Armada 1: Toda roja
    List<List<Color>> matrizArmada1 = List.generate(
      10, (_) => List.generate(6, (_) => cRojo)
    );

    // Armada 2: Patrón Listado
    // Fila 1: N N B B N N
    // Fila 2: N V V V V N
    // Fila 3: B V R R V B
    // Fila 4: B V R R V B
    // Fila 5: N V V V V N
    // Fila 6: N B B B B N
    // Fila 7: N V V V V N
    // Fila 8: B V R R V B
    // Fila 9: B V R R V B
    // Fila 10:N N B B N N
    List<List<Color>> matrizArmada2 = [
      [cNegro, cNegro, cBlanco, cBlanco, cNegro, cNegro],
      [cNegro, cVerde, cVerde, cVerde, cVerde, cNegro],
      [cBlanco, cVerde, cRojo, cRojo, cVerde, cBlanco],
      [cBlanco, cVerde, cRojo, cRojo, cVerde, cBlanco],
      [cNegro, cVerde, cVerde, cVerde, cVerde, cNegro],
      [cNegro, cBlanco, cBlanco, cBlanco, cBlanco, cNegro],
      [cNegro, cVerde, cVerde, cVerde, cVerde, cNegro],
      [cBlanco, cVerde, cRojo, cRojo, cVerde, cBlanco],
      [cBlanco, cVerde, cRojo, cRojo, cVerde, cBlanco],
      [cNegro, cNegro, cBlanco, cBlanco, cNegro, cNegro],
    ];

    // Armada 3: Corazón Oscuro
    List<List<Color>> matrizArmada3 = List.generate(
      10, (_) => List.generate(6, (_) => cNegro)
    );

    recetaActual = RecetaUrdido(
      modelo: 'Colorado (Aguayo Clásico)',
      totalHilos: 600,
      anchoPeine: 60,
      armadas: [
        Armada(
          titulo: 'Armada 1: Guarda Roja Principal',
          descripcion: 'Franjas rojas gruesas y sólidas características del modelo colorado.',
          repeticiones: 4,
          posicionesUrdidor: ['U1', 'U2', 'U9', 'U10'],
          matrizHilos: matrizArmada1,
        ),
        Armada(
          titulo: 'Armada 2: Patrón Listado',
          descripcion: 'Lleva la figura geométrica o las trencillas combinando conos verdes, negros y crudos.',
          repeticiones: 4,
          posicionesUrdidor: ['U3', 'U5', 'U6', 'U8'],
          matrizHilos: matrizArmada2,
        ),
        Armada(
          titulo: 'Armada 3: Corazón Oscuro',
          descripcion: 'Franja central sólida oscura para dar equilibrio al diseño.',
          repeticiones: 2,
          posicionesUrdidor: ['U4', 'U7'],
          matrizHilos: matrizArmada3,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Secuencia de Urdido',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kNaranja,
        onPressed: () async {
          final nuevaArmada = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearUrdidoPage()),
          );
          if (nuevaArmada != null && nuevaArmada is Armada) {
            setState(() {
              recetaActual.armadas.add(nuevaArmada);
            });
          }
        },
        icon: const Icon(Icons.palette_rounded, color: Colors.white),
        label: const Text('Pintar Armada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kFondo, Color(0xFF0B1120)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeaderResumen(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: recetaActual.armadas.length,
                  itemBuilder: (context, index) {
                    return _buildArmadaCard(recetaActual.armadas[index], index + 1);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderResumen() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNaranja.withOpacity(0.2), _kNaranjaDark.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kNaranja.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kNaranja.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kNaranja.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grid_on_rounded, color: _kNaranja, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MODELO ACTUAL',
                      style: TextStyle(
                        color: _kNaranja.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recetaActual.modelo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDatoHeader('Total Hilos', '${recetaActual.totalHilos}'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildDatoHeader('Ancho Peine', '${recetaActual.anchoPeine}'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildDatoHeader('Armadas', '${recetaActual.armadas.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatoHeader(String label, String valor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildArmadaCard(Armada armada, int numero) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _kFondoCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la armada
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kNaranja,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Paso $numero',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    armada.titulo,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 18),
                  onPressed: () async {
                    final armadaEditada = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CrearUrdidoPage(armadaEdicion: armada)
                      ),
                    );
                    if (armadaEditada != null && armadaEditada is Armada) {
                      setState(() {
                        int idx = recetaActual.armadas.indexOf(armada);
                        if (idx != -1) {
                          recetaActual.armadas[idx] = armadaEditada;
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              armada.descripcion,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, height: 1.3),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Row layout para info y matriz
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info instrucciones
                Expanded(
                  child: Column(
                    children: [
                      _buildInstruccionBox(
                        icon: Icons.repeat_rounded,
                        label: 'Repeticiones',
                        value: '${armada.repeticiones} veces',
                      ),
                      const SizedBox(height: 12),
                      _buildInstruccionBox(
                        icon: Icons.push_pin_rounded,
                        label: 'Posiciones Urdidor',
                        value: armada.posicionesUrdidor.join('   -   '),
                        isAccented: true,
                      ),
                    ],
                  ),
                ),
                
                // Matriz Visual interactiva (ocupando su espacio natural exacto)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(20),
                        child: MatrizFileteraWidget(
                          matrizHilos: armada.matrizHilos,
                          conoSize: 24.0, // Tamaño gigante para el zoom
                          fontSize: 16.0,
                        ),
                      ),
                    );
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.zoomIn,
                    child: Tooltip(
                      message: 'Toca para agrandar',
                      child: MatrizFileteraWidget(matrizHilos: armada.matrizHilos),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInstruccionBox({
    required IconData icon, 
    required String label, 
    required String value,
    bool isAccented = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAccented ? _kNaranja.withOpacity(0.1) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccented ? _kNaranja.withOpacity(0.3) : Colors.white.withOpacity(0.05)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isAccented ? _kNaranja : Colors.white54),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isAccented ? _kNaranja : Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isAccented ? Colors.white : Colors.white.withOpacity(0.9),
              fontSize: isAccented ? 13 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

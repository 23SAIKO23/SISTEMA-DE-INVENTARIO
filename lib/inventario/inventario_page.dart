import 'package:flutter/material.dart';
import 'inventario_service.dart';
import 'inventario_voice_svc.dart';
import '../services/app_service.dart';
import '../produccion/produccion.dart';

// ── Colores del Módulo de Inventario ──────────────
const _kFondo = Color(0xFF0F172A); // Slate 900
const _kFondo2 = Color(0xFF1E293B); // Slate 800
const _kAccent = Color(0xFF38BDF8); // Light Blue 400
const _kVerde = Color(0xFF10B981); // Emerald 500
const _kRojo = Color(0xFFEF4444); // Red 500

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> with SingleTickerProviderStateMixin {
  final _inventarioSvc = InventarioService.instance;
  final _voiceSvc = InventarioVoiceService.instance;
  
  String _ultimaPalabra = '';
  String _respuestaVoz = '';
  bool _estaEscuchando = false;
  late AnimationController _pulseCtrl;
  final _chatCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inventarioSvc.addListener(_onUpdate);
    _voiceSvc.init();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _inventarioSvc.removeListener(_onUpdate);
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleVoz() async {
    if (_estaEscuchando) {
      await _voiceSvc.stopListening();
      setState(() => _estaEscuchando = false);
    } else {
      setState(() {
        _estaEscuchando = true;
        _ultimaPalabra = ''; // Limpiar antes de empezar
      });
      
      final bool iniciado = await _voiceSvc.startListening((texto) {
        setState(() {
          _ultimaPalabra = texto;
        });
      }, (respuesta) {
        setState(() {
          _respuestaVoz = respuesta;
          _estaEscuchando = false;
        });
        // Desaparecer la respuesta después de 6 segundos
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted && _respuestaVoz == respuesta) {
            setState(() => _respuestaVoz = '');
          }
        });
      });

      // Si falló el inicio
      if (!iniciado && mounted) {
        setState(() => _estaEscuchando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo iniciar el micrófono. Verifica los permisos de la aplicación.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _enviarChat(String texto) {
    if (texto.trim().isEmpty) return;
    final r = _voiceSvc.interpretarTexto(texto);
    setState(() {
      _respuestaVoz = r;
      _chatCtrl.clear();
    });
    // Autocerrar
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _respuestaVoz == r) {
        setState(() => _respuestaVoz = '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockMap = _inventarioSvc.inventarioActual;
    final colores = stockMap.keys.toList()..sort();
    int stockTotal = stockMap.values.fold(0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: _kFondo,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kFondo, _kFondo2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, stockTotal),
                  
                  // Tarjeta de Insights Inteligentes (Innovación)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildInsightsCard(),
                  ),
                  
                  if (colores.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text('Inventario Vacío', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Registra producciones para ver stock.', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildExcelTable(colores, stockMap),
                      ),
                    ),
                ],
              ),

              // Indicador de Voz flotante (MIENTRAS ESCUCHA)
              if (_estaEscuchando)
                Positioned(
                  bottom: 110,
                  left: 0, right: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_ultimaPalabra.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '"$_ultimaPalabra"',
                              style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 14),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: _kAccent.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: _kAccent.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 4)
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mic_rounded, color: Colors.white),
                              const SizedBox(width: 12),
                              const Text('Escuchando...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Ventana Emergente de Respuesta de IA (RESULTADO)
              if (_respuestaVoz.isNotEmpty && !_estaEscuchando)
                Positioned(
                  bottom: 100,
                  left: 20, right: 20,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kFondo2,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _kAccent.withValues(alpha: 0.5), width: 2),
                        boxShadow: [
                          BoxShadow(color: _kAccent.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _kAccent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, color: _kAccent, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('Asistente de Inventario', 
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                                onPressed: () => setState(() => _respuestaVoz = ''),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          Text(
                            _respuestaVoz,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          bool isShort = MediaQuery.of(context).size.width < 400;
          return ScaleTransition(
            scale: Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)),
            child: FloatingActionButton.extended(
              onPressed: _toggleVoz,
              backgroundColor: _estaEscuchando ? _kRojo : _kAccent,
              icon: Icon(_estaEscuchando ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white),
              label: Text(
                _estaEscuchando ? 'Parar' : (isShort ? 'Voz' : 'Preguntar Voz'), 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildExcelTable(List<String> colores, Map<String, int> stockMap) {
    final Map<String, int> prodMap = {};
    for (var m in ProduccionService.instance.maquinas) {
      for (var semana in m.historialProduccion) {
        semana.produccionPorColor.forEach((rawColor, cant) {
          final color = _inventarioSvc.normalizarColor(rawColor);
          prodMap[color] = (prodMap[color] ?? 0) + cant.toInt();
        });
      }
    }

    final Map<String, int> ventMap = {};
    for (var venta in AppService.instance.ventas) {
      if (venta.color.isNotEmpty && venta.color.toLowerCase() != 'sin color') {
        final color = _inventarioSvc.normalizarColor(venta.color);
        ventMap[color] = (ventMap[color] ?? 0) + venta.cantidad.toInt();
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100), // Espacio para el FAB
            itemCount: colores.length,
            itemBuilder: (context, index) {
              final c = colores[index];
              final prod = prodMap[c] ?? 0;
              final vent = ventMap[c] ?? 0;
              final stock = stockMap[c] ?? 0;
              bool enRiesgo = stock <= 5;
              final statusColor = enRiesgo ? _kRojo : _kVerde;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, 
                            color: statusColor,
                            boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 8)],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(c, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            enRiesgo ? 'REPOSICIÓN' : 'ESTABLE',
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat('Producido', '$prod', Colors.white54),
                        _buildStat('Vendido', '$vent', Colors.white54),
                        _buildStat('Stock', '$stock', enRiesgo ? _kRojo : _kAccent, isBig: true),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.architecture_rounded, color: _kAccent, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _inventarioSvc.formatearCortes(stock),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9), 
                                fontSize: 13, 
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        // Diseño Tabla Excel para Escritorio
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
                    columnSpacing: (constraints.maxWidth / 7).clamp(20, 100),
                    dataRowMinHeight: 65,
                    dataRowMaxHeight: 75,
                    dividerThickness: 0.5,
                    columns: [
                      _buildHeaderCell('Color / Material'),
                      _buildHeaderCell('Total Producido', isNumeric: true),
                      _buildHeaderCell('Total Vendido', isNumeric: true),
                      _buildHeaderCell('Stock (Aguayos)', isNumeric: true),
                      _buildHeaderCell('Cortes (20u)', isNumeric: true),
                      _buildHeaderCell('Estado'),
                    ],
                    rows: colores.map((c) {
                      final prod = prodMap[c] ?? 0;
                      final vent = ventMap[c] ?? 0;
                      final stock = stockMap[c] ?? 0;
                      final txtCortes = _inventarioSvc.formatearCortes(stock);
                      bool enRiesgo = stock <= 5;
                      final statusColor = enRiesgo ? _kRojo : _kVerde;

                      return DataRow(
                        cells: [
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle, 
                                  color: statusColor,
                                  boxShadow: [
                                    BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(c, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          )),
                          DataCell(Text('$prod', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500))),
                          DataCell(Text('$vent', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500))),
                          DataCell(Text('$stock', style: TextStyle(
                            color: enRiesgo ? _kRojo : Colors.white, 
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ))),
                          DataCell(Text(txtCortes, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              enRiesgo ? 'REPOSICIÓN' : 'ESTABLE',
                              style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value, Color color, {bool isBig = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          color: color, 
          fontSize: isBig ? 24 : 16, 
          fontWeight: FontWeight.w900
        )),
      ],
    );
  }

  DataColumn _buildHeaderCell(String label, {bool isNumeric = false}) {
    return DataColumn(
      numeric: isNumeric,
      label: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label, style: const TextStyle(color: _kAccent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 650;

        if (isMobile) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Inventario',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$total aguayos', style: const TextStyle(color: _kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatCtrl,
                        onSubmitted: _enviarChat,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Preguntar algo...',
                          hintStyle: TextStyle(color: _kAccent.withValues(alpha: 0.5), fontSize: 13),
                          filled: true,
                          fillColor: _kAccent.withValues(alpha: 0.1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          isDense: true,
                          prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: _kAccent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _kAccent.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _kAccent.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _kAccent),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _voiceSvc.speak("Probando audio."),
                      icon: const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Escritorio / Tablet Wide
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Inventario General',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    Text('Cuadro Maestro de Stock (Excel Style)',
                        style: TextStyle(color: _kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: TextField(
                  controller: _chatCtrl,
                  onSubmitted: _enviarChat,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Preguntar algo...',
                    hintStyle: TextStyle(color: _kAccent.withValues(alpha: 0.5), fontSize: 13),
                    filled: true,
                    fillColor: _kAccent.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    isDense: true,
                    prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: _kAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _kAccent.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _kAccent.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kAccent),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _voiceSvc.speak("Probando audio. Si escuchas esto, tus parlantes están bien."),
                icon: const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 20),
                tooltip: 'Probar Voz',
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kAccent.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text('Total Stock', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                    Text('$total und', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconsCard() {
    // Implementación mínima para evitar error si se llama
    return const SizedBox.shrink();
  }

  Widget _buildInsightsCard() {
    final top = _inventarioSvc.obtenerTopVendido();
    final rec = _inventarioSvc.generarRecomendacion();
    final dormidos = _inventarioSvc.obtenerStockDormido();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kAccent.withValues(alpha: 0.1), _kAccent.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: _kAccent, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Asesor de Inteligencia',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Insight de Ventas
          _buildInsightItem(
            Icons.local_fire_department_rounded, 
            'Más Vendido:', 
            top == "Sin datos" ? "Pendiente" : top, 
            Colors.orangeAccent
          ),
          const SizedBox(height: 12),
          // Recomendación
          _buildInsightItem(
            Icons.lightbulb_outline_rounded, 
            'Recomendación:', 
            rec.replaceAll('**', ''), 
            _kAccent
          ),
          if (dormidos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInsightItem(
              Icons.warning_amber_rounded, 
              'Stock Quieto:', 
              '${dormidos.join(", ")} no se mueve mucho.', 
              _kRojo
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, height: 1.4),
              children: [
                TextSpan(text: '$label ', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
                TextSpan(text: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

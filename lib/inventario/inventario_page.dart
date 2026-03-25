import 'package:flutter/material.dart';
import 'inventario_service.dart';
import 'inventario_voice_svc.dart';
import '../services/app_service.dart';
import '../produccion/modelos_produccion.dart';

// ── Colores BI Premium ──────────────────────────────────────────────────────
const _kFondo  = Color(0xFF060B18);
const _kFondo2 = Color(0xFF0F172A);
const _kCard   = Color(0xFF1E293B);
const _kCyan   = Color(0xFF0EA5E9);
const _kGreen  = Color(0xFF10B981);
const _kRed    = Color(0xFFEF4444);
const _kPurple = Color(0xFF8B5CF6);

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> with TickerProviderStateMixin {
  final _invSvc = InventarioService.instance;
  final _voiceSvc = InventarioVoiceService.instance;
  
  String _ultimaPalabra = '';
  String _respuestaVoz = '';
  bool _estaEscuchando = false;
  late AnimationController _pulseCtrl;
  late AnimationController _listCtrl;
  final _chatCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _invSvc.addListener(_onUpdate);
    _voiceSvc.init();
    
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    
    _listCtrl.forward();
    
    // Cargar datos frescos
    AppService.instance.cargarVentas();
    ProduccionService.instance.cargarDesdeServidor();
  }

  @override
  void dispose() {
    _invSvc.removeListener(_onUpdate);
    _pulseCtrl.dispose();
    _listCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() { if (mounted) setState(() {}); }

  Future<void> _toggleVoz() async {
    if (_estaEscuchando) {
      await _voiceSvc.stopListening();
      setState(() => _estaEscuchando = false);
    } else {
      setState(() { _estaEscuchando = true; _ultimaPalabra = ''; });
      final bool iniciado = await _voiceSvc.startListening((texto) {
        setState(() => _ultimaPalabra = texto);
      }, (respuesta) {
        setState(() { _respuestaVoz = respuesta; _estaEscuchando = false; });
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted && _respuestaVoz == respuesta) setState(() => _respuestaVoz = '');
        });
      });
      if (!iniciado && mounted) setState(() => _estaEscuchando = false);
    }
  }

  void _enviarChat(String texto) {
    if (texto.trim().isEmpty) return;
    final r = _voiceSvc.interpretarTexto(texto);
    setState(() { _respuestaVoz = r; _chatCtrl.clear(); });
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _respuestaVoz == r) setState(() => _respuestaVoz = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockMap = _invSvc.inventarioActual;
    final colores = stockMap.keys.toList()..sort();
    int stockTotal = stockMap.values.fold(0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: _kFondo,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_kFondo, _kFondo2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Stack(children: [
            Column(children: [
              _buildHeader(context, stockTotal),
              _buildSearchBar(),
              _buildStatsRow(stockTotal, colores.length),
              _buildInsightsCard(),
              const SizedBox(height: 12),
              
              if (colores.isEmpty)
                _buildEmptyState()
              else
                Expanded(child: _buildMainContent(colores, stockMap)),
            ]),

            // UI de VOZ semi-transparente (Glass)
            if (_estaEscuchando || _respuestaVoz.isNotEmpty)
              _buildVoiceOverlay(),
          ]),
        ),
      ),
      floatingActionButton: _buildMicrophoneFAB(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: _chatCtrl,
        onSubmitted: _enviarChat,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Consultar inventario a la IA...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _kCyan, size: 20),
          filled: true,
          fillColor: _kCard.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kCyan, width: 1.5)),
        ),
      ),
    );
  }

  // ── Header Premium ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Inventario',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text('Stock en tiempo real de producción y ventas',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
        ])),
        Container(
          height: 40, width: 40,
          decoration: BoxDecoration(
            color: _kCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.inventory_2_rounded, color: _kCyan, size: 20),
        ),
      ]),
    );
  }

  // ── Stats Quick View ────────────────────────────────────────────────────────
  Widget _buildStatsRow(int total, int totalColores) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        _statMiniCard('TOTAL UNIDADES', '$total', _kCyan, Icons.dataset_rounded),
        const SizedBox(width: 12),
        _statMiniCard('COLORES ACTIVOS', '$totalColores', _kPurple, Icons.palette_rounded),
      ]),
    );
  }

  Widget _statMiniCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w800)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ]),
        ]),
      ),
    );
  }

  // ── Card de Insights Inteligentes ──────────────────────────────────────────
  Widget _buildInsightsCard() {
    final rec = _invSvc.generarRecomendacion();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_kCyan.withValues(alpha: 0.15), _kCyan.withValues(alpha: 0.02)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome_rounded, color: _kCyan, size: 24),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ASISTENTE IA', style: TextStyle(color: _kCyan, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(rec.replaceAll('**', ''), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
        ])),
      ]),
    );
  }

  // ── Main Content (Grid / List) ──────────────────────────────────────────────
  Widget _buildMainContent(List<String> colores, Map<String, int> stockMap) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: colores.length,
      itemBuilder: (context, idx) {
        final c = colores[idx];
        final stock = stockMap[c] ?? 0;
        final enRiesgo = stock <= 10;
        final statusColor = enRiesgo ? _kRed : _kGreen;
        
        // Calcular porcentaje para la barra (basado en un stock ideal de 100 por ejemplo)
        final porc = (stock / 100).clamp(0.0, 1.0);

        return FadeTransition(
          opacity: _listCtrl,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kCard.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: enRiesgo ? _kRed.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04),
                width: enRiesgo ? 1.5 : 1,
              ),
              boxShadow: [
                if (enRiesgo) BoxShadow(color: _kRed.withValues(alpha: 0.05), blurRadius: 15, spreadRadius: -5),
              ],
            ),
            child: Row(
              children: [
                // Icono Estilizado
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor.withValues(alpha: 0.2), statusColor.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(c[0].toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 18),

                // Info Central
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(_invSvc.formatearCortes(stock),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      // Barra de Stock
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          height: 5, width: 140,
                          color: Colors.white.withValues(alpha: 0.05),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: porc,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [statusColor, statusColor.withValues(alpha: 0.4)]),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats compactos (Aprovechando espacio medio)
                if (MediaQuery.of(context).size.width > 600)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _rowStat('PRODUCCIÓN ACUMULADA', '${_getProd(c)}', _kCyan),
                          const SizedBox(height: 8),
                          _rowStat('VENTAS REALIZADAS', '${_getVend(c)}', _kPurple),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(width: 24),

                // Stock Final (A la derecha)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$stock',
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1)),
                    Text('UNIDADES',
                        style: TextStyle(
                            color: statusColor.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rowStat(String label, String val, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Evita que ocupe todo el ancho
      children: [
        Container(width: 4, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(width: 14),
        Text(val, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Row(children: [
      Text('$label ', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
      Text(value, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }

  int _getProd(String color) {
    int total = 0;
    for (var m in ProduccionService.instance.maquinas) {
      for (var s in m.historialProduccion) {
        total += s.produccionPorColor[_invSvc.normalizarColor(color)]?.toInt() ?? 0;
      }
    }
    return total;
  }

  int _getVend(String color) {
    int total = 0;
    for (var v in AppService.instance.ventas) {
      if (_invSvc.normalizarColor(v.color) == _invSvc.normalizarColor(color)) total += v.cantidad.toInt();
    }
    return total;
  }

  // ── VOZ OVERLAY (Glassmorphism) ───────────────────────────────────────────────
  Widget _buildVoiceOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kCard.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: _kCyan.withValues(alpha: 0.2), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_estaEscuchando) ...[
                const Icon(Icons.mic_rounded, color: _kCyan, size: 48),
                const SizedBox(height: 16),
                const Text('ESCUCHANDO...', style: TextStyle(color: _kCyan, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text(_ultimaPalabra.isEmpty ? 'Habla ahora...' : '"$_ultimaPalabra"',
                  style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 16), textAlign: TextAlign.center),
              ] else ...[
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded, color: _kCyan, size: 20),
                  const SizedBox(width: 8),
                  const Text('ASISTENTE VOZ', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w800, fontSize: 12)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white24), onPressed: () => setState(() => _respuestaVoz = '')),
                ]),
                const SizedBox(height: 20),
                Text(_respuestaVoz, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, height: 1.4), textAlign: TextAlign.center),
                const SizedBox(height: 20),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildMicrophoneFAB() {
    return ScaleTransition(
      scale: _pulse.value == 1.0 ? const AlwaysStoppedAnimation(1.0) : _pulse,
      child: FloatingActionButton.extended(
        onPressed: _toggleVoz,
        backgroundColor: _estaEscuchando ? _kRed : _kCyan,
        icon: Icon(_estaEscuchando ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white),
        label: Text(_estaEscuchando ? 'PARAR' : 'PREGUNTAR VOZ', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
      const SizedBox(height: 16),
      Text('SIN DATOS REALES', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      Text('Registra producciones y ventas para ver stock.', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 14)),
    ])));
  }
}

extension on _InventarioPageState {
  Widget _buildEmptyState() => const _EmptyState();
  Animation<double> get _pulse => Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
}

import 'package:flutter/material.dart';
import 'modelos_cliente.dart';

// ─────────────────────────────────────────────
//  Página Semáforo de Pago
// ─────────────────────────────────────────────
class SemaforoPagoPage extends StatefulWidget {
  final List<Cliente> clientes;

  const SemaforoPagoPage({super.key, required this.clientes});

  @override
  State<SemaforoPagoPage> createState() => _SemaforoPagoPageState();
}

class _SemaforoPagoPageState extends State<SemaforoPagoPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Agrupación por semáforo ─────────────────
  List<Cliente> _grupo(EstadoPago e) =>
      widget.clientes.where((c) => c.estadoPago == e).toList();

  // ── Configuración visual del semáforo ───────
  _SemaforoConfig _config(EstadoPago e) {
    switch (e) {
      case EstadoPago.puntual:
        return _SemaforoConfig(
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
          label: 'PUNTUAL',
          desc: 'Paga a tiempo siempre',
          bgGrad: [const Color(0xFF052E16), const Color(0xFF0D0018)],
        );
      case EstadoPago.seRetrasa:
        return _SemaforoConfig(
          color: const Color(0xFFF59E0B),
          icon: Icons.schedule_rounded,
          label: 'SE RETRASA',
          desc: 'Pago ocasionalmente tardío',
          bgGrad: [const Color(0xFF451A03), const Color(0xFF0D0018)],
        );
      case EstadoPago.riesgo:
        return _SemaforoConfig(
          color: const Color(0xFFEF4444),
          icon: Icons.warning_rounded,
          label: 'RIESGO',
          desc: 'Alto riesgo de incumplimiento',
          bgGrad: [const Color(0xFF450A0A), const Color(0xFF0D0018)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final puntuales = _grupo(EstadoPago.puntual);
    final retrasos = _grupo(EstadoPago.seRetrasa);
    final riesgos = _grupo(EstadoPago.riesgo);
    final total = widget.clientes.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0018),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444)],
          ).createShader(b),
          child: const Text(
            'Semáforo de Pago',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Visual Semáforo Central ────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  // Semáforo gráfico
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A0035), Color(0xFF0D001A)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SemaforoLuz(
                          color: const Color(0xFF10B981),
                          activo: puntuales.isNotEmpty,
                          cantidad: puntuales.length,
                          label: 'Puntuales',
                          pulseCtrl: _pulseCtrl,
                        ),
                        _SemaforoLuz(
                          color: const Color(0xFFF59E0B),
                          activo: retrasos.isNotEmpty,
                          cantidad: retrasos.length,
                          label: 'Se retrasan',
                          pulseCtrl: _pulseCtrl,
                        ),
                        _SemaforoLuz(
                          color: const Color(0xFFEF4444),
                          activo: riesgos.isNotEmpty,
                          cantidad: riesgos.length,
                          label: 'Riesgo',
                          pulseCtrl: _pulseCtrl,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Barra de distribución
                  if (total > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            if (puntuales.isNotEmpty)
                              Flexible(
                                flex: puntuales.length,
                                child: Container(
                                    color: const Color(0xFF10B981)),
                              ),
                            if (retrasos.isNotEmpty)
                              Flexible(
                                flex: retrasos.length,
                                child: Container(
                                    color: const Color(0xFFF59E0B)),
                              ),
                            if (riesgos.isNotEmpty)
                              Flexible(
                                flex: riesgos.length,
                                child: Container(
                                    color: const Color(0xFFEF4444)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$total clientes en total',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          total > 0
                              ? '${(puntuales.length / total * 100).toStringAsFixed(0)}% puntuales'
                              : '',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Secciones por estado ──────────────
          for (final estado in EstadoPago.values)
            if (_grupo(estado).isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(config: _config(estado),
                    count: _grupo(estado).length),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final cl = _grupo(estado)[i];
                    return _SemaforoClienteCard(
                      cliente: cl,
                      config: _config(estado),
                    );
                  },
                  childCount: _grupo(estado).length,
                ),
              ),
            ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Modelo config semáforo
// ─────────────────────────────────────────────
class _SemaforoConfig {
  final Color color;
  final IconData icon;
  final String label;
  final String desc;
  final List<Color> bgGrad;

  const _SemaforoConfig({
    required this.color,
    required this.icon,
    required this.label,
    required this.desc,
    required this.bgGrad,
  });
}

// ─────────────────────────────────────────────
//  Widget: Luz del semáforo
// ─────────────────────────────────────────────
class _SemaforoLuz extends StatelessWidget {
  final Color color;
  final bool activo;
  final int cantidad;
  final String label;
  final AnimationController pulseCtrl;

  const _SemaforoLuz({
    required this.color,
    required this.activo,
    required this.cantidad,
    required this.label,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: pulseCtrl,
          builder: (_, child) {
            final pulse = activo ? (0.6 + 0.4 * pulseCtrl.value) : 0.15;
            return Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: activo ? 0.15 : 0.05),
                border: Border.all(
                  color: color.withValues(alpha: activo ? 0.80 : 0.20),
                  width: 2.5,
                ),
                boxShadow: activo
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: pulse * 0.60),
                          blurRadius: 20 + 10 * pulseCtrl.value,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: activo
                    ? Text(
                        '$cantidad',
                        style: TextStyle(
                          color: color,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : Icon(Icons.remove, color: color.withValues(alpha: 0.25), size: 20),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: activo ? color : Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Encabezado de sección
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final _SemaforoConfig config;
  final int count;

  const _SectionHeader({required this.config, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config.bgGrad,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.label,
                  style: TextStyle(
                    color: config.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  config.desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: config.color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Tarjeta cliente en semáforo
// ─────────────────────────────────────────────
class _SemaforoClienteCard extends StatelessWidget {
  final Cliente cliente;
  final _SemaforoConfig config;

  const _SemaforoClienteCard({
    required this.cliente,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          // Indicador circular
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: config.color.withValues(alpha: 0.60), blurRadius: 6)
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Info cliente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.35)),
                    const SizedBox(width: 4),
                    Text(
                      cliente.telefono.isEmpty ? '—' : cliente.telefono,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                      ),
                    ),
                    if (cliente.saldoPendiente > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Bs ${cliente.saldoPendiente.toStringAsFixed(0)} deuda',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Color _colorEstado(EstadoPago e) {
    switch (e) {
      case EstadoPago.puntual:
        return const Color(0xFF10B981);
      case EstadoPago.seRetrasa:
        return const Color(0xFFF59E0B);
      case EstadoPago.riesgo:
        return const Color(0xFFEF4444);
    }
  }

  IconData _iconEstado(EstadoPago e) {
    switch (e) {
      case EstadoPago.puntual:
        return Icons.check_circle_rounded;
      case EstadoPago.seRetrasa:
        return Icons.schedule_rounded;
      case EstadoPago.riesgo:
        return Icons.warning_rounded;
    }
  }

  String _labelEstado(EstadoPago e) {
    switch (e) {
      case EstadoPago.puntual:
        return 'Puntual — paga a tiempo';
      case EstadoPago.seRetrasa:
        return 'Se retrasa — tardíos ocasionales';
      case EstadoPago.riesgo:
        return 'Riesgo — alto incumplimiento';
    }
  }
}

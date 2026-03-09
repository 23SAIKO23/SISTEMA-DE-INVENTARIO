import 'package:flutter/material.dart';
import 'modelos_produccion.dart';
import 'registro_semanal.dart' show ProdAppBar, ProdEmpty;

// ── Paleta ─────────────────────────────────────
const _kAzul       = Color(0xFF1565C0);
const _kAzulClaro  = Color(0xFF42A5F5);
const _kVerde      = Color(0xFF00C853);
const _kVerdeClaro = Color(0xFF69F0AE);
const _kFondo      = Color(0xFF0A1628);
const _kFondo2     = Color(0xFF0D2145);
const _kAmbar      = Color(0xFFFFB300);

// ─────────────────────────────────────────────
//  Productividad por trabajador (aguayos por SEMANA)
// ─────────────────────────────────────────────
class ProductividadPage extends StatefulWidget {
  const ProductividadPage({super.key});
  @override
  State<ProductividadPage> createState() => _ProductividadPageState();
}

class _ProductividadPageState extends State<ProductividadPage> {
  final _svc = ProduccionService.instance;
  String? _seleccionado;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final trabajadores = _svc.produccionPorTrabajador.keys.toList();
    final porTrab = _svc.produccionPorTrabajador;
    final total   = _svc.totalProduccionGobal;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kFondo, _kFondo2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(child: Column(children: [
          const ProdAppBar(titulo: 'PRODUCTIVIDAD',
              subtitulo: 'Rendimiento semanal por trabajador'),

          // Resumen general
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              _StatBox(label: 'Trabajadores', valor: '${trabajadores.length}',
                  color: _kAzulClaro, icono: Icons.group_rounded),
              const SizedBox(width: 10),
              _StatBox(label: 'Máquinas activas',
                  valor: '${_svc.maquinas.length}',
                  color: _kVerdeClaro,
                  icono: Icons.precision_manufacturing_rounded),
              const SizedBox(width: 10),
              _StatBox(label: 'Total histórico',
                  valor: '${total.toStringAsFixed(0)}',
                  color: _kVerde, icono: Icons.inventory_2_rounded),
            ]),
          ),

          // Lista trabajadores
          Expanded(
            child: trabajadores.isEmpty
                ? const ProdEmpty('No hay máquinas asignadas a trabajadores')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    children: [
                      const _SeccionTitle('RANKING PROMEDIO SEMANAL'),
                      const SizedBox(height: 8),
                      ..._rankingList(trabajadores, porTrab, total),
                    ],
                  ),
          ),
        ])),
      ),
    );
  }

  List<Widget> _rankingList(
    List<String> trabajadores,
    Map<String, double> porTrab,
    double total,
  ) {
    // Ordenamos por mayor productividad SEMANAL
    final sorted = trabajadores.toList()
      ..sort((a, b) {
        final pa = _svc.productividadSemanalTrabajador(a);
        final pb = _svc.productividadSemanalTrabajador(b);
        return pb.compareTo(pa); // descendente
      });

    final medalColors = [_kAmbar, const Color(0xFFBDBDBD), _kAmbar];

    return sorted.asMap().entries.map((entry) {
      final pos   = entry.key;
      final t     = entry.value;
      final prod  = porTrab[t] ?? 0.0;
      final pdt   = _svc.productividadSemanalTrabajador(t);
      final pct   = total > 0 ? prod / total : 0.0;
      final semanas = _svc.semanasTrabajadasPorTrabajador(t);
      final maqAsignadas = _svc.maquinas
          .where((m) => m.trabajadorAsignado == t)
          .toList();

      Color c;
      if (pos == 0)      c = _kAmbar;
      else if (pos == 1) c = const Color(0xFF90A4AE);
      else               c = _kVerde;

      return _TarjetaTrabajador(
        posicion: pos + 1,
        nombre: t,
        total: prod,
        productividadSemanal: pdt,
        porcentaje: pct,
        semanas: semanas,
        color: c,
        medalColor: pos < medalColors.length ? medalColors[pos] : _kVerde,
        maquinas: maqAsignadas,
        onTap: () => setState(() =>
            _seleccionado = _seleccionado == t ? null : t),
        expandido: _seleccionado == t,
      );
    }).toList();
  }
}

// ── Tarjeta de trabajador ──────────────────────
class _TarjetaTrabajador extends StatelessWidget {
  final int posicion, semanas;
  final String nombre;
  final double total, productividadSemanal, porcentaje;
  final Color color, medalColor;
  final List<Maquina> maquinas;
  final VoidCallback onTap;
  final bool expandido;

  const _TarjetaTrabajador({
    required this.posicion, required this.nombre, required this.total,
    required this.productividadSemanal, required this.porcentaje,
    required this.semanas, required this.color,
    required this.medalColor, required this.maquinas, required this.onTap,
    required this.expandido,
  });

  static const _kFondo2 = Color(0xFF0D2145);
  static const _kAzulClaro = Color(0xFF42A5F5);
  static const _kVerdeClaro = Color(0xFF69F0AE);
  static const _kAmbar = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kFondo2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.50), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Container(height: 4, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF1565C0), _kAzulClaro, const Color(0xFF00C853), _kVerdeClaro]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
          )),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.50)),
                  ),
                  child: Center(child: Text(
                    posicion <= 3 ? ['🥇','🥈','🥉'][posicion - 1] : '#$posicion',
                    style: const TextStyle(fontSize: 22),
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nombre, style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.date_range_rounded, size: 10,
                        color: _kAzulClaro.withValues(alpha: 0.70)),
                    const SizedBox(width: 4),
                    Text('$semanas semana(s) activa(s)',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 10)),
                  ]),
                  const SizedBox(height: 4),
                  Wrap(spacing: 4, children: maquinas.map((m) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kAzulClaro.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _kAzulClaro.withValues(alpha: 0.30)),
                    ),
                    child: Text(m.nombre, style: TextStyle(
                        color: _kAzulClaro, fontSize: 9,
                        fontWeight: FontWeight.w600)),
                  )).toList()),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${productividadSemanal.toStringAsFixed(1)}',
                      style: TextStyle(color: color, fontWeight: FontWeight.w900,
                          fontSize: 26)),
                  Text('promedio/sem', style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 9)),
                ]),
              ]),
              const SizedBox(height: 10),

              Stack(children: [
                Container(height: 8, decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(6),
                )),
                FractionallySizedBox(
                  widthFactor: porcentaje.clamp(0.0, 1.0),
                  child: Container(height: 8, decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [_kAzulClaro, color]),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(
                        color: color.withValues(alpha: 0.50), blurRadius: 6)],
                  )),
                ),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${total.toStringAsFixed(0)} uds recolectados (histórico)',
                    style: TextStyle(color: color, fontSize: 11,
                        fontWeight: FontWeight.w700)),
                Text('${(porcentaje * 100).toStringAsFixed(1)}% del total general',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40),
                        fontSize: 10)),
              ]),

              if (expandido) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                  ),
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(children: [
                        Icon(Icons.history_rounded, size: 12,
                            color: _kAmbar.withValues(alpha: 0.80)),
                        const SizedBox(width: 5),
                        Text('Últimas 3 semanas (Máquinas Asignadas)',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    ...maquinas.expand((m) => m.historialProduccion.take(3).map((r) => 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text('${m.nombre} • ${r.etiquetaSemana}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
                                  overflow: TextOverflow.ellipsis)),
                              Text('${r.cantidadAcumulada.toStringAsFixed(0)} uds',
                                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                              const SizedBox(width: 6),
                              Icon(r.cerrada ? Icons.lock_rounded : Icons.lock_open_rounded, 
                                size: 11, color: r.cerrada ? Colors.white38 : _kVerdeClaro)
                            ]),
                            if (r.produccionPorColor.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6, runSpacing: 4,
                                children: r.produccionPorColor.entries.map((e) => 
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.palette_rounded, size: 9, color: color.withValues(alpha: 0.7)),
                                        const SizedBox(width: 3),
                                        Text('${e.key}: ', style: TextStyle(color: Colors.white70, fontSize: 9)),
                                        Text('${e.value.toStringAsFixed(0)}', 
                                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9)),
                                      ],
                                    ),
                                  )
                                ).toList()
                              )
                            ]
                          ],
                        ),
                      )
                    )),
                    const SizedBox(height: 6),
                  ]),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label, valor;
  final Color color;
  final IconData icono;
  const _StatBox({required this.label, required this.valor,
      required this.color, required this.icono});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: color, size: 15),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(color: color,
            fontWeight: FontWeight.w900, fontSize: 14)),
        Text(label, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40), fontSize: 9)),
      ]),
    ),
  );
}

class _SeccionTitle extends StatelessWidget {
  final String text;
  const _SeccionTitle(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 14,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_kAzulClaro, _kVerdeClaro],
            begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.40),
        fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  ]);
}

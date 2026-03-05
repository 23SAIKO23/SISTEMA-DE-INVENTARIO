import 'package:flutter/material.dart';
import 'modelos_cliente.dart';

// ─────────────────────────────────────────────
//  Modelo Abono
// ─────────────────────────────────────────────
class Abono {
  final DateTime fecha;
  final double monto;
  final String nota;

  const Abono({
    required this.fecha,
    required this.monto,
    this.nota = '',
  });
}

// ─────────────────────────────────────────────
//  Página Control de Deudas
// ─────────────────────────────────────────────
class ControlDeudasPage extends StatefulWidget {
  final List<Cliente> clientes;

  const ControlDeudasPage({super.key, required this.clientes});

  @override
  State<ControlDeudasPage> createState() => _ControlDeudasPageState();
}

class _ControlDeudasPageState extends State<ControlDeudasPage> {
  // Abonos de ejemplo por cliente id
  final Map<String, List<Abono>> _abonos = {
    '1': [
      Abono(fecha: DateTime(2025, 2, 10), monto: 150, nota: 'Abono inicial'),
    ],
    '3': [
      Abono(fecha: DateTime(2025, 1, 5), monto: 400, nota: 'Primer pago'),
      Abono(fecha: DateTime(2025, 2, 20), monto: 200, nota: 'Segundo pago'),
    ],
    '4': [],
  };

  List<Cliente> get _conDeuda =>
      widget.clientes.where((c) => c.saldoPendiente > 0).toList()
        ..sort((a, b) => b.saldoPendiente.compareTo(a.saldoPendiente));

  double get _totalDeudaGlobal =>
      widget.clientes.fold(0, (s, c) => s + c.saldoPendiente);

  @override
  Widget build(BuildContext context) {
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
            colors: [Color(0xFFFBBF24), Color(0xFFFCA5A5)],
          ).createShader(b),
          child: const Text(
            'Control de Deudas',
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
          // ── Resumen global ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  // Banner total deuda
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C1D1D), Color(0xFF1A0035)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFEF4444).withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  const Color(0xFFEF4444).withValues(alpha: 0.50),
                            ),
                          ),
                          child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Color(0xFFEF4444),
                              size: 26),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bs. ${_totalDeudaGlobal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Deuda total — ${_conDeuda.length} cliente(s) pendientes',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.50),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mini stats
                  Row(
                    children: [
                      _MiniStat(
                        valor: '${widget.clientes.length}',
                        label: 'Total clientes',
                        color: const Color(0xFF6366F1),
                        icono: Icons.people_alt_rounded,
                      ),
                      const SizedBox(width: 10),
                      _MiniStat(
                        valor:
                            '${widget.clientes.where((c) => c.estadoPago == EstadoPago.puntual).length}',
                        label: 'Al día',
                        color: const Color(0xFF10B981),
                        icono: Icons.check_circle_rounded,
                      ),
                      const SizedBox(width: 10),
                      _MiniStat(
                        valor: '${_conDeuda.length}',
                        label: 'Con deuda',
                        color: const Color(0xFFEF4444),
                        icono: Icons.warning_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Etiqueta
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CLIENTES CON SALDO PENDIENTE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Lista deudores ─────────────────────
          _conDeuda.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 60,
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.60)),
                          const SizedBox(height: 12),
                          Text(
                            '¡Sin deudas pendientes!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final cl = _conDeuda[i];
                      final abonos = _abonos[cl.id] ?? [];
                      return _DeudorCard(
                        cliente: cl,
                        abonos: abonos,
                        onAbonar: () => _mostrarAbonoDialog(context, cl),
                      );
                    },
                    childCount: _conDeuda.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _mostrarAbonoDialog(BuildContext context, Cliente cliente) {
    final montoCtrl = TextEditingController();
    final notaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_card_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Registrar abono',
                style: const TextStyle(color: Colors.white, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cliente.nombre,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 12,
              ),
            ),
            Text(
              'Saldo: Bs ${cliente.saldoPendiente.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            _DialogCampo(ctrl: montoCtrl, label: 'Monto del abono (Bs)',
                tipo: TextInputType.number),
            const SizedBox(height: 10),
            _DialogCampo(ctrl: notaCtrl, label: 'Nota (opcional)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.40))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final monto = double.tryParse(montoCtrl.text) ?? 0;
              if (monto <= 0 || monto > cliente.saldoPendiente) return;
              setState(() {
                cliente.saldoPendiente -= monto;
                _abonos.putIfAbsent(cliente.id, () => []).add(
                  Abono(
                    fecha: DateTime.now(),
                    monto: monto,
                    nota: notaCtrl.text,
                  ),
                );
                if (cliente.saldoPendiente == 0) {
                  cliente.estadoPago = EstadoPago.puntual;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Tarjeta de deudor
// ─────────────────────────────────────────────
class _DeudorCard extends StatefulWidget {
  final Cliente cliente;
  final List<Abono> abonos;
  final VoidCallback onAbonar;

  const _DeudorCard({
    required this.cliente,
    required this.abonos,
    required this.onAbonar,
  });

  @override
  State<_DeudorCard> createState() => _DeudorCardState();
}

class _DeudorCardState extends State<_DeudorCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
    final urgencia = c.estadoPago == EstadoPago.riesgo
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: urgencia.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: urgencia.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: urgencia.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded, color: urgencia, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        c.telefono,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bs ${c.saldoPendiente.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: urgencia,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'pendiente',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barra de progreso abonos
          if (widget.abonos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (widget.abonos.fold(0.0, (s, a) => s + a.monto)) /
                          (c.saldoPendiente +
                              widget.abonos.fold(0.0, (s, a) => s + a.monto)),
                      minHeight: 6,
                      backgroundColor:
                          urgencia.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          urgencia.withValues(alpha: 0.80)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Abonado: Bs ${widget.abonos.fold(0.0, (s, a) => s + a.monto).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

          // Botones acción
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: Icon(
                      _expandido
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.history_rounded,
                      size: 16,
                    ),
                    label: Text(
                        _expandido ? 'Ocultar' : 'Ver abonos',
                        style: const TextStyle(fontSize: 11)),
                    onPressed: () =>
                        setState(() => _expandido = !_expandido),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Abonar',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    onPressed: widget.onAbonar,
                  ),
                ),
              ],
            ),
          ),

          // Historial abonos expandible
          if (_expandido)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.abonos.isEmpty
                  ? Text(
                      'Sin abonos registrados',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11),
                    )
                  : Column(
                      children: widget.abonos
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      a.nota.isEmpty
                                          ? _formatFecha(a.fecha)
                                          : '${_formatFecha(a.fecha)} — ${a.nota}',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '+ Bs ${a.monto.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime d) {
    const meses = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${meses[d.month]} ${d.year}';
  }
}

// ─────────────────────────────────────────────
//  Widgets auxiliares
// ─────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String valor;
  final String label;
  final Color color;
  final IconData icono;

  const _MiniStat({
    required this.valor,
    required this.label,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 18),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40), fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _DialogCampo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType tipo;

  const _DialogCampo({
    required this.ctrl,
    required this.label,
    this.tipo = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
    );
  }
}

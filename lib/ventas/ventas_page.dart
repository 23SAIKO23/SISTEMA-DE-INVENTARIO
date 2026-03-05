import 'package:flutter/material.dart';
import 'modelos_venta.dart';

export 'modelos_venta.dart';

// ── Paleta azul / verde / blanco ──────────────
const _kAzul     = Color(0xFF1565C0);   // azul fuerte
const _kAzulClaro = Color(0xFF42A5F5);  // azul cielo
const _kVerde    = Color(0xFF00C853);   // verde vibrante
const _kVerdeClaro = Color(0xFF69F0AE); // verde menta
const _kFondo    = Color(0xFF0A1628);   // azul noche muy oscuro
const _kFondo2   = Color(0xFF0D2145);   // azul noche medio

// ─────────────────────────────────────────────
//  Página principal de Ventas
// ─────────────────────────────────────────────
class VentasPage extends StatefulWidget {
  const VentasPage({super.key});
  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final List<Venta> _ventas = [
    Venta(
      id: '001', cliente: 'Tienda Don Pepe',
      tipo: TipoProducto.doble, color: 'Rojo / Negro',
      cantidad: 5, destino: 'Av. Potosí 123',
      precioUnit: 120, pago: ModalidadPago.credito,
      montoPagado: 100, fecha: DateTime(2025, 3, 1),
    ),
    Venta(
      id: '002', cliente: 'Doña Carmen',
      tipo: TipoProducto.simple, color: 'Azul / Blanco',
      cantidad: 3, destino: 'Calle Junín 45',
      precioUnit: 80, pago: ModalidadPago.parcial,
      montoPagado: 180, fecha: DateTime(2025, 3, 3),
    ),
    Venta(
      id: '003', cliente: 'Distribuidora Alteña',
      tipo: TipoProducto.metros, color: 'Verde / Amarillo',
      cantidad: 10, destino: 'El Alto, 16 de Julio',
      precioUnit: 35, pago: ModalidadPago.contado,
      montoPagado: 350, fecha: DateTime(2025, 2, 20),
    ),
    Venta(
      id: '004', cliente: 'Tienda La Estrella',
      tipo: TipoProducto.doble, color: 'Morado / Rosa',
      cantidad: 2, destino: 'Mercado Rodríguez',
      precioUnit: 150, pago: ModalidadPago.credito,
      montoPagado: 0, fecha: DateTime(2025, 3, 5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final totalVentas    = _ventas.fold(0.0, (s, v) => s + v.total);
    final totalPendiente = _ventas.fold(0.0, (s, v) => s + v.pendiente);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kFondo, _kFondo2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // ── AppBar manual ────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [_kAzulClaro, _kVerdeClaro],
                          ).createShader(b),
                          child: const Text('VENTAS',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.5)),
                        ),
                        Text('Registro de pedidos',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 10,
                                letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Franja decorativa ──────────
              Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kAzul, _kAzulClaro, _kVerde, _kVerdeClaro]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),

              // ── Resumen ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _Caja(
                      titulo: 'Total ventas',
                      valor: 'Bs ${totalVentas.toStringAsFixed(0)}',
                      color: _kAzulClaro,
                      icono: Icons.shopping_bag_rounded,
                    ),
                    const SizedBox(width: 10),
                    _Caja(
                      titulo: 'Por cobrar',
                      valor: 'Bs ${totalPendiente.toStringAsFixed(0)}',
                      color: _kVerdeClaro,
                      icono: Icons.account_balance_wallet_rounded,
                    ),
                  ],
                ),
              ),

              // ── Lista de pedidos ─────────────
              Expanded(
                child: _ventas.isEmpty
                    ? Center(
                        child: Text('Sin pedidos',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35))))
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: _ventas.length,
                        itemBuilder: (_, i) => _TarjetaVenta(
                          venta: _ventas[i],
                          onAbonar: () => _abonar(context, _ventas[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kVerde,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo pedido',
            style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _formulario(context),
      ),
    );
  }

  // ── Registrar abono ───────────────────────
  void _abonar(BuildContext ctx, Venta v) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2145),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _kAzulClaro.withValues(alpha: 0.40)),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kVerde.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kVerde.withValues(alpha: 0.50)),
            ),
            child: const Icon(Icons.add_card_rounded, color: _kVerde, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Registrar abono',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Column(children: [
                _Fila('Total del pedido',
                    'Bs ${v.total.toStringAsFixed(2)}', Colors.white70),
                const SizedBox(height: 4),
                _Fila('Ya cobrado',
                    'Bs ${v.montoPagado.toStringAsFixed(2)}', _kVerdeClaro),
                const SizedBox(height: 4),
                _Fila('Pendiente',
                    'Bs ${v.pendiente.toStringAsFixed(2)}', _kAzulClaro),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Monto del abono (Bs)',
                labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50), fontSize: 12),
                prefixText: 'Bs  ',
                prefixStyle: const TextStyle(
                    color: _kVerdeClaro, fontWeight: FontWeight.w700),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _kAzulClaro, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerde,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final m = double.tryParse(ctrl.text) ?? 0;
              if (m > 0) {
                setState(() =>
                    v.montoPagado = (v.montoPagado + m).clamp(0, v.total));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Confirmar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Formulario nuevo pedido ───────────────
  void _formulario(BuildContext ctx) {
    final clienteCtrl = TextEditingController();
    final colorCtrl   = TextEditingController();
    final cantCtrl    = TextEditingController();
    final destCtrl    = TextEditingController();
    final precioCtrl  = TextEditingController();
    TipoProducto tipo  = TipoProducto.simple;
    ModalidadPago pago  = ModalidadPago.contado;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (bCtx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(bCtx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF0D2145),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _kAzulClaro.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Línea decorativa + título
                  Row(children: [
                    Container(
                      width: 4, height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kAzulClaro, _kVerdeClaro],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Nuevo Pedido',
                        style: TextStyle(color: Colors.white,
                            fontSize: 18, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 16),

                  // Tipo
                  _SecLabel('TIPO DE TEJIDO'),
                  const SizedBox(height: 6),
                  Row(children: TipoProducto.values.map((t) {
                    final sel = tipo == t;
                    final colores = [_kAzulClaro, _kVerde, _kVerdeClaro];
                    final c = colores[TipoProducto.values.indexOf(t)];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setS(() => tipo = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 6),
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: sel
                                ? c.withValues(alpha: 0.20)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? c
                                  : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(_labelTipo(t),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: sel ? c : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 12),

                  _Input(ctrl: clienteCtrl, label: 'Cliente',
                      icono: Icons.person_rounded),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _Input(ctrl: colorCtrl, label: 'Color',
                        icono: Icons.palette_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _Input(
                        ctrl: cantCtrl,
                        label: tipo == TipoProducto.metros
                            ? 'Metros' : 'Cantidad',
                        icono: Icons.tag_rounded, numerico: true)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _Input(ctrl: precioCtrl,
                        label: 'Precio (Bs)',
                        icono: Icons.attach_money_rounded, numerico: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _Input(ctrl: destCtrl, label: 'Destino',
                        icono: Icons.location_on_rounded)),
                  ]),
                  const SizedBox(height: 12),

                  _SecLabel('FORMA DE PAGO'),
                  const SizedBox(height: 6),
                  Row(children: [
                    _PagoBtn(label: 'Contado', color: _kVerde,
                        activo: pago == ModalidadPago.contado,
                        onTap: () => setS(() => pago = ModalidadPago.contado)),
                    const SizedBox(width: 6),
                    _PagoBtn(label: 'Crédito', color: _kAzulClaro,
                        activo: pago == ModalidadPago.credito,
                        onTap: () => setS(() => pago = ModalidadPago.credito)),
                    const SizedBox(width: 6),
                    _PagoBtn(label: 'Parcial', color: _kVerdeClaro,
                        activo: pago == ModalidadPago.parcial,
                        onTap: () => setS(() => pago = ModalidadPago.parcial)),
                  ]),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kVerde,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (clienteCtrl.text.trim().isEmpty) return;
                        final cant =
                            double.tryParse(cantCtrl.text) ?? 1;
                        final precio =
                            double.tryParse(precioCtrl.text) ?? 0;
                        setState(() {
                          _ventas.insert(0, Venta(
                            id: '${_ventas.length + 1}'.padLeft(3, '0'),
                            cliente: clienteCtrl.text.trim(),
                            tipo: tipo,
                            color: colorCtrl.text.trim(),
                            cantidad: cant,
                            destino: destCtrl.text.trim(),
                            precioUnit: precio,
                            pago: pago,
                            montoPagado: pago == ModalidadPago.contado
                                ? cant * precio : 0,
                            fecha: DateTime.now(),
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Registrar pedido',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _labelTipo(TipoProducto t) {
    switch (t) {
      case TipoProducto.simple: return 'Simple';
      case TipoProducto.doble:  return 'Doble';
      case TipoProducto.metros: return 'Metros';
    }
  }
}

// ─────────────────────────────────────────────
//  Tarjeta de venta
// ─────────────────────────────────────────────
class _TarjetaVenta extends StatelessWidget {
  final Venta venta;
  final VoidCallback onAbonar;
  const _TarjetaVenta({required this.venta, required this.onAbonar});

  ({Color color, Color barColor, String emoji, String texto}) _cfg() {
    switch (venta.estadoPago) {
      case EstadoPago.sinAbono:
        return (color: const Color(0xFFEF5350),
            barColor: const Color(0xFFEF5350),
            emoji: '🔴',
            texto: 'Sin abono — debe Bs ${venta.pendiente.toStringAsFixed(0)}');
      case EstadoPago.vaPagando:
        return (color: _kAzulClaro,
            barColor: _kAzulClaro,
            emoji: '🔵',
            texto: 'Va pagando — falta Bs ${venta.pendiente.toStringAsFixed(0)}');
      case EstadoPago.casiSaldado:
        return (color: _kVerdeClaro,
            barColor: _kVerdeClaro,
            emoji: '🟢',
            texto: '¡Casi! — falta Bs ${venta.pendiente.toStringAsFixed(0)}');
      case EstadoPago.saldado:
        return (color: _kVerde,
            barColor: _kVerde,
            emoji: '✅',
            texto: '¡Pagado completo!');
    }
  }

  String _labelPago(ModalidadPago p) {
    switch (p) {
      case ModalidadPago.contado: return 'Contado';
      case ModalidadPago.credito: return 'Crédito';
      case ModalidadPago.parcial: return 'Parcial';
    }
  }

  String _labelTipo(TipoProducto t) {
    switch (t) {
      case TipoProducto.simple: return 'Simple';
      case TipoProducto.doble:  return 'Doble';
      case TipoProducto.metros: return 'Metros';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2145),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cfg.color.withValues(alpha: 0.50), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: cfg.color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Franja superior azul→verde
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_kAzul, _kAzulClaro, _kVerde, _kVerdeClaro]),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: cfg.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: cfg.color.withValues(alpha: 0.50)),
                      ),
                      child: Center(
                        child: Text('#${venta.id}',
                            style: TextStyle(
                                color: cfg.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(venta.cliente,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(
                            '${_labelTipo(venta.tipo)}  •  '
                            '${venta.color.isEmpty ? "—" : venta.color}  •  '
                            '${venta.tipo == TipoProducto.metros ? "${venta.cantidad.toStringAsFixed(0)} m" : "${venta.cantidad.toInt()} unid."}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 11),
                          ),
                          if (venta.destino.isNotEmpty)
                            Row(children: [
                              Icon(Icons.location_on_rounded,
                                  size: 11,
                                  color: _kAzulClaro.withValues(alpha: 0.70)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(venta.destino,
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.45),
                                        fontSize: 11),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Bs ${venta.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18)),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kAzul.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_labelPago(venta.pago),
                              style: TextStyle(
                                  color: _kAzulClaro.withValues(alpha: 0.90),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Barra de progreso
                Stack(children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: venta.progreso,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [_kAzulClaro, cfg.barColor]),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                              color: cfg.barColor.withValues(alpha: 0.50),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),

                // Estado
                Row(children: [
                  Text(cfg.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(cfg.texto,
                        style: TextStyle(
                            color: cfg.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  Text(
                    'Bs ${venta.montoPagado.toStringAsFixed(0)} cobrado',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40),
                        fontSize: 10),
                  ),
                ]),

                if (!venta.saldado) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cfg.color,
                        side: BorderSide(
                            color: cfg.color.withValues(alpha: 0.60)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Registrar abono',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: onAbonar,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widgets auxiliares
// ─────────────────────────────────────────────
class _Caja extends StatelessWidget {
  final String titulo, valor;
  final Color color;
  final IconData icono;
  const _Caja({required this.titulo, required this.valor,
      required this.color, required this.icono});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2145),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.10),
                  blurRadius: 12)
            ],
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.40)),
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(valor,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w900, fontSize: 16)),
              Text(titulo,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
            ]),
          ]),
        ),
      );
}

class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icono;
  final bool numerico;
  const _Input({required this.ctrl, required this.label,
      required this.icono, this.numerico = false});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: numerico ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
          prefixIcon: Icon(icono, color: _kAzulClaro, size: 17),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.14)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kAzulClaro, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      );
}

class _PagoBtn extends StatelessWidget {
  final String label;
  final bool activo;
  final Color color;
  final VoidCallback onTap;
  const _PagoBtn({required this.label, required this.activo,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: activo
                  ? color.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: activo
                      ? color
                      : Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: activo ? color : Colors.white38,
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

class _Fila extends StatelessWidget {
  final String label, valor;
  final Color color;
  const _Fila(this.label, this.valor, this.color);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
          Text(valor,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      );
}

class _SecLabel extends StatelessWidget {
  final String texto;
  const _SecLabel(this.texto);

  @override
  Widget build(BuildContext context) => Text(texto,
      style: const TextStyle(
          color: Colors.white38, fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 1.3));
}

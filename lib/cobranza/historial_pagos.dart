import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../ventas/modelos_venta.dart';
import 'cobranza_widgets.dart';
import 'recibo_pdf.dart';

// ── Paleta ────────────────────────────────────
const _kAzul       = Color(0xFF1565C0);
const _kAzulClaro  = Color(0xFF42A5F5);
const _kVerde      = Color(0xFF00C853);
const _kVerdeClaro = Color(0xFF69F0AE);
const _kFondo      = Color(0xFF0A1628);
const _kFondo2     = Color(0xFF0D2145);
const _kRojo       = Color(0xFFEF5350);
const _kAmbar      = Color(0xFFFFB300);

// ─────────────────────────────────────────────
//  Historial de Pagos por Cliente
//  Lee historialAbonos directamente desde Venta (via AppService)
// ─────────────────────────────────────────────
class HistorialPagos extends StatefulWidget {
  const HistorialPagos({super.key});
  @override
  State<HistorialPagos> createState() => _HistorialPagosState();
}

class _HistorialPagosState extends State<HistorialPagos> {
  final _svc = AppService.instance;
  String _busqueda = '';
  Venta? _seleccionada;

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

  // Solo ventas con al menos 1 abono
  List<Venta> get _conHistorial => _svc.cuentasPorCobrar
      .where((v) =>
          v.historialAbonos.isNotEmpty &&
          v.cliente.toLowerCase().contains(_busqueda.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
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
          child: _seleccionada == null
              ? _vistaListado(context)
              : _vistaDetalle(context, _seleccionada!),
        ),
      ),
    );
  }

  // ── Vista listado ─────────────────────────
  Widget _vistaListado(BuildContext context) {
    final totalAbonos = _svc.cuentasPorCobrar
        .fold<int>(0, (s, v) => s + v.historialAbonos.length);

    return Column(children: [
      CobAppBar(titulo: 'HISTORIAL DE PAGOS',
          subtitulo: 'Por cliente · sincronizado con Ventas'),

      // Resumen global
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _MiniCard(label: 'Total abonos',
              valor: '$totalAbonos',
              color: _kAzulClaro,
              icono: Icons.receipt_long_rounded),
          const SizedBox(width: 10),
          _MiniCard(label: 'Cobrado',
              valor: 'Bs ${_svc.totalCobrado.toStringAsFixed(0)}',
              color: _kVerde,
              icono: Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _MiniCard(label: 'Pendiente',
              valor: 'Bs ${_svc.totalPendiente.toStringAsFixed(0)}',
              color: _kAmbar,
              icono: Icons.hourglass_top_rounded),
        ]),
      ),
      const SizedBox(height: 12),

      // Buscador
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _busqueda = v),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.30), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: _kAzulClaro.withValues(alpha: 0.70), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),

      // Lista (Tabla)
      Expanded(
        child: _conHistorial.isEmpty
            ? const CobEmpty('Sin historial de abonos registrados')
            : Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: _kFondo2.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Cabecera
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _kAzul.withValues(alpha: 0.15),
                        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Cliente', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Tipo / Color', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Detalle Compra', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Total Cobrado', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Padding(padding: EdgeInsets.only(left: 16), child: Text('Pendiente', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12)))),
                          Expanded(flex: 2, child: Text('Acciones', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                    // Cuerpo
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _conHistorial.length,
                        itemBuilder: (context, i) {
                          final venta = _conHistorial[i];
                          final color = venta.saldado ? _kVerde : (venta.progreso >= 0.5 ? _kVerdeClaro : _kAzulClaro);
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: i.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
                              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(venta.cliente, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12))),
                                Expanded(flex: 2, child: Text(venta.color.isEmpty ? venta.tipo.name.toUpperCase() : '${venta.tipo.name.toUpperCase()} · ${venta.color}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                                Expanded(flex: 2, child: Text('${venta.cantidad.toStringAsFixed(0)} u. x Bs ${venta.precioUnit.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                                Expanded(flex: 2, child: Text('Bs ${venta.montoPagado.toStringAsFixed(0)}', textAlign: TextAlign.right, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(left: 16), child: Text('Bs ${venta.pendiente.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 12)))),
                                Expanded(flex: 2, child: Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _kAzulClaro,
                                      side: BorderSide(color: _kAzulClaro.withValues(alpha: 0.5)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.visibility_rounded, size: 16),
                                    label: const Text('Ver detalles', style: TextStyle(fontSize: 12)),
                                    onPressed: () => setState(() => _seleccionada = venta),
                                  )
                                )),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ]);
  }

  // ── Vista detalle ─────────────────────────
  Widget _vistaDetalle(BuildContext context, Venta v) {
    final pagos = List<AbonoVenta>.from(v.historialAbonos)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Column(children: [
      // AppBar detalle
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => setState(() => _seleccionada = null),
          ),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [_kAzulClaro, _kVerdeClaro],
              ).createShader(b),
              child: Text(v.cliente.toUpperCase(),
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ),
            Text('Venta #${v.id}  ·  ${v.color}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10)),
          ])),
        ]),
      ),
      Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_kAzul, _kAzulClaro, _kVerde, _kVerdeClaro]),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(height: 12),

      // Resumen del cliente
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _TarjetaResumenDetalle(venta: v),
      ),
      const SizedBox(height: 14),

      // Título línea de tiempo
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Container(width: 4, height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kAzulClaro, _kVerdeClaro],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text('Línea de tiempo — ${pagos.length} abono(s)',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 13)),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAzulClaro.withValues(alpha: 0.1),
              foregroundColor: _kAzulClaro,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: _kAzulClaro.withValues(alpha: 0.3)),
              ),
            ),
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Comprobante', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () => ReciboPdf.generarEImprimir(v, context),
          ),
        ]),
      ),
      const SizedBox(height: 10),

      // Línea de tiempo (Tabla)
      Expanded(
        child: pagos.isEmpty
            ? const CobEmpty('Sin abonos registrados')
            : Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: _kFondo2.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Cabecera
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _kAzul.withValues(alpha: 0.15),
                        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 1, child: Text('#', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(flex: 3, child: Text('Fecha y Hora', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(flex: 3, child: Text('Nota', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(flex: 1, child: Text('Recibo', textAlign: TextAlign.center, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(flex: 2, child: Text('Monto Abono', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(flex: 2, child: Padding(padding: EdgeInsets.only(left: 16), child: Text('Acumulado (hasta ahí)', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 13)))),
                        ],
                      ),
                    ),
                    // Cuerpo
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: pagos.length,
                        itemBuilder: (context, i) {
                          final pago = pagos[i];
                          final numero = pagos.length - i;
                          final acumulado = pagos.sublist(i).fold(0.0, (s, p) => s + p.monto);
                          final color = numero == 1 ? _kVerdeClaro : _kAzulClaro;
                          
                          String fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: i.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
                              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text('$numero', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 3, child: Text(fmt(pago.fecha), style: const TextStyle(color: Colors.white, fontSize: 13))),
                                Expanded(flex: 3, child: Text(pago.nota.isEmpty ? '-' : pago.nota, style: TextStyle(color: _kVerdeClaro.withValues(alpha: 0.8), fontStyle: FontStyle.italic, fontSize: 13))),
                                Expanded(
                                  flex: 1, 
                                  child: pago.comprobante != null && pago.comprobante!.isNotEmpty
                                      ? Center(
                                          child: IconButton(
                                            icon: const Icon(Icons.receipt_long_rounded, color: _kAzulClaro, size: 20),
                                            tooltip: 'Ver Comprobante',
                                            onPressed: () => _mostrarComprobante(context, pago.comprobante!),
                                          ),
                                        )
                                      : const SizedBox.shrink()
                                ),
                                Expanded(flex: 2, child: Text('Bs ${pago.monto.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(left: 16), child: Text('Bs ${acumulado.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ]);
  }

  void _mostrarComprobante(BuildContext context, String fileName) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'http://localhost/marcali/uploads/comprobantes/$fileName',
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
    );
  }
}


// ── Tarjeta resumen en detalle ─────────────────
class _TarjetaResumenDetalle extends StatelessWidget {
  final Venta venta;
  const _TarjetaResumenDetalle({required this.venta});
  @override
  Widget build(BuildContext context) {
    final color = venta.saldado ? _kVerde : _kAzulClaro;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, 
            children: [
              _Col('Cantidad', '${venta.cantidad.toStringAsFixed(0)} aguayos', Colors.white),
              _Col('Producto', venta.tipo.name.toUpperCase(), Colors.white),
              _Col('Precio Unit.', 'Bs ${venta.precioUnit.toStringAsFixed(2)}', Colors.white70),
            ]
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, 
            children: [
              _Col('Total Venta', 'Bs ${venta.total.toStringAsFixed(2)}', Colors.white70),
              _Col('Cobrado', 'Bs ${venta.montoPagado.toStringAsFixed(2)}', _kVerde),
              _Col('Pendiente', 'Bs ${venta.pendiente.toStringAsFixed(2)}', venta.saldado ? Colors.white38 : _kRojo),
            ]
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String l, v; final Color c;
  const _Col(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w900,
        fontSize: 15)),
    Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.40),
        fontSize: 9)),
  ]);
}

// ── Widgets auxiliares ────────────────────────
class _MiniCard extends StatelessWidget {
  final String label, valor; final Color color; final IconData icono;
  const _MiniCard({required this.label, required this.valor,
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
        Icon(icono, color: color, size: 16),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(color: color,
            fontWeight: FontWeight.w900, fontSize: 13)),
        Text(label, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40), fontSize: 9)),
      ]),
    ),
  );
}

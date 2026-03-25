import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'modelos_compra.dart';
import '../services/api_service.dart';
import '../cobranza/cobranza_widgets.dart';

// ── Paleta BI Premium "Compras" ────────────────
const _kAzulOscuro = Color(0xFF060B18);
const _kFondo2 = Color(0xFF0D1424);
const _kNaranjaAcento = Color(0xFFF97316); 
const _kCyan = Color(0xFF22D3EE);
const _kPurple = Color(0xFF8B5CF6);
const _kCardBg = Color(0xFF111827);
const _kTextoSecundario = Color(0xFF94A3B8);
const _kRojoDeuda = Color(0xFFF43F5E);     
const _kVerdePago = Color(0xFF10B981);     

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> with SingleTickerProviderStateMixin {
  final _srv = ComprasService.instance;
  final _formatoMoneda = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
  final _formatoKilos = NumberFormat.decimalPattern();

  String _busqueda = '';
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _animCtrl.forward();
    _srv.addListener(_onServiceUpdate);
    
    // Carga inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _srv.cargarProveedores();
    });
  }

  @override
  void dispose() {
    _srv.removeListener(_onServiceUpdate);
    _animCtrl.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<Proveedor> get _proveedoresFiltrados {
    final pr = _srv.proveedores;
    if (_busqueda.isEmpty) return pr;
    final b = _busqueda.toLowerCase();
    return pr.where((p) => p.nombre.toLowerCase().contains(b) || p.empresa.toLowerCase().contains(b)).toList();
  }

  double get _deudaTotalGlobal {
    return _srv.proveedores.fold(0, (sum, p) => sum + p.saldoDeudorActual);
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _proveedoresFiltrados;

    return Scaffold(
      backgroundColor: _kAzulOscuro,
      body: Stack(
        children: [
          // Fondo gradiente sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, -0.6),
                  radius: 1.2,
                  colors: [_kPurple.withValues(alpha: 0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, 0.7),
                  radius: 1.0,
                  colors: [_kNaranjaAcento.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildHeroResumen(),
                _buildBuscador(),
                Expanded(
                  child: _srv.cargando && filtrados.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: _kNaranjaAcento))
                      : filtrados.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                              itemCount: filtrados.length,
                              itemBuilder: (context, index) {
                                return _ProveedorRowPremium(
                                  proveedor: filtrados[index],
                                  formatoMoneda: _formatoMoneda,
                                  index: index,
                                  anim: _animCtrl,
                                  onTap: () => _abrirDialHistorial(context, filtrados[index]),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialNuevoProveedor(context),
        backgroundColor: _kNaranjaAcento,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('NUEVO PROVEEDOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COMPRAS', style: TextStyle(
                  color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text('Libro Diario de Proveedores', style: TextStyle(
                  color: _kTextoSecundario, fontSize: 10, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroResumen() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 15))
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4, height: 16,
                    decoration: BoxDecoration(color: _kNaranjaAcento, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  Text('DEUDA TOTAL CONSOLIDADA', style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatoMoneda.format(_deudaTotalGlobal), style: const TextStyle(
                      color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _busqueda = v),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Buscar por empresa o contacto...',
            hintStyle: TextStyle(color: _kTextoSecundario, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: _kNaranjaAcento, size: 22),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.white.withValues(alpha: 0.1), size: 100),
          const SizedBox(height: 16),
          Text('No se encontraron proveedores', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _abrirDialHistorial(BuildContext ctx, Proveedor proveedor) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalCuentaCorriente(proveedor: proveedor),
    );
  }

  void _abrirDialNuevoProveedor(BuildContext ctx) {
    final nombreCtrl = TextEditingController();
    final empresaCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _kAzulOscuro.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const Text('NUEVO PROVEEDOR', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 28),
              _CampoBI(ctrl: empresaCtrl, hint: 'Nombre de la Empresa', ico: Icons.factory_rounded),
              const SizedBox(height: 16),
              _CampoBI(ctrl: nombreCtrl, hint: 'Persona de Contacto', ico: Icons.person_rounded),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNaranjaAcento, 
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
                onPressed: () {
                  final empresa = empresaCtrl.text.trim();
                  final nombre = nombreCtrl.text.trim();
                  if (empresa.isNotEmpty && nombre.isNotEmpty) {
                    _srv.agregarProveedor(nombre, empresa);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('REGISTRAR AHORA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              ))
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REGISTRO PREMIUM — ROW
// ─────────────────────────────────────────────
class _ProveedorRowPremium extends StatelessWidget {
  final Proveedor proveedor;
  final NumberFormat formatoMoneda;
  final int index;
  final AnimationController anim;
  final VoidCallback onTap;

  const _ProveedorRowPremium({
    required this.proveedor,
    required this.formatoMoneda,
    required this.index,
    required this.anim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final saldo = proveedor.saldoDeudorActual;
    final tieneDeuda = saldo > 0;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: anim, curve: Interval(index * 0.05, 1.0, curve: Curves.easeOutCubic))
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: anim, curve: Interval(index * 0.05, 1.0, curve: Curves.easeIn))
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: _kNaranjaAcento.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(proveedor.empresa.substring(0, 1).toUpperCase(), 
                      style: const TextStyle(color: _kNaranjaAcento, fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(proveedor.empresa, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(proveedor.nombre, style: TextStyle(color: _kTextoSecundario.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatoMoneda.format(saldo), style: TextStyle(
                        color: tieneDeuda ? _kRojoDeuda : _kVerdePago, 
                        fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(tieneDeuda ? 'FALTA PAGAR' : 'SALDADO', style: TextStyle(color: (tieneDeuda ? _kRojoDeuda : _kVerdePago).withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MODAL: CUENTA CORRIENTE (ESTILO LIBRO DIARIO)
// ─────────────────────────────────────────────
class _ModalCuentaCorriente extends StatefulWidget {
  final Proveedor proveedor;
  const _ModalCuentaCorriente({required this.proveedor});

  @override
  State<_ModalCuentaCorriente> createState() => _ModalCuentaCorrienteState();
}

class _ModalCuentaCorrienteState extends State<_ModalCuentaCorriente> {
  final _formatoMoneda = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
  final _srv = ComprasService.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _srv,
      builder: (context, child) {
        final saldo = widget.proveedor.saldoDeudorActual;
        final tieneDeuda = saldo > 0;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: BoxDecoration(
            color: _kAzulOscuro,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _kNaranjaAcento.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.menu_book_rounded, color: _kNaranjaAcento, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LIBRO DE CUENTA CORRIENTE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        Text(widget.proveedor.empresa.toUpperCase(), style: const TextStyle(color: _kNaranjaAcento, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Tarjeta Resumen Saldo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DEUDA PENDIENTE', style: TextStyle(color: _kTextoSecundario, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(_formatoMoneda.format(saldo.abs()), style: TextStyle(
                            color: tieneDeuda ? _kRojoDeuda : _kVerdePago, fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _abrirDialInsertarEfectivo(context),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                      label: const Text('ABONAR (FOTO)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(backgroundColor: _kVerdePago, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirDialInsertarMaterial(context),
                  icon: const Icon(Icons.inventory_2_rounded, size: 16),
                  label: const Text('RECIBIR MATERIAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(backgroundColor: _kNaranjaAcento, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 20),
              
              const Align(alignment: Alignment.centerLeft, child: Text('MOVIMIENTOS CONTABLES', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
              const SizedBox(height: 8),
              
              Expanded(
                child: widget.proveedor.historial.isEmpty
                    ? const Center(child: Text('No hay movimientos', style: TextStyle(color: _kTextoSecundario)))
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildTablaContable(widget.proveedor.historial),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTablaContable(List<TransaccionCompra> txs) {
    // Calculamos el saldo acumulado desde el inicio (el historial suele estar en orden inverso de visualización)
    double saldoAcumulado = 0;
    final List<Map<String, dynamic>> filas = [];
    
    // Suponemos que txs viene de ApiService con saldo_acumulado si lo pedimos, pero si no, calculamos:
    // Nota: El historial en el modelo ya viene ordenado por fecha de servidor.
    for (var tx in txs.reversed) {
      bool esEntrada = tx.tipo == TipoTransaccion.entregaMaterial;
      if (esEntrada) {
        saldoAcumulado += (tx.importeCobrado ?? 0);
      } else {
        saldoAcumulado -= (tx.montoPagado ?? 0);
      }
      filas.insert(0, {
        'tx': tx,
        'saldo': saldoAcumulado,
        'esEntrada': esEntrada,
      });
    }

    return DataTable(
      columnSpacing: 15,
      horizontalMargin: 10,
      headingRowHeight: 40,
      dataRowHeight: 45,
      border: TableBorder.all(color: Colors.white.withValues(alpha: 0.1)),
      columns: const [
        DataColumn(label: Text('Fecha', style: TextStyle(color: _kTextoSecundario, fontSize: 11, fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Detalle', style: TextStyle(color: _kTextoSecundario, fontSize: 11, fontWeight: FontWeight.bold))),
        DataColumn(label: Text('FOTO', style: TextStyle(color: _kCyan, fontSize: 11, fontWeight: FontWeight.bold))),
        DataColumn(label: Text('FIRMA', style: TextStyle(color: _kPurple, fontSize: 11, fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Haber (Bs)', style: TextStyle(color: _kTextoSecundario, fontSize: 11, fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Debe (Bs)', style: TextStyle(color: _kTextoSecundario, fontSize: 11, fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Saldo (Bs)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
      ],
      rows: filas.map((f) {
        final TransaccionCompra tx = f['tx'];
        final bool esEntrada = f['esEntrada'];
        final hasPhoto = tx.comprobantePath != null && tx.comprobantePath!.isNotEmpty;
        final hasFirma = tx.firmaB64 != null && tx.firmaB64!.isNotEmpty;

        return DataRow(
          cells: [
            DataCell(Text(DateFormat('dd/MM/yy').format(tx.fecha), style: const TextStyle(color: Colors.white70, fontSize: 11))),
            DataCell(Text(esEntrada ? (tx.detalleMateriaPrima ?? '') : 'Abono/Pago', style: const TextStyle(color: Colors.white, fontSize: 11))),
            DataCell(
              hasPhoto 
                ? IconButton(
                    icon: const Icon(Icons.image_search_rounded, color: _kCyan, size: 20),
                    onPressed: () => _verComprobanteCompleto(context, tx.comprobantePath!),
                  )
                : const SizedBox.shrink()
            ),
            DataCell(
              hasFirma
                ? IconButton(
                    icon: const Icon(Icons.draw_rounded, color: _kPurple, size: 20),
                    onPressed: () => _verFirmaCompleta(context, tx.firmaB64!),
                  )
                : const SizedBox.shrink()
            ),
            DataCell(Text(esEntrada ? _formatoMoneda.format(tx.importeCobrado) : '', style: const TextStyle(color: _kRojoDeuda, fontSize: 11, fontWeight: FontWeight.bold))),
            DataCell(Text(!esEntrada ? _formatoMoneda.format(tx.montoPagado) : '', style: const TextStyle(color: _kVerdePago, fontSize: 11, fontWeight: FontWeight.bold))),
            DataCell(Text(_formatoMoneda.format(f['saldo']), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))),
          ]
        );
      }).toList(),
    );
  }

  void _abrirDialInsertarMaterial(BuildContext ctx) {
    final bolsasCtrl = TextEditingController();
    final kilosXBolCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) {
          String? fotoRuta;
          String? firmaB64;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _kAzulOscuro, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('RECIBIR MATERIAL', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                _CampoBI(ctrl: bolsasCtrl, hint: 'Nº Bolsas', ico: Icons.shopping_bag_rounded, num: true),
                const SizedBox(height: 12),
                _CampoBI(ctrl: kilosXBolCtrl, hint: 'Kg por Bolsa', ico: Icons.scale_rounded, num: true),
                const SizedBox(height: 12),
                _CampoBI(ctrl: montoCtrl, hint: 'Importe Total (Bs.)', ico: Icons.money_rounded, num: true),
                const SizedBox(height: 12),
                _CampoBI(ctrl: obsCtrl, hint: 'Observaciones', ico: Icons.notes_rounded),
                const SizedBox(height: 20),
                
                Row(children: [
                  Expanded(
                    child: _BotonAdjuntarFoto(
                      label: 'FOTO FACTURA',
                      rutaActual: fotoRuta,
                      onRutaCambiada: (ruta) => setStateModal(() => fotoRuta = ruta),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final data = await showDialog<Uint8List>(context: context, builder: (_) => const CobDialogFirma());
                        if (data != null) setStateModal(() => firmaB64 = base64Encode(data));
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
                        ),
                        child: firmaB64 == null
                          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.draw_rounded, color: _kPurple, size: 28),
                              SizedBox(height: 4),
                              Text('FIRMA RECIBIDO', style: TextStyle(color: _kPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                            ])
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(base64Decode(firmaB64!), fit: BoxFit.contain, color: Colors.white),
                            ),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _kNaranjaAcento, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    final b = double.tryParse(bolsasCtrl.text) ?? 0;
                    final k = double.tryParse(kilosXBolCtrl.text) ?? 0;
                    final m = double.tryParse(montoCtrl.text) ?? 0;
                    if (b > 0 && m > 0) {
                      _srv.registrarEntregaMaterial(
                        widget.proveedor, 
                        '${b.toInt()} bolsas a ${k.toInt()}kg', 
                        b * k, m, 
                        comprobantePath: fotoRuta,
                        firmaB64: firmaB64,
                        detalleExtra: obsCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa bolsas y monto.')));
                    }
                  },
                  child: const Text('GUARDAR RÉCORD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ))
              ]),
            ),
          );
        }
      ),
    );
  }

  void _abrirDialInsertarEfectivo(BuildContext ctx) {
    final montoCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) {
          String? fotoRuta;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _kAzulOscuro, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('REGISTRAR ABONO / DEPÓSITO', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                _CampoBI(ctrl: montoCtrl, hint: 'Monto Abonado (Bs.)', ico: Icons.money_rounded, num: true),
                const SizedBox(height: 12),
                _CampoBI(ctrl: obsCtrl, hint: 'Observaciones de depósito', ico: Icons.notes_rounded),
                const SizedBox(height: 16),
                _BotonAdjuntarFoto(
                  label: 'FOTO COMPROBANTE',
                  rutaActual: fotoRuta,
                  onRutaCambiada: (ruta) => setStateModal(() => fotoRuta = ruta),
                ),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _kVerdePago, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    final m = double.tryParse(montoCtrl.text) ?? 0;
                    if (m > 0) {
                      _srv.registrarPagoEfectivo(
                        widget.proveedor, 
                        m, 
                        comprobantePath: fotoRuta,
                        detalleExtra: obsCtrl.text.trim()
                      );
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un monto válido.')));
                    }
                  },
                  child: const Text('REGISTRAR DEPÓSITO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ))
              ]),
            ),
          );
        }
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────

class _CampoBI extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData ico;
  final bool num;
  const _CampoBI({required this.ctrl, required this.hint, required this.ico, this.num = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: num ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: Icon(ico, color: _kNaranjaAcento, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _BotonAdjuntarFoto extends StatelessWidget {
  final String label;
  final String? rutaActual;
  final Function(String?) onRutaCambiada;

  const _BotonAdjuntarFoto({required this.label, this.rutaActual, required this.onRutaCambiada});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picker = ImagePicker();
        final img = await picker.pickImage(source: ImageSource.camera);
        if (img != null) onRutaCambiada(img.path);
      },
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
        ),
        child: rutaActual == null 
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_a_photo_rounded, color: _kCyan, size: 28),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: _kCyan, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ])
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(rutaActual!), fit: BoxFit.cover),
            ),
      ),
    );
  }
}

void _verComprobanteCompleto(BuildContext context, String path) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(path)),
          ),
          Positioned(right: 10, top: 10, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))))
        ],
      ),
    )
  );
}

void _verFirmaCompleta(BuildContext context, String b64) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('FIRMA DE CONFORMIDAD', style: TextStyle(fontWeight: FontWeight.bold, color: _kAzulOscuro)),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Image.memory(base64Decode(b64), color: _kAzulOscuro),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR'))
        ],
      ),
    )
  );
}

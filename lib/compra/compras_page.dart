import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'modelos_compra.dart';

const _kAzulOscuro = Color(0xFF0D1424);
const _kNaranjaAcento = Color(0xFFF97316); // Orange 500
const _kNaranjaClaro = Color(0xFFFB923C);  // Orange 400
const _kCardBg = Color(0xFF172036);
const _kTextoSecundario = Color(0xFF94A3B8);
const _kRojoDeuda = Color(0xFFEF4444);     // Red 500
const _kVerdePago = Color(0xFF10B981);     // Emerald 500

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
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animCtrl.forward();
    _srv.addListener(_onServiceUpdate);
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
          // Fondos Decorativos
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kNaranjaAcento.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kNaranjaClaro.withValues(alpha: 0.1), Colors.transparent],
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
                  child: filtrados.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 120, left: 16, right: 16),
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            return SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
                                CurvedAnimation(parent: _animCtrl, curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic))
                              ),
                              child: FadeTransition(
                                opacity: Tween<double>(begin: 0, end: 1).animate(
                                  CurvedAnimation(parent: _animCtrl, curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut))
                                ),
                                child: _ProveedorCard(
                                  proveedor: filtrados[index],
                                  formatoMoneda: _formatoMoneda,
                                  onVerDetalle: (prov) => _abrirDialHistorial(context, prov),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirDialNuevoProveedor(context),
        backgroundColor: _kNaranjaAcento,
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
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
          const Text('Compras y Proveedores', style: TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildHeroResumen() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNaranjaAcento, Color(0xFFC2410C)], // Orange 500 to Orange 700
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kNaranjaAcento.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.local_shipping_rounded, size: 120, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DEUDA TOTAL A PROVEEDORES', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(_formatoMoneda.format(_deudaTotalGlobal), style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
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
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _busqueda = v),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Buscar proveedor o empresa...',
            hintStyle: const TextStyle(color: _kTextoSecundario, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: _kTextoSecundario, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.factory_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 60),
          ),
          const SizedBox(height: 16),
          const Text('No hay proveedores registrados', style: TextStyle(
              color: _kTextoSecundario, fontSize: 15)),
        ],
      ),
    );
  }

  // ─── MODAL: DETALLE CUENTA CORRIENTE ────────────────────────
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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kCardBg.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Nuevo Proveedor', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              _CampoG(ctrl: empresaCtrl, hint: 'Empresa (ej: Hilos El Sol)', ico: Icons.factory_rounded, num: false),
              const SizedBox(height: 12),
              _CampoG(ctrl: nombreCtrl, hint: 'Nombre del Contacto', ico: Icons.person_rounded, num: false),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kNaranjaAcento, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  final empresa = empresaCtrl.text.trim();
                  final nombre = nombreCtrl.text.trim();
                  if (empresa.isNotEmpty && nombre.isNotEmpty) {
                    _srv.agregarProveedor(nombre, empresa);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Guardar Proveedor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ))
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UI Components Locales
// ─────────────────────────────────────────────

class _ProveedorCard extends StatelessWidget {
  final Proveedor proveedor;
  final NumberFormat formatoMoneda;
  final Function(Proveedor) onVerDetalle;

  const _ProveedorCard({
    required this.proveedor,
    required this.formatoMoneda,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final saldo = proveedor.saldoDeudorActual;
    final tieneDeuda = saldo > 0;

    return GestureDetector(
      onTap: () => onVerDetalle(proveedor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                left: -20, top: -20,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _kNaranjaAcento.withValues(alpha: 0.05),
                      Colors.transparent
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF334155), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Center(
                        child: Text(proveedor.empresa.substring(0, 1).toUpperCase(), 
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(proveedor.empresa, style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text(proveedor.nombre, style: const TextStyle(color: _kTextoSecundario, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Falta pagar:', style: TextStyle(color: _kTextoSecundario, fontSize: 10, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(formatoMoneda.format(saldo), style: TextStyle(
                            color: tieneDeuda ? _kRojoDeuda : _kVerdePago, 
                            fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                        if (!tieneDeuda && saldo < 0) 
                          Text('Plata a nuestro favor', style: TextStyle(color: _kVerdePago.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w800))
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalCuentaCorriente extends StatefulWidget {
  final Proveedor proveedor;
  const _ModalCuentaCorriente({required this.proveedor});

  @override
  State<_ModalCuentaCorriente> createState() => _ModalCuentaCorrienteState();
}

class _ModalCuentaCorrienteState extends State<_ModalCuentaCorriente> {
  final _formatoMoneda = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
  final _formatoFecha = DateFormat('EEEE d \'de\' MMMM yyyy', 'es'); // ej. "jueves 10 de febrero 2026"
  final _srv = ComprasService.instance;

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios para repintar
    return ListenableBuilder(
      listenable: _srv,
      builder: (context, child) {
        final saldo = widget.proveedor.saldoDeudorActual;
        final tieneDeuda = saldo > 0;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: BoxDecoration(
            color: _kAzulOscuro,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10))),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cuenta Corriente',
                            style: const TextStyle(color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        Text(widget.proveedor.empresa,
                            style: const TextStyle(color: _kNaranjaAcento,
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Tarjeta Resumen Saldo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL QUE NOS FALTA PAGAR', style: TextStyle(color: _kTextoSecundario, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(_formatoMoneda.format(saldo.abs()), style: TextStyle(
                            color: tieneDeuda ? _kRojoDeuda : _kVerdePago, fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (tieneDeuda ? _kRojoDeuda : _kVerdePago).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tieneDeuda ? 'Debo al Proveedor' : 'Saldo a Nuestro Favor', style: TextStyle(
                          color: tieneDeuda ? _kRojoDeuda : _kVerdePago, fontSize: 12, fontWeight: FontWeight.w800)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Botones de Acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _abrirDialInsertarEfectivo(context),
                      icon: const Icon(Icons.attach_money_rounded, size: 16),
                      label: const Text('Abonar Dinero', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kVerdePago, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _abrirDialInsertarMaterial(context),
                      icon: const Icon(Icons.inventory_2_rounded, size: 16),
                      label: const Text('Recibir Material', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kNaranjaAcento, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('DETALLE DE MOVIMIENTOS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1))),
              const SizedBox(height: 8),
              
              Expanded(
                child: widget.proveedor.historial.isEmpty
                    ? const Center(child: Text('No hay historial', style: TextStyle(color: _kTextoSecundario)))
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildTablaExcel(widget.proveedor.historial.reversed.toList()), // Reversed to calculate balances from old to new
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTablaExcel(List<TransaccionCompra> transacciones) {
    double saldoAcumulado = 0;
    
    // Primero, precalcular saldos acumulados ascendentes (de más viejo a más nuevo)
    final List<Map<String, dynamic>> filas = [];
    for (var tx in transacciones) {
      bool esEntrada = tx.tipo == TipoTransaccion.entregaMaterial;
      if (esEntrada) {
        saldoAcumulado += (tx.importeCobrado ?? 0);
      } else {
        saldoAcumulado -= (tx.montoPagado ?? 0);
      }
      filas.insert(0, { // Insert in reverse so newest is on top of display
        'tx': tx,
        'saldoLinea': saldoAcumulado,
        'esEntrada': esEntrada,
      });
    }

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 48,
      headingRowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.4)),
      horizontalMargin: 12,
      columnSpacing: 20,
      border: TableBorder.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
      columns: const [
        DataColumn(label: Text('Fecha', style: TextStyle(color: _kTextoSecundario, fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Detalle', style: TextStyle(color: _kTextoSecundario, fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Costo (Bs)', style: TextStyle(color: _kTextoSecundario, fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Abonado (Bs)', style: TextStyle(color: _kTextoSecundario, fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Falta (Bs)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
      ],
      rows: filas.map((fila) {
        final TransaccionCompra tx = fila['tx'];
        final double saldoLinea = fila['saldoLinea'];
        final bool esEntrada = fila['esEntrada'];

        return DataRow(
          cells: [
            DataCell(Text(DateFormat('dd/MM/yy').format(tx.fecha), style: const TextStyle(color: Colors.white, fontSize: 12))),
            DataCell(Text(esEntrada ? '${tx.detalleMateriaPrima}' : 'Pago/Abono', 
                style: const TextStyle(color: Colors.white, fontSize: 12))),
            DataCell(Text(esEntrada ? _formatoMoneda.format(tx.importeCobrado) : '', 
                style: const TextStyle(color: _kRojoDeuda, fontWeight: FontWeight.bold, fontSize: 12))),
            DataCell(Text(!esEntrada ? _formatoMoneda.format(tx.montoPagado) : '', 
                style: const TextStyle(color: _kVerdePago, fontWeight: FontWeight.bold, fontSize: 12))),
            DataCell(Text(_formatoMoneda.format(saldoLinea), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
          ],
        );
      }).toList(),
    );
  }

  void _abrirDialInsertarMaterial(BuildContext ctx) {
    final bolsasCtrl = TextEditingController();
    final kilosXBolCtrl = TextEditingController();
    final montoCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kCardBg.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Recibir Material', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              _CampoG(ctrl: bolsasCtrl, hint: 'Nº Bolsas (ej: 38)', ico: Icons.shopping_bag_rounded, num: true),
              const SizedBox(height: 12),
              _CampoG(ctrl: kilosXBolCtrl, hint: 'Kg por Bolsa (ej: 6)', ico: Icons.scale_rounded, num: true),
              const SizedBox(height: 12),
              _CampoG(ctrl: montoCtrl, hint: 'Importe Cobrado (Bs.)', ico: Icons.money_rounded, num: true),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kNaranjaAcento, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  final bolsas = double.tryParse(bolsasCtrl.text) ?? 0;
                  final kilos = double.tryParse(kilosXBolCtrl.text) ?? 0;
                  final monto = double.tryParse(montoCtrl.text) ?? 0;
                  if (bolsas > 0 && monto > 0) {
                    _srv.registrarEntregaMaterial(
                      widget.proveedor, 
                      '${bolsas.toInt()} bolsas a ${kilos.toInt()}kg', 
                      bolsas * kilos, 
                      monto
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Registrar Deuda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ))
            ]),
          ),
        ),
      ),
    );
  }

  void _abrirDialInsertarEfectivo(BuildContext ctx) {
    final montoCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kCardBg.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Abonar Dinero', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              _CampoG(ctrl: montoCtrl, hint: 'Monto a pagar (Bs.)', ico: Icons.payments_rounded, num: true),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kVerdePago, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  final monto = double.tryParse(montoCtrl.text) ?? 0;
                  if (monto > 0) {
                    _srv.registrarPagoEfectivo(widget.proveedor, monto);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Registrar Abono', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ))
            ]),
          ),
        ),
      ),
    );
  }
}

class _CampoG extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData ico;
  final bool num;
  const _CampoG({required this.ctrl, required this.hint, required this.ico, required this.num});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextoSecundario, fontSize: 14),
        prefixIcon: Icon(ico, color: _kTextoSecundario, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}

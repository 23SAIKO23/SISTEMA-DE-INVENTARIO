import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'modelos_salarios.dart';
import 'historial/historial_pagos.dart'; // Import nuevo
import '../services/notificaciones_service.dart';

// ── Paleta y Constantes Premium ────────────────
const _kVerdeAcento = Color(0xFF14B8A6); // Teal 500
const _kVerdeClaro = Color(0xFF2DD4BF);  // Teal 400
const _kAzulOscuro = Color(0xFF0D1424);  // Fondo Profundo
const _kCardBg = Color(0xFF172036);      // Cards
const _kTextoSecundario = Color(0xFF94A3B8); // Slate 400

// ─────────────────────────────────────────────
// Pagos Page
// ─────────────────────────────────────────────
class PagosPage extends StatefulWidget {
  const PagosPage({super.key});

  @override
  State<PagosPage> createState() => _PagosPageState();
}

class _PagosPageState extends State<PagosPage> with SingleTickerProviderStateMixin {
  final _srv = SalariosService.instance;
  final _formatoMoneda = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
  final _formatoFecha = DateFormat('dd MMM yyyy');

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

  List<Trabajador> get _trabajadoresFiltrados {
    final tr = _srv.trabajadores;
    if (_busqueda.isEmpty) return tr;
    final b = _busqueda.toLowerCase();
    return tr.where((t) => t.nombre.toLowerCase().contains(b) || t.cargo.toLowerCase().contains(b)).toList();
  }

  double get _planillaTotal {
    return _srv.trabajadores.fold(0, (sum, t) => sum + t.salarioBase);
  }

  double get _pagadoEsteMes {
    final mesActual = _obtenerMesActual();
    return _srv.trabajadores.fold(0, (sum, t) {
      final pagoMes = t.historialPagos.where((p) => p.mesCorrespondiente == mesActual).toList();
      if (pagoMes.isNotEmpty) return sum + pagoMes.first.monto;
      return sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _trabajadoresFiltrados;

    return Scaffold(
      backgroundColor: _kAzulOscuro,
      body: Stack(
        children: [
          // ── Fondos Decorativos ──
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kVerdeAcento.withValues(alpha: 0.15), Colors.transparent],
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
                  colors: [_kVerdeClaro.withValues(alpha: 0.1), Colors.transparent],
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
                  child: _srv.isLoading 
                      ? const Center(child: CircularProgressIndicator(color: _kVerdeAcento))
                      : filtrados.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 120),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.08)),
                                    dataRowColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                      return Colors.transparent;
                                    }),
                                    dividerThickness: 0.5,
                                    columnSpacing: 24,
                                    headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                                    columns: const [
                                      DataColumn(label: Text('N°')),
                                      DataColumn(label: Text('NOMBRE COMPLETO')),
                                      DataColumn(label: Text('CARGO')),
                                      DataColumn(label: Text('INGRESO O PAGO')),
                                      DataColumn(label: Text('SALARIO BASE')),
                                      DataColumn(label: Text('ACCIONES')),
                                    ],
                                    rows: List<DataRow>.generate(filtrados.length, (index) {
                                      final t = filtrados[index];
                                      return DataRow(
                                        color: WidgetStateProperty.all(index.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.03)),
                                        cells: [
                                          DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.white70))),
                                          DataCell(Text(t.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                          DataCell(Text(t.cargo, style: const TextStyle(color: _kVerdeClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataCell(Text('${t.fechaIngreso.day}/${t.fechaIngreso.month}/${t.fechaIngreso.year} (Día ${t.fechaIngreso.day})', style: const TextStyle(color: Colors.white70))),
                                          DataCell(Text(_formatoMoneda.format(t.salarioBase), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                                          DataCell(Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.payment_rounded, color: _kVerdeAcento, size: 20),
                                                tooltip: 'Registrar Pago',
                                                splashRadius: 20,
                                                onPressed: () => _abrirDialRegistrarPago(context, t),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.history_rounded, color: Colors.white70, size: 20),
                                                tooltip: 'Ver Historial',
                                                splashRadius: 20,
                                                onPressed: () => _abrirDialHistorial(context, t),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent, size: 20),
                                                tooltip: 'Probar Notificación Ahora',
                                                splashRadius: 20,
                                                onPressed: () {
                                                   NotificacionesService.instance.programarRecordatorioPago(
                                                      idNotificacion: t.id.hashCode + 999,
                                                      nombreTrabajador: t.nombre,
                                                      fechaIngreso: DateTime.now().add(const Duration(days: 1)),
                                                   );
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Notificación de prueba programada para mañana (ver consola)')),
                                                   );
                                                },
                                              ),
                                            ],
                                          )),
                                        ]
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kVerdeAcento,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nuevo Trabajador', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _abrirDialNuevoTrabajador(context),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('Nómina de Salarios', style: TextStyle(
                  color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialPagosPage())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kVerdeAcento.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kVerdeAcento.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, color: _kVerdeAcento, size: 16),
                  const SizedBox(width: 6),
                  const Text('Reportes', style: TextStyle(color: _kVerdeAcento, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeroResumen() {
    final progreso = _planillaTotal > 0 ? _pagadoEsteMes / _planillaTotal : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kVerdeAcento, Color(0xFF0F766E)], // Teal 500 to Teal 700
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kVerdeAcento.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Patrón aguayo verde superpuesto sutílmente
          Positioned(
            right: -30, top: -30,
            child: Icon(Icons.payments_rounded, size: 120, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL PLANILLA - ${_obtenerMesActual()}', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(_formatoMoneda.format(_planillaTotal), style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pagado Este Mes', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                      Text(_formatoMoneda.format(_pagadoEsteMes), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Restante', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                      Text(_formatoMoneda.format(_planillaTotal - _pagadoEsteMes), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 8,
                  backgroundColor: Colors.black.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
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
            hintText: 'Buscar empleado o cargo...',
            hintStyle: TextStyle(
                color: _kTextoSecundario, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: _kTextoSecundario, size: 20),
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
            child: Icon(Icons.people_alt_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 60),
          ),
          const SizedBox(height: 16),
          Text('No se encontraron empleados', style: TextStyle(
              color: _kTextoSecundario, fontSize: 15)),
        ],
      ),
    );
  }

  void _abrirDialNuevoTrabajador(BuildContext ctx) {
    final nombreCtrl = TextEditingController();
    final cargoCtrl = TextEditingController();
    final salarioCtrl = TextEditingController();
    DateTime fechaIngreso = DateTime.now();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctxModal, setStateModal) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kCardBg.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, -5)),
              ]
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10))),
              
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kVerdeClaro, _kVerdeAcento]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _kVerdeAcento.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nuevo Personal',
                            style: TextStyle(color: Colors.white, fontSize: 22,
                                fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const Text('Registrar Nómina',
                            style: TextStyle(color: _kVerdeClaro,
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              _CampoInputGlass(ctrl: nombreCtrl, label: 'Nombre Completo',
                  icono: Icons.badge_rounded),
              const SizedBox(height: 16),
              _CampoInputGlass(ctrl: cargoCtrl, label: 'Cargo (p.ej. Costurera)',
                  icono: Icons.work_outline_rounded),
              const SizedBox(height: 16),
              _CampoInputGlass(ctrl: salarioCtrl, label: 'Salario Base Mensual (Bs)',
                  icono: Icons.monetization_on_rounded, numerico: true),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: () async {
                  final seleccion = await showDatePicker(
                    context: ctx,
                    initialDate: fechaIngreso,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (seleccion != null) {
                    setStateModal(() => fechaIngreso = seleccion);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: _kVerdeAcento, size: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha de Ingreso / Contrato', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                          Text('${fechaIngreso.day}/${fechaIngreso.month}/${fechaIngreso.year}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeAcento,
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shadowColor: _kVerdeAcento.withValues(alpha:  0.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final s = double.tryParse(salarioCtrl.text);
                  if (nombreCtrl.text.trim().isNotEmpty && s != null) {
                    _srv.agregarTrabajador(nombreCtrl.text.trim(), cargoCtrl.text.trim(), s, fechaIngreso);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Registrar Empleado', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5)),
              )),
              const SizedBox(height: 10),
            ]),
          ),
        ),
      ),
      ),
    );
  }

  void _abrirDialRegistrarPago(BuildContext ctx, Trabajador trabajador) {
    final montoCtrl = TextEditingController(text: trabajador.salarioBase.toStringAsFixed(2));
    final mesCtrl = TextEditingController(text: _obtenerMesActual());
    
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
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, -5)),
              ]
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10))),
              
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kVerdeClaro, _kVerdeAcento]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _kVerdeAcento.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: const Icon(Icons.payments_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pagar Salario',
                            style: TextStyle(color: Colors.white, fontSize: 22,
                                fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        Text(trabajador.nombre,
                            style: const TextStyle(color: _kVerdeClaro,
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              _CampoInputGlass(ctrl: montoCtrl, label: 'Monto a Pagar (Bs.)',
                  icono: Icons.money_rounded, numerico: true),
              const SizedBox(height: 16),
              _CampoInputGlass(ctrl: mesCtrl, label: 'Mes Correspondiente',
                  icono: Icons.calendar_month_rounded),
              const SizedBox(height: 32),
              
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeAcento,
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shadowColor: _kVerdeAcento.withValues(alpha:  0.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final monto = double.tryParse(montoCtrl.text);
                  if (monto != null && monto > 0 && mesCtrl.text.trim().isNotEmpty) {
                    _srv.registrarPago(trabajador, monto, mesCtrl.text.trim());
                    Navigator.pop(ctx);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded, color: _kVerdeAcento, size: 16),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text('Pago de ${_formatoMoneda.format(monto)} registrado con éxito.', style: const TextStyle(fontWeight: FontWeight.w600))),
                          ]),
                        ),
                        backgroundColor: _kVerdeAcento,
                        behavior: SnackBarBehavior.floating,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        duration: const Duration(seconds: 3),
                      )
                    );
                  }
                },
                child: const Text('Confirmar Pago', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5)),
              )),
              const SizedBox(height: 10),
            ]),
          ),
        ),
      ),
    );
  }

  void _abrirDialHistorial(BuildContext ctx, Trabajador trabajador) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
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
                  child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Historial de Pagos',
                          style: TextStyle(color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      Text(trabajador.nombre,
                          style: const TextStyle(color: _kVerdeClaro,
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18)
                  ),
                  onPressed: () => Navigator.pop(ctx),
                )
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: trabajador.historialPagos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 60, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          Text('Sin pagos registrados', style: TextStyle(color: _kTextoSecundario, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: trabajador.historialPagos.length,
                      itemBuilder: (context, index) {
                        final pago = trabajador.historialPagos[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: _kVerdeAcento.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: _kVerdeClaro, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pago.mesCorrespondiente, style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(_formatoFecha.format(pago.fecha), style: TextStyle(
                                        color: _kTextoSecundario, fontSize: 12, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Abonado', style: TextStyle(color: _kVerdeClaro, fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(_formatoMoneda.format(pago.monto), style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _obtenerMesActual() {
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    final now = DateTime.now();
    return '${meses[now.month - 1]} ${now.year}';
  }
}

// ── Componentes de la UI ─────────────────────────

class _CampoInputGlass extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icono;
  final bool numerico;
  
  const _CampoInputGlass({
    required this.ctrl, 
    required this.label,
    required this.icono, 
    this.numerico = false,
  });
  
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ]
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: numerico ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: _kTextoSecundario, fontSize: 14, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icono, color: _kVerdeAcento, size: 22),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _kVerdeAcento, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
      ),
    ),
  );
}

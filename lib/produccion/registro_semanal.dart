import 'package:flutter/material.dart';
import 'modelos_produccion.dart';

// ── Paleta ─────────────────────────────────────
const _kAzul       = Color(0xFF1565C0);
const _kAzulClaro  = Color(0xFF42A5F5);
const _kVerde      = Color(0xFF00C853);
const _kVerdeClaro = Color(0xFF69F0AE);
const _kFondo      = Color(0xFF0A1628);
const _kFondo2     = Color(0xFF0D2145);
const _kRojo       = Color(0xFFEF5350);

// ─────────────────────────────────────────────
//  Registro Semanal — Acumulable
// ─────────────────────────────────────────────
class RegistroSemanalPage extends StatefulWidget {
  const RegistroSemanalPage({super.key});
  @override
  State<RegistroSemanalPage> createState() => _RegistroSemanalPageState();
}

class _RegistroSemanalPageState extends State<RegistroSemanalPage> {
  final _svc = ProduccionService.instance;
  String _busqueda = '';

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

  List<Maquina> get _filtradas {
    return _svc.maquinas.where((m) {
      if (_busqueda.isEmpty) return true;
      final b = _busqueda.toLowerCase();
      return m.nombre.toLowerCase().contains(b) ||
             m.trabajadorAsignado.toLowerCase().contains(b);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final maquinas = _filtradas;
    
    // Asumimos que todas las máquinas comparten la misma semana activa
    // Si no hay máquinas creadas, no hay semana activa
    RegistroSemana? semActiva = maquinas.isNotEmpty ? maquinas.first.semanaActual : null;
    final totalSemana = _svc.totalSemanaActual;
    final esDomingo = DateTime.now().weekday == DateTime.sunday;

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
          const ProdAppBar(titulo: 'REGISTRO SEMANAL',
              subtitulo: 'Acumulado semanal de aguayos por máquina'),

          // Banner de la semana actual
          if (semActiva != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _kAzulClaro.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kAzulClaro.withValues(alpha: 0.50)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SEMANA EN CURSO', style: TextStyle(
                        color: _kAzulClaro.withValues(alpha: 0.8),
                        fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 2),
                    Text(semActiva.etiquetaSemana, style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  ]),
                  
                  if (esDomingo)
                    ElevatedButton.icon(
                      onPressed: () => _confirmarCierreSemana(context),
                      icon: const Icon(Icons.archive_rounded, size: 16),
                      label: const Text('Cerrar', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRojo, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lock_clock_rounded, size: 14,
                            color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(width: 4),
                        Text('Cierre el Domingo', style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                ]),
              ),
            ),

          // Buscador y Resumen General
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(children: [
              Expanded(child: _Buscador(
                  onChanged: (v) => setState(() => _busqueda = v))),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kVerde.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kVerde.withValues(alpha: 0.40)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.inventory_2_rounded, color: _kVerde, size: 15),
                  const SizedBox(height: 4),
                  Text('${totalSemana.toStringAsFixed(0)} uds', style: const TextStyle(color: _kVerde,
                      fontWeight: FontWeight.w900, fontSize: 13)),
                  Text('Total semanal', style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40), fontSize: 9)),
                ]),
              ),
            ]),
          ),

          // ── Resumen por Colores ──
          if (_svc.totalSemanaActualPorColor.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _svc.totalSemanaActualPorColor.entries.map((e) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.palette_rounded, size: 12, color: _kAzulClaro.withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.key.toUpperCase(), style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5), fontSize: 9, 
                            fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                        Text('${e.value.toStringAsFixed(0)} uds', style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 10),

          // Lista de máquinas
          Expanded(
            child: maquinas.isEmpty
                ? const ProdEmpty('Sin máquinas agregadas aún')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: maquinas.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onLongPress: () => _confirmarEliminarMaquina(context, maquinas[i]),
                      child: _TarjetaMaquina(
                        maquina: maquinas[i],
                        onAdd: () => _abrirDialProduccion(context, maquinas[i]),
                        onAddColor: (c) => _abrirDialProduccion(context, maquinas[i], colorPredefinido: c),
                      ),
                    ),
                  ),
          ),
        ])),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAzulClaro,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva máquina',
            style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _abrirDialNuevaMaquina(context),
      ),
    );
  }

  void _confirmarCierreSemana(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kFondo2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _kRojo.withValues(alpha: 0.5))),
      title: const Text('Cerrar Semana', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: const Text(
          'El acumulado de esta semana se guardará en el historial de las máquinas y empezará una semana nueva en cero.\n\n¿Estás seguro?',
          style: TextStyle(color: Colors.white70, fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kRojo, foregroundColor: Colors.white),
          onPressed: () {
            _svc.cerrarSemanaTodos();
            Navigator.pop(context);
          },
          child: const Text('Cerrar Semana', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  // ── Modals ──────────────────────────────────
  void _abrirDialProduccion(BuildContext ctx, Maquina mq, {String? colorPredefinido}) {
    final ctrl = TextEditingController();
    final colorCtrl = TextEditingController(text: colorPredefinido ?? '');
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: const BoxDecoration(
            color: Color(0xFF0D2145),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: _kVerde.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(4))),
            Text('Sumar a la semana actual',
                style: const TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${mq.nombre} • Trab. ${mq.trabajadorAsignado}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 12)),
            const SizedBox(height: 20),
            
            _Campo(ctrl: colorCtrl, label: 'Color (ej. Azul, Rojo...)',
                icono: Icons.palette_rounded),
            const SizedBox(height: 12),
            _Campo(ctrl: ctrl, label: 'Cantidad a SUMAR',
                icono: Icons.add_box_rounded, numerico: true),
            const SizedBox(height: 20),
            
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kVerde, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final cant = double.tryParse(ctrl.text);
                if (cant != null && cant > 0) {
                  final color = colorCtrl.text.trim().isEmpty ? 'S/C' : colorCtrl.text.trim();
                  _svc.registrarProduccionActual(mq.id, color, cant);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Sumar Producción', style: TextStyle(fontWeight: FontWeight.w800)),
            )),
          ]),
        ),
      ),
    );
  }

  void _abrirDialNuevaMaquina(BuildContext ctx) {
    final nCtrl = TextEditingController();
    final tCtrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: const BoxDecoration(
            color: Color(0xFF0D2145),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: _kAzulClaro.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(4))),
            const Text('Agregar Nueva Máquina',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            
            _Campo(ctrl: nCtrl, label: 'Nombre de Máquina (ej. Máquina 5)',
                icono: Icons.precision_manufacturing_rounded),
            const SizedBox(height: 12),
            _Campo(ctrl: tCtrl, label: 'Trabajador asignado',
                icono: Icons.person_rounded),
            const SizedBox(height: 20),
            
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAzulClaro, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (nCtrl.text.trim().isEmpty || tCtrl.text.trim().isEmpty) return;
                final m = Maquina(
                  id: 'M${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                  nombre: nCtrl.text.trim(),
                  trabajadorAsignado: tCtrl.text.trim(),
                );
                _svc.agregarMaquina(m);
                Navigator.pop(ctx);
              },
              child: const Text('Crear Máquina', style: TextStyle(fontWeight: FontWeight.w800)),
            )),
          ]),
        ),
      ),
    );
  }

  void _confirmarEliminarMaquina(BuildContext ctx, Maquina mq) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: _kFondo2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _kRojo.withValues(alpha: 0.5))),
      title: const Text('Eliminar Máquina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(
          '¿Desea eliminar la máquina "${mq.nombre}" creada por error?',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kRojo, foregroundColor: Colors.white),
          onPressed: () {
            _svc.eliminarMaquina(mq.id);
            Navigator.pop(ctx);
          },
          child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }
}

// ── Tarjeta de Máquina ───────────────────────
class _TarjetaMaquina extends StatelessWidget {
  final Maquina maquina;
  final VoidCallback onAdd;
  final Function(String) onAddColor;
  const _TarjetaMaquina({required this.maquina, required this.onAdd, required this.onAddColor});

  @override
  Widget build(BuildContext context) {
    final acts = maquina.semanaActual;
    final acumu = acts?.cantidadAcumulada ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: _kFondo2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kAzulClaro.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: _kAzulClaro.withValues(alpha: 0.08),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar máquina
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kAzul, _kAzulClaro],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Icon(Icons.precision_manufacturing_rounded, 
              color: Colors.white, size: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(maquina.nombre, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.person_rounded, size: 12, color: _kVerdeClaro.withValues(alpha: 0.80)),
              const SizedBox(width: 4),
              Text(maquina.trabajadorAsignado, style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60), fontSize: 12)),
            ]),
          ])),
          const SizedBox(width: 8),
          
          // Bloque producción semana actual
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${acumu.toStringAsFixed(0)}', style: TextStyle(
                color: acumu > 0 ? _kVerde : Colors.white70,
                fontWeight: FontWeight.w900, fontSize: 24)),
            Text('uds en la sem', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40), fontSize: 9)),
          ]),
          const SizedBox(width: 14),
          
          // Botón sumar
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _kVerde.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kVerde.withValues(alpha: 0.40)),
              ),
              child: const Icon(Icons.add_rounded, color: _kVerde, size: 22),
            ),
          ),
        ]),

        // Desglose de colores
        if (acts != null && acts.produccionPorColor.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: acts.produccionPorColor.entries.map((e) =>
                GestureDetector(
                  onTap: () => onAddColor(e.key),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _kAzulClaro.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kAzulClaro.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.palette_rounded, size: 18, color: _kAzulClaro.withValues(alpha: 0.9)),
                          const SizedBox(width: 8),
                          Text(e.key.toUpperCase(), style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8), 
                              fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ]),
                        Row(children: [
                          Text('${e.value.toStringAsFixed(0)}', style: const TextStyle(
                              color: _kAzulClaro, fontWeight: FontWeight.w900, fontSize: 18)),
                          const SizedBox(width: 4),
                          Text('uds', style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kVerde,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(children: [
                              Icon(Icons.add_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Sumar', style: TextStyle(color: Colors.white, 
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                            ]),
                          )
                        ]),
                      ]),
                  ),
                )
              ).toList(),
            ),
          )
        ],
      ]),
    );
  }
}

// ── Widgets internos ──────────────────────────
class _Buscador extends StatelessWidget {
  final Function(String) onChanged;
  const _Buscador({required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Buscar máquina o trabajador...',
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.30), fontSize: 12),
        prefixIcon: Icon(Icons.search_rounded,
            color: _kAzulClaro.withValues(alpha: 0.70), size: 17),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
      ),
    ),
  );
}

// ── Widgets compartidos prod ──────────────────
class ProdAppBar extends StatelessWidget {
  final String titulo, subtitulo;
  const ProdAppBar({super.key, required this.titulo, required this.subtitulo});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_kAzulClaro, _kVerdeClaro],
            ).createShader(b),
            child: Text(titulo, style: const TextStyle(
                color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w900, letterSpacing: 2)),
          ),
          Text(subtitulo, style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10, letterSpacing: 0.8)),
        ]),
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
  ]);
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icono;
  final bool numerico;
  const _Campo({required this.ctrl, required this.label,
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
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kAzulClaro, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
    ),
  );
}

class ProdEmpty extends StatelessWidget {
  final String msg;
  const ProdEmpty(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_rounded,
          color: _kAzulClaro.withValues(alpha: 0.30), size: 60),
      const SizedBox(height: 12),
      Text(msg, style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
          textAlign: TextAlign.center),
    ]),
  );
}

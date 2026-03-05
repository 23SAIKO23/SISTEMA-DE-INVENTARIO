import 'package:flutter/material.dart';
import 'modelos_cliente.dart';
import 'historial_compras.dart';
import 'control_deudas.dart';
import 'semaforo_pago.dart';

export 'modelos_cliente.dart';

// ─────────────────────────────────────────────
//  Página principal de Clientes
// ─────────────────────────────────────────────
class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  String _busqueda = '';

  // Datos de ejemplo
  final List<Cliente> _clientes = [
    Cliente(
      id: '1',
      nombre: 'Tienda Don Pepe',
      telefono: '70012345',
      direccion: 'Av. Potosí 123',
      tipo: TipoCliente.tienda,
      saldoPendiente: 350.0,
      estadoPago: EstadoPago.seRetrasa,
      fechaRegistro: DateTime(2024, 3, 10),
    ),
    Cliente(
      id: '2',
      nombre: 'Doña Carmen',
      telefono: '71198765',
      direccion: 'Calle Junín 45',
      tipo: TipoCliente.casera,
      saldoPendiente: 0.0,
      estadoPago: EstadoPago.puntual,
      fechaRegistro: DateTime(2024, 5, 22),
    ),
    Cliente(
      id: '3',
      nombre: 'Distribuidora Alteña',
      telefono: '72345678',
      direccion: 'El Alto, Zona 16 de Julio',
      tipo: TipoCliente.departamento,
      saldoPendiente: 1200.0,
      estadoPago: EstadoPago.riesgo,
      fechaRegistro: DateTime(2023, 11, 1),
    ),
    Cliente(
      id: '4',
      nombre: 'Tienda La Estrella',
      telefono: '68899001',
      direccion: 'Mercado Rodríguez',
      tipo: TipoCliente.tienda,
      saldoPendiente: 80.0,
      estadoPago: EstadoPago.puntual,
      fechaRegistro: DateTime(2025, 1, 15),
    ),
  ];

  List<Cliente> get _filtrados {
    final q = _busqueda.toLowerCase();
    return _clientes.where((c) {
      final matchTab = _tabCtrl.index == 0 ||
          (_tabCtrl.index == 1 && c.tipo == TipoCliente.tienda) ||
          (_tabCtrl.index == 2 && c.tipo == TipoCliente.casera) ||
          (_tabCtrl.index == 3 && c.tipo == TipoCliente.departamento);
      final matchQ = q.isEmpty ||
          c.nombre.toLowerCase().contains(q) ||
          c.telefono.contains(q);
      return matchTab && matchQ;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Colores / iconos / labels por tipo ───────
  Color _colorTipo(TipoCliente t) {
    switch (t) {
      case TipoCliente.tienda:
        return const Color(0xFF6366F1);
      case TipoCliente.casera:
        return const Color(0xFF10B981);
      case TipoCliente.departamento:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _iconTipo(TipoCliente t) {
    switch (t) {
      case TipoCliente.tienda:
        return Icons.storefront_rounded;
      case TipoCliente.casera:
        return Icons.home_rounded;
      case TipoCliente.departamento:
        return Icons.apartment_rounded;
    }
  }

  String _labelTipo(TipoCliente t) {
    switch (t) {
      case TipoCliente.tienda:
        return 'Tienda';
      case TipoCliente.casera:
        return 'Casera';
      case TipoCliente.departamento:
        return 'Departamento';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0018),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFE0C3FC), Color(0xFFFFB6C1)],
          ).createShader(b),
          child: const Text(
            'Clientes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF818CF8)),
            tooltip: 'Semáforo de pago',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SemaforoPagoPage(clientes: _clientes)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded,
                color: Color(0xFFFBBF24)),
            tooltip: 'Control de deudas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ControlDeudasPage(clientes: _clientes)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF7C3AED),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(icon: Icon(Icons.storefront_rounded, size: 18)),
            Tab(icon: Icon(Icons.home_rounded, size: 18)),
            Tab(icon: Icon(Icons.apartment_rounded, size: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Buscador ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.30)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded,
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.70),
                      size: 19),
                  hintText: 'Buscar cliente...',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.30),
                      fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Lista ────────────────────────────
          Expanded(
            child: _filtrados.isEmpty
                ? Center(
                    child: Text('Sin clientes',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.30))))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: _filtrados.length,
                    itemBuilder: (_, i) => _ClienteCard(
                      cliente: _filtrados[i],
                      colorTipo: _colorTipo(_filtrados[i].tipo),
                      iconTipo: _iconTipo(_filtrados[i].tipo),
                      labelTipo: _labelTipo(_filtrados[i].tipo),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HistorialComprasPage(cliente: _filtrados[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),

      // ── FAB: Nuevo cliente ──────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo cliente',
            style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _mostrarFormulario(context),
      ),
    );
  }

  // ── Formulario nuevo cliente ─────────────────
  void _mostrarFormulario(BuildContext context, [Cliente? editar]) {
    final nombreCtrl = TextEditingController(text: editar?.nombre ?? '');
    final telCtrl = TextEditingController(text: editar?.telefono ?? '');
    final dirCtrl = TextEditingController(text: editar?.direccion ?? '');
    TipoCliente tipo = editar?.tipo ?? TipoCliente.tienda;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0035),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text(
                editar == null ? 'Nuevo Cliente' : 'Editar Cliente',
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),

              // Tipo de cliente
              Row(
                children: TipoCliente.values.map((t) {
                  final sel = tipo == t;
                  final c = _colorTipo(t);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => tipo = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? c.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel
                                  ? c
                                  : Colors.white.withValues(alpha: 0.10)),
                        ),
                        child: Column(
                          children: [
                            Icon(_iconTipo(t),
                                color: sel ? c : Colors.white38, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              _labelTipo(t),
                              style: TextStyle(
                                color: sel ? c : Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              _Campo(ctrl: nombreCtrl, label: 'Nombre / Razón social',
                  icono: Icons.person_rounded),
              const SizedBox(height: 10),
              _Campo(ctrl: telCtrl, label: 'Teléfono',
                  icono: Icons.phone_rounded, tipo: TextInputType.phone),
              const SizedBox(height: 10),
              _Campo(ctrl: dirCtrl, label: 'Dirección',
                  icono: Icons.location_on_rounded),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    setState(() {
                      if (editar == null) {
                        _clientes.add(Cliente(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          nombre: nombreCtrl.text.trim(),
                          telefono: telCtrl.text.trim(),
                          direccion: dirCtrl.text.trim(),
                          tipo: tipo,
                          fechaRegistro: DateTime.now(),
                        ));
                      } else {
                        editar.nombre = nombreCtrl.text.trim();
                        editar.telefono = telCtrl.text.trim();
                        editar.direccion = dirCtrl.text.trim();
                        editar.tipo = tipo;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    editar == null
                        ? 'Registrar Cliente'
                        : 'Guardar cambios',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Tarjeta de cliente
// ─────────────────────────────────────────────
class _ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final Color colorTipo;
  final IconData iconTipo;
  final String labelTipo;
  final VoidCallback onTap;

  const _ClienteCard({
    required this.cliente,
    required this.colorTipo,
    required this.iconTipo,
    required this.labelTipo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semColor = _semaforoColor(cliente.estadoPago);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorTipo.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: colorTipo.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorTipo.withValues(alpha: 0.30),
                    colorTipo.withValues(alpha: 0.10),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: colorTipo.withValues(alpha: 0.50)),
              ),
              child: Icon(iconTipo, color: colorTipo, size: 22),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente.nombre,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.40)),
                      const SizedBox(width: 4),
                      Text(
                        cliente.telefono.isEmpty ? '—' : cliente.telefono,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 11),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorTipo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          labelTipo,
                          style: TextStyle(
                              color: colorTipo,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (cliente.saldoPendiente > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Deuda: Bs ${cliente.saldoPendiente.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),

            // Semáforo indicador
            Column(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: semColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: semColor.withValues(alpha: 0.70),
                          blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.30), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _semaforoColor(EstadoPago e) {
    switch (e) {
      case EstadoPago.puntual:
        return const Color(0xFF10B981);
      case EstadoPago.seRetrasa:
        return const Color(0xFFF59E0B);
      case EstadoPago.riesgo:
        return const Color(0xFFEF4444);
    }
  }
}

// ─────────────────────────────────────────────
//  Widget: Campo de texto reutilizable
// ─────────────────────────────────────────────
class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icono;
  final TextInputType tipo;

  const _Campo({
    required this.ctrl,
    required this.label,
    required this.icono,
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
        labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.50), fontSize: 12),
        prefixIcon: Icon(icono, color: const Color(0xFF7C3AED), size: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
    );
  }
}

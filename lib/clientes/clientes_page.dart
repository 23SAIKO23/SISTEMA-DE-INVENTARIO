import 'package:flutter/material.dart';
import 'modelos_cliente.dart';
import 'historial_compras.dart';
import 'control_deudas.dart';
import 'semaforo_pago.dart';
import '../services/api_service.dart';

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

  final _api = ApiService.instance;
  List<Cliente> _clientes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await _api.listarClientes();
      setState(() {
        _clientes = (data as List).map((j) => Cliente.fromJson(j)).toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() { _error = 'Error al conectar con el servidor'; _cargando = false; });
    }
  }


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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0018), Color(0xFF1A0035)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(context),
              _buildCategoryTabs(),
              _buildSearchBar(),
              
              // ── Tabla / Lista ────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off_rounded, color: Colors.white30, size: 48),
                                  const SizedBox(height: 12),
                                  Text(_error!, style: const TextStyle(color: Colors.white38)),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _cargarClientes,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Reintentar'),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                                  ),
                                ],
                              ),
                            )
                          : _filtrados.isEmpty
                              ? _buildEmptyState()
                              : _buildPremiumTable(context, _filtrados),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB: Nuevo cliente ──────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Registrar Nuevo',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        onPressed: () => _mostrarFormulario(context),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFE0C3FC), Color(0xFFFFB6C1)],
                  ).createShader(b),
                  child: const Text(
                    'Gestión de Clientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text('Base de datos y control de saldos',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _buildActionIcon(Icons.bar_chart_rounded, const Color(0xFF818CF8), 'Semáforo', 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => SemaforoPagoPage(clientes: _clientes)))),
          const SizedBox(width: 8),
          _buildActionIcon(Icons.account_balance_wallet_rounded, const Color(0xFFFBBF24), 'Deudas',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ControlDeudasPage(clientes: _clientes)))),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, String tip, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          final labels = ['Todos', 'Tiendas', 'Caseras', 'Deptos'];
          final isSel = _tabCtrl.index == index;
          return GestureDetector(
            onTap: () {
              setState(() => _tabCtrl.index = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF7C3AED) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSel ? Colors.transparent : Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (v) => setState(() => _busqueda = v),
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7C3AED), size: 20),
            hintText: 'Buscar por nombre o teléfono...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
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
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('No se encontraron clientes', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPremiumTable(BuildContext context, List<Cliente> clientes) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E0B36).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF2D1155).withValues(alpha: 0.5)),
              columnSpacing: 25,
              dataRowMinHeight: 65,
              dataRowMaxHeight: 75,
              dividerThickness: 0.5,
              horizontalMargin: 20,
              showCheckboxColumn: true,
              columns: [
                const DataColumn(label: _HeaderCell('Nombre')),
                const DataColumn(label: _HeaderCell('Ciudad')),
                const DataColumn(label: _HeaderCell('Teléfono')),
                const DataColumn(label: _HeaderCell('Tipo')),
                const DataColumn(label: _HeaderCell('Deuda')),
                const DataColumn(label: _HeaderCell('Estado')),
                const DataColumn(label: _HeaderCell('Acción')),
              ],
              rows: clientes.map((c) {
                final colorT = _colorTipo(c.tipo);
                final estCol = _estadoColor(c.estadoPago);
                return DataRow(
                  onSelectChanged: (_) => Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialComprasPage(cliente: c))),
                  cells: [
                    DataCell(Text(c.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                    DataCell(Text(c.ciudad.isNotEmpty ? c.ciudad : '—', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13))),
                    DataCell(Text(c.telefono, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13))),
                    DataCell(_buildTypeBadge(c.tipo, colorT)),
                    DataCell(Text('Bs ${c.saldoPendiente.toStringAsFixed(2)}', 
                      style: TextStyle(
                        color: c.saldoPendiente > 0 ? const Color(0xFFFBBF24) : Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w900, fontSize: 13))),
                    DataCell(_buildStatusCell(c.estadoPago, estCol)),
                    const DataCell(Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(TipoCliente t, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _labelTipo(t).toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStatusCell(EstadoPago p, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)],
          ),
        ),
        const SizedBox(width: 8),
        Text(_labelEstado(p), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
  Color _estadoColor(EstadoPago e) {
    switch (e) {
      case EstadoPago.puntual:
        return const Color(0xFF10B981);
      case EstadoPago.seRetrasa:
        return const Color(0xFFF59E0B);
      case EstadoPago.riesgo:
        return const Color(0xFFEF4444);
    }
  }

  String _labelEstado(EstadoPago e) {
    switch (e) {
      case EstadoPago.puntual:
        return 'Puntual';
      case EstadoPago.seRetrasa:
        return 'Retraso';
      case EstadoPago.riesgo:
        return 'Riesgo';
    }
  }

  // ── Formulario nuevo cliente ─────────────────
  void _mostrarFormulario(BuildContext context, [Cliente? editar]) {
    final nombreCtrl = TextEditingController(text: editar?.nombre ?? '');
    final telCtrl = TextEditingController(text: editar?.telefono ?? '');
    final dirCtrl = TextEditingController(text: editar?.direccion ?? '');
    
    final ciudadesValidas = ['Potosí', 'La Paz', 'El Alto', 'Cochabamba', 'Oruro'];
    String? ciudadSel;
    if (editar != null && ciudadesValidas.contains(editar.ciudad)) {
      ciudadSel = editar.ciudad;
    }

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
              
              DropdownButtonFormField<String>(
                value: ciudadSel,
                dropdownColor: const Color(0xFF1A0035),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
                decoration: InputDecoration(
                  labelText: 'Ciudad',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  prefixIcon: const Icon(Icons.location_city_rounded, color: Colors.white54, size: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: ciudadesValidas.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (val) => setS(() => ciudadSel = val),
              ),
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
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      if (editar == null) {
                        await _api.agregarCliente(
                          nombre: nombreCtrl.text.trim(),
                          telefono: telCtrl.text.trim(),
                          ciudad: ciudadSel ?? '',
                          direccion: dirCtrl.text.trim(),
                          tipo: tipo.name,
                        );
                      } else {
                        await _api.editarCliente(
                          id: editar.id,
                          nombre: nombreCtrl.text.trim(),
                          telefono: telCtrl.text.trim(),
                          ciudad: ciudadSel ?? '',
                          direccion: dirCtrl.text.trim(),
                          tipo: tipo.name,
                        );
                      }
                      Navigator.pop(context);
                      _cargarClientes(); // Recargar desde MySQL
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al guardar. ¿Está XAMPP activo?')),
                      );
                    }
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
//  Componentes de Tabla
// ─────────────────────────────────────────────
class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5));
  }
}

// ─────────────────────────────────────────────
//  Widget: Tarjeta de cliente
// ─────────────────────────────────────────────

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

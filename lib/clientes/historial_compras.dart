import 'package:flutter/material.dart';
import 'modelos_cliente.dart';

// ─────────────────────────────────────────────
//  Modelo Compra
// ─────────────────────────────────────────────
class Compra {
  final String id;
  final DateTime fecha;
  final List<ItemCompra> items;
  final double total;
  final bool pagado;
  final String? nota;

  const Compra({
    required this.id,
    required this.fecha,
    required this.items,
    required this.total,
    required this.pagado,
    this.nota,
  });
}

class ItemCompra {
  final String producto;
  final int cantidad;
  final double precioUnit;

  const ItemCompra({
    required this.producto,
    required this.cantidad,
    required this.precioUnit,
  });

  double get subtotal => cantidad * precioUnit;
}

// ─────────────────────────────────────────────
//  Página Historial de Compras
// ─────────────────────────────────────────────
class HistorialComprasPage extends StatefulWidget {
  final Cliente cliente;

  const HistorialComprasPage({super.key, required this.cliente});

  @override
  State<HistorialComprasPage> createState() => _HistorialComprasPageState();
}

class _HistorialComprasPageState extends State<HistorialComprasPage> {
  // Datos de ejemplo para el cliente
  late List<Compra> _compras;

  @override
  void initState() {
    super.initState();
    // Genera compras de ejemplo relacionadas al cliente
    _compras = [
      Compra(
        id: 'C001',
        fecha: DateTime(2025, 2, 14),
        items: const [
          ItemCompra(producto: 'Manta aguayo grande', cantidad: 3, precioUnit: 120.0),
          ItemCompra(producto: 'Bolso tejido', cantidad: 2, precioUnit: 45.0),
        ],
        total: 450.0,
        pagado: true,
      ),
      Compra(
        id: 'C002',
        fecha: DateTime(2025, 3, 1),
        items: const [
          ItemCompra(producto: 'Camino de mesa', cantidad: 5, precioUnit: 70.0),
        ],
        total: 350.0,
        pagado: false,
        nota: 'Pago pendiente — acordado para fin de mes',
      ),
      Compra(
        id: 'C003',
        fecha: DateTime(2025, 3, 20),
        items: const [
          ItemCompra(producto: 'Bufanda artesanal', cantidad: 10, precioUnit: 38.0),
          ItemCompra(producto: 'Gorro andino', cantidad: 6, precioUnit: 25.0),
        ],
        total: 530.0,
        pagado: true,
      ),
      Compra(
        id: 'C004',
        fecha: DateTime(2025, 4, 5),
        items: const [
          ItemCompra(producto: 'Tapiz decorativo', cantidad: 2, precioUnit: 180.0),
        ],
        total: 360.0,
        pagado: false,
        nota: 'Abonó Bs 160. Resto pendiente.',
      ),
    ];
  }

  double get _totalCompras =>
      _compras.fold(0, (s, c) => s + c.total);
  double get _totalPagado =>
      _compras.where((c) => c.pagado).fold(0, (s, c) => s + c.total);
  double get _totalDeuda =>
      _compras.where((c) => !c.pagado).fold(0, (s, c) => s + c.total);

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cliente.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Historial de compras',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Resumen estadístico ────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatBox(
                        label: 'Total compras',
                        valor: 'Bs ${_totalCompras.toStringAsFixed(0)}',
                        icono: Icons.shopping_bag_rounded,
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 10),
                      _StatBox(
                        label: 'Pagado',
                        valor: 'Bs ${_totalPagado.toStringAsFixed(0)}',
                        icono: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 10),
                      _StatBox(
                        label: 'Pendiente',
                        valor: 'Bs ${_totalDeuda.toStringAsFixed(0)}',
                        icono: Icons.pending_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barra de progreso pago
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _totalCompras == 0
                          ? 0
                          : _totalPagado / _totalCompras,
                      minHeight: 8,
                      backgroundColor:
                          const Color(0xFFF59E0B).withValues(alpha: 0.20),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_totalCompras == 0 ? 0 : (_totalPagado / _totalCompras * 100)).toStringAsFixed(0)}% pagado',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${_compras.length} pedidos',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Separador etiqueta
                  Row(
                    children: [
                      Container(
                        width: 3, height: 14,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PEDIDOS RECIENTES',
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

          // ── Lista de compras ───────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _CompraCard(compra: _compras[i]),
              childCount: _compras.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Caja estadística
// ─────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color color;

  const _StatBox({
    required this.label,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Tarjeta de una compra
// ─────────────────────────────────────────────
class _CompraCard extends StatefulWidget {
  final Compra compra;
  const _CompraCard({required this.compra});

  @override
  State<_CompraCard> createState() => _CompraCardState();
}

class _CompraCardState extends State<_CompraCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.compra;
    final color = c.pagado ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    c.pagado
                        ? Icons.receipt_long_rounded
                        : Icons.pending_actions_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${c.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatFecha(c.fecha),
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
                      'Bs ${c.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.pagado ? 'Pagado' : 'Pendiente',
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(
                  _expandido
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),

            // Detalle expandible
            if (_expandido) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: 8),
              ...c.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.fiber_manual_record,
                          size: 6,
                          color: Colors.white.withValues(alpha: 0.30)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.producto,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${item.cantidad}x  Bs ${item.precioUnit.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bs ${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (c.nota != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c.nota!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
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

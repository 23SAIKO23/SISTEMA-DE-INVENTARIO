import 'package:flutter/material.dart';

class MatrizFileteraWidget extends StatelessWidget {
  final List<List<Color>> matrizHilos;

  const MatrizFileteraWidget({super.key, required this.matrizHilos});

  @override
  Widget build(BuildContext context) {
    if (matrizHilos.isEmpty) return const SizedBox.shrink();
    
    int rows = matrizHilos.length;
    int cols = matrizHilos.first.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'PEINE ESPACIADOR ($rows x $cols)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: rows * cols,
            itemBuilder: (context, index) {
              int row = index ~/ cols;
              int col = index % cols;
              Color colorCono = matrizHilos[row][col];
              
              // Bordecito ligero si es un color muy claro (blanco/crudo)
              Border? border;
              if (colorCono == Colors.white || colorCono.computeLuminance() > 0.8) {
                border = Border.all(color: Colors.grey.withOpacity(0.3), width: 1);
              }

              return Container(
                decoration: BoxDecoration(
                  color: colorCono,
                  shape: BoxShape.circle,
                  border: border,
                  boxShadow: [
                    BoxShadow(
                      color: colorCono.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

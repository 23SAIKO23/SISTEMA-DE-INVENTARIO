import 'package:flutter/material.dart';

class MatrizFileteraWidget extends StatelessWidget {
  final List<List<Color>> matrizHilos;
  final double conoSize;
  final double fontSize;
  final Function(int row, int col)? onConoTap;

  const MatrizFileteraWidget({
    super.key, 
    required this.matrizHilos,
    this.conoSize = 10.0,
    this.fontSize = 9.0,
    this.onConoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (matrizHilos.isEmpty) return const SizedBox.shrink();
    
    int rows = matrizHilos.length;
    int cols = matrizHilos.first.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Text(
              'PEINE ESPACIADOR ($rows x $cols)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(rows, (r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(cols, (c) {
                    Color colorCono = matrizHilos[r][c];

                    Border? border;
                    if (colorCono == Colors.white || colorCono.computeLuminance() > 0.8) {
                      border = Border.all(color: Colors.grey.withOpacity(0.3), width: 1);
                    }

                    Widget conoWidget = Container(
                      margin: EdgeInsets.symmetric(horizontal: conoSize * 0.1),
                      width: conoSize,
                      height: conoSize,
                      decoration: BoxDecoration(
                        color: colorCono,
                        shape: BoxShape.circle,
                        border: border,
                        boxShadow: [
                          BoxShadow(
                            color: colorCono.withOpacity(0.3),
                            blurRadius: conoSize * 0.3,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: conoSize * 0.4,
                          height: conoSize * 0.4,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );

                    if (onConoTap != null) {
                      return GestureDetector(
                        onTap: () => onConoTap!(r, c),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: conoWidget,
                        ),
                      );
                    }

                    return conoWidget;
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

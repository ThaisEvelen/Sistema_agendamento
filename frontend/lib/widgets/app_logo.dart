import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Logo do OrganizaAI.
///
/// Parâmetros:
/// - [size]     : tamanho do ícone quadrado (padrão 100)
/// - [showText] : exibe "OrganizaAI" abaixo do ícone (padrão true)
/// - [darkText] : usa texto escuro (para fundos claros) — padrão false (branco)
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool darkText;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = true,
    this.darkText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Ícone ──────────────────────────────────────────────
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: kPrimaryGradient,
            borderRadius: BorderRadius.circular(size * 0.24),
            boxShadow: [
              BoxShadow(
                color: kPurple.withValues(alpha: 0.45),
                blurRadius: size * 0.22,
                offset: Offset(0, size * 0.09),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Brilho sutil no canto superior-direito
              Positioned(
                top: -size * 0.05,
                right: -size * 0.05,
                child: Container(
                  width: size * 0.65,
                  height: size * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Calendário — corpo branco
              Center(
                child: CustomPaint(
                  size: Size(size * 0.68, size * 0.68),
                  painter: _CalendarPainter(size: size),
                ),
              ),

              // Badge sparkle (IA) — canto inferior-direito
              Positioned(
                bottom: size * 0.1,
                right: size * 0.1,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: size * 0.06,
                        offset: Offset(0, size * 0.02),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: kPurple,
                      size: size * 0.17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Texto ──────────────────────────────────────────────
        if (showText) ...[
          SizedBox(height: size * 0.14),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Organiza',
                  style: TextStyle(
                    fontSize: size * 0.26,
                    fontWeight: FontWeight.w800,
                    color: darkText ? kPurple : Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(
                    fontSize: size * 0.26,
                    fontWeight: FontWeight.w800,
                    color: darkText
                        ? kIndigo
                        : Colors.white.withValues(alpha: 0.65),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Desenha o ícone de calendário estilizado
class _CalendarPainter extends CustomPainter {
  final double size;
  const _CalendarPainter({required this.size});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final purplePaint = Paint()
      ..color = kPurple
      ..style = PaintingStyle.fill;

    final darkPurplePaint = Paint()
      ..color = kPurpleDark
      ..style = PaintingStyle.fill;

    final r = w * 0.12;

    // ── Corpo do calendário (branco) ──────────────────────────
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.14, w, h * 0.86),
      Radius.circular(r),
    );
    canvas.drawRRect(bodyRect, whitePaint);

    // ── Cabeçalho roxo ────────────────────────────────────────
    final headerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, h * 0.14, w, h * 0.30),
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
    );
    canvas.drawRRect(headerRect, darkPurplePaint);

    // Linha divisória header/corpo
    final dividerPaint = Paint()
      ..color = kPurpleLight.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(w * 0.05, h * 0.44),
      Offset(w * 0.95, h * 0.44),
      dividerPaint,
    );

    // Texto simulado no header (pequena linha)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = h * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.12, h * 0.285),
      Offset(w * 0.55, h * 0.285),
      linePaint,
    );

    // ── Argolas do calendário ─────────────────────────────────
    final hookPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, 0, w * 0.1, h * 0.24),
        const Radius.circular(999),
      ),
      hookPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.68, 0, w * 0.1, h * 0.24),
        const Radius.circular(999),
      ),
      hookPaint,
    );

    // ── Grade de pontos (2 × 2 visíveis + checkmark) ─────────
    final dotR = w * 0.09;
    final gx = [w * 0.2, w * 0.5, w * 0.8];
    final gy = [h * 0.60, h * 0.80];

    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        // Posição col=1 row=0 → checkmark; col=2 row=1 → omitido (badge cobre)
        if (row == 0 && col == 1) continue; // substituído por checkmark
        if (row == 1 && col == 2) continue; // coberto pelo badge sparkle

        final opacity = row == 0 ? 1.0 : 0.55;
        canvas.drawCircle(
          Offset(gx[col], gy[row]),
          dotR,
          Paint()
            ..color = purplePaint.color.withValues(alpha: opacity)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // ── Check (confirmação) no ponto central superior ─────────
    final checkBg = Paint()
      ..color = kPurpleDark
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(gx[1], gy[0]), dotR * 1.25, checkBg);

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(gx[1] - dotR * 0.7, gy[0])
      ..lineTo(gx[1] - dotR * 0.1, gy[0] + dotR * 0.65)
      ..lineTo(gx[1] + dotR * 0.8, gy[0] - dotR * 0.7);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Estrela de 4 pontas (sparkle) — utilitário compartilhável
Path buildSparklePath(Offset center, double outerR, double innerR) {
  final path = Path();
  const points = 8;
  for (int i = 0; i < points; i++) {
    final angle = (i * math.pi * 2 / points) - math.pi / 2;
    final r = i.isEven ? outerR : innerR;
    final x = center.dx + r * math.cos(angle);
    final y = center.dy + r * math.sin(angle);
    i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
  }
  return path..close();
}

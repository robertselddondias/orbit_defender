import 'dart:math';

import 'package:flutter/material.dart';

class StarfieldPainter extends CustomPainter {
  final Random _random = Random(42); // Seed fixo para consistência
  final int starCount = 200; // Quantidade de estrelas

  @override
  void paint(Canvas canvas, Size size) {
    final Paint smallStarPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final Paint mediumStarPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final Paint largeStarPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final Paint outerGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Desenhar nebulosas distantes
    final bluePaint = Paint()
      ..color = const Color(0xFF0033AA).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final redPaint = Paint()
      ..color = const Color(0xFFAA0033).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Nebulosa azul
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.2, size.height * 0.3),
        width: size.width * 0.4,
        height: size.height * 0.2,
      ),
      bluePaint,
    );

    // Nebulosa vermelha
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height * 0.2),
        width: size.width * 0.3,
        height: size.height * 0.15,
      ),
      redPaint,
    );

    // Outra nebulosa azul
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.7),
        width: size.width * 0.5,
        height: size.height * 0.3,
      ),
      bluePaint,
    );

    // Outra nebulosa vermelha
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.8),
        width: size.width * 0.4,
        height: size.height * 0.25,
      ),
      redPaint,
    );

    // Desenhar estrelas pequenas
    for (int i = 0; i < starCount; i++) {
      final double x = _random.nextDouble() * size.width;
      final double y = _random.nextDouble() * size.height;
      final double radius = _random.nextDouble() * 1.0 + 0.5; // Entre 0.5 e 1.5

      canvas.drawCircle(Offset(x, y), radius, smallStarPaint);
    }

    // Desenhar estrelas médias
    for (int i = 0; i < starCount ~/ 8; i++) {
      final double x = _random.nextDouble() * size.width;
      final double y = _random.nextDouble() * size.height;
      final double radius = _random.nextDouble() * 1.0 + 1.2; // Entre 1.2 e 2.2

      canvas.drawCircle(Offset(x, y), radius, mediumStarPaint);
      canvas.drawCircle(Offset(x, y), radius * 1.5, glowPaint);
    }

    // Desenhar estrelas grandes com brilho
    for (int i = 0; i < starCount ~/ 20; i++) {
      final double x = _random.nextDouble() * size.width;
      final double y = _random.nextDouble() * size.height;
      final double radius = _random.nextDouble() * 1.0 + 2.0; // Entre 2.0 e 3.0

      canvas.drawCircle(Offset(x, y), radius, largeStarPaint);
      canvas.drawCircle(Offset(x, y), radius * 1.8, glowPaint);
      canvas.drawCircle(Offset(x, y), radius * 3.0, outerGlowPaint);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) => false;
}

import 'dart:math';

import 'package:flutter/material.dart';

class ParallaxStarfieldPainter extends CustomPainter {
  final double animationValue;
  final List<Star> _stars = [];
  final Random _random = Random();
  final int starCount;

  // Armazenar o tamanho da tela para evitar recriação de estrelas
  Size? _lastSize;

  // IMPORTANTE: Velocidades definidas em apenas 1-2 pixels por segundo
  final double nearStarsSpeed;
  final double midStarsSpeed;
  final double farStarsSpeed;

  // Direção: 0 = para baixo, 1 = para cima
  final int direction;

  ParallaxStarfieldPainter({
    required this.animationValue,
    this.starCount = 150,
    // Velocidades extremamente baixas - praticamente estático
    this.nearStarsSpeed = 0.005,
    this.midStarsSpeed = 0.002,
    this.farStarsSpeed = 0.0005,
    this.direction = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Se o tamanho mudou ou as estrelas ainda não foram criadas, reinicializar
    if (_stars.isEmpty || _lastSize != size) {
      _initStars(size);
      _lastSize = size;
    }

    // Pintar o fundo preto do espaço
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Atualizar e desenhar estrelas
    for (var star in _stars) {
      // Determinar velocidade com base na camada
      double speed;
      if (star.layer == 0) {
        speed = nearStarsSpeed;
      } else if (star.layer == 1) {
        speed = midStarsSpeed;
      } else {
        speed = farStarsSpeed;
      }

      // Movimento extremamente lento baseado no animationValue
      double offset = animationValue * speed * 100; // Escala para ser visível, mas muito lento

      if (direction == 0) { // Para baixo
        star.y = (star.initialY + offset) % size.height;
      } else { // Para cima
        star.y = (star.initialY - offset) % size.height;
        if (star.y < 0) star.y += size.height;
      }

      // Definir cor e tamanho com base na camada
      final paint = Paint();

      // Desenhar estrela - apenas pontos pequenos, sem efeitos
      if (star.layer == 0) { // Próxima
        paint.color = Colors.white.withOpacity(0.9);
        canvas.drawCircle(Offset(star.x, star.y), star.size, paint);
      } else if (star.layer == 1) { // Média
        paint.color = Colors.white.withOpacity(0.7);
        canvas.drawCircle(Offset(star.x, star.y), star.size, paint);
      } else { // Distante
        paint.color = Colors.white.withOpacity(0.5);
        canvas.drawCircle(Offset(star.x, star.y), star.size, paint);
      }
    }
  }

  void _initStars(Size size) {
    _stars.clear();

    // Espaçamento mínimo entre estrelas
    final minDistance = size.width * 0.02;
    final positions = <Offset>[];

    for (int i = 0; i < starCount; i++) {
      // Tentar encontrar posição válida
      Offset position;
      bool validPosition;
      int attempts = 0;

      do {
        validPosition = true;
        position = Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        );

        // Verificar distância das outras estrelas
        for (final pos in positions) {
          if ((pos - position).distance < minDistance) {
            validPosition = false;
            break;
          }
        }

        attempts++;
      } while (!validPosition && attempts < 3);

      positions.add(position);

      // Determinar camada - muitas estrelas distantes
      int layer;
      final layerRand = _random.nextDouble();
      if (layerRand < 0.05) {
        layer = 0; // 5% na camada próxima
      } else if (layerRand < 0.20) {
        layer = 1; // 15% na camada média
      } else {
        layer = 2; // 80% na camada distante
      }

      // Tamanhos muito pequenos para estrelas
      double starSize;
      if (layer == 0) {
        starSize = 0.3 + _random.nextDouble() * 0.6; // 0.3 - 0.9
      } else if (layer == 1) {
        starSize = 0.2 + _random.nextDouble() * 0.3; // 0.2 - 0.5
      } else {
        starSize = 0.1 + _random.nextDouble() * 0.1; // 0.1 - 0.2
      }

      _stars.add(Star(
        x: position.dx,
        y: position.dy,
        initialY: position.dy,
        size: starSize,
        layer: layer,
      ));
    }
  }

  @override
  bool shouldRepaint(ParallaxStarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class Star {
  final double x;
  double y;
  final double initialY;
  final double size;
  final int layer;

  Star({
    required this.x,
    required this.y,
    required this.initialY,
    required this.size,
    required this.layer,
  });
}

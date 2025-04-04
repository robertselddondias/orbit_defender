import 'dart:math';

import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/enemy.dart';
import 'package:orbit_defender/entities/explosion.dart';
import 'package:orbit_defender/entities/power_up.dart';
import 'package:orbit_defender/entities/power_up_type.dart';
import 'package:orbit_defender/entities/projectile.dart';
import 'package:orbit_defender/game_controller.dart';
import 'package:orbit_defender/utils/power_name_animation.dart';

class GamePainter extends CustomPainter {
  final GameController gameController;

  GamePainter(this.gameController);

  @override
  void paint(Canvas canvas, Size size) {
    // Verificar se o controlador está pronto
    if (!gameController.isInitialized) {
      return;
    }

    try {
      // Desenhar canhão
      _drawCannon(canvas);

      // Desenhar projéteis
      for (final projectile in gameController.projectiles) {
        _drawProjectile(canvas, projectile);
      }

      // Desenhar inimigos
      for (final enemy in gameController.enemies) {
        _drawEnemy(canvas, enemy);
      }

      // Desenhar power-ups
      for (final powerUp in gameController.powerUps) {
        _drawPowerUp(canvas, powerUp);
      }

      // Desenhar explosões
      for (final explosion in gameController.explosions) {
        _drawExplosion(canvas, explosion);
      }

      // Desenhar animação do nome da habilidade (NOVO)
      _drawPowerNameAnimation(canvas);

    } catch (e) {
      debugPrint('Erro ao desenhar elementos do jogo: $e');
    }
  }

  void _drawCannon(Canvas canvas) {
    try {
      final cannon = gameController.cannon;

      // Desenhar base circular
      final basePaint = Paint()
        ..color = Colors.blue.shade800
        ..style = PaintingStyle.fill;

      canvas.drawCircle(cannon.position, cannon.radius, basePaint);

      // Desenhar borda
      final borderPaint = Paint()
        ..color = Colors.blue.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(cannon.position, cannon.radius, borderPaint);

      // Desenhar núcleo interno
      final corePaint = Paint()
        ..color = Colors.blue.shade500
        ..style = PaintingStyle.fill;

      canvas.drawCircle(cannon.position, cannon.radius * 0.7, corePaint);

      // Desenhar núcleo interno brilhante
      final glowPaint = Paint()
        ..color = Colors.blue.shade300
        ..style = PaintingStyle.fill;

      canvas.drawCircle(cannon.position, cannon.radius * 0.4, glowPaint);

      // Desenhar centro brilhante
      final centerPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(cannon.position, cannon.radius * 0.2, centerPaint);

      // Desenhar escudo se ativo
      if (cannon.hasPowerUp(PowerUpType.shield)) {
        final shieldPaint = Paint()
          ..color = Colors.blue.shade200.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(cannon.position, cannon.radius * 1.5, shieldPaint);

        final shieldBorderPaint = Paint()
          ..color = Colors.blue.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(cannon.position, cannon.radius * 1.5, shieldBorderPaint);
      }
    } catch (e) {
      debugPrint('Erro ao desenhar canhão: $e');
    }
  }

  void _drawProjectile(Canvas canvas, Projectile projectile) {
    try {
      // Definir a cor base do projétil
      Color baseColor = projectile.isSuperShot ? Colors.amber : projectile.color;

      // Paint para o projétil principal
      final paint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill;

      // Desenhar o projétil principal
      canvas.drawCircle(projectile.position, projectile.radius, paint);

      // Para super tiro, adicionar um efeito de trilha
      if (projectile.isSuperShot) {
        // Adicionar trilha atrás do projétil
        final pathPaint = Paint()
          ..color = Colors.amber.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = projectile.radius * 1.5;

        final path = Path();
        path.moveTo(
            projectile.position.dx - projectile.direction.dx * projectile.radius * 4,
            projectile.position.dy - projectile.direction.dy * projectile.radius * 4
        );
        path.lineTo(projectile.position.dx, projectile.position.dy);

        canvas.drawPath(path, pathPaint);

        // Primeiro brilho (mais intenso)
        final glowPaint1 = Paint()
          ..color = Colors.amber.withOpacity(0.7)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(projectile.position, projectile.radius * 1.8, glowPaint1);

        // Segundo brilho (menos intenso, mais amplo)
        final glowPaint2 = Paint()
          ..color = Colors.amber.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(projectile.position, projectile.radius * 3.0, glowPaint2);

        // Terceiro brilho (muito tênue, bem amplo)
        final glowPaint3 = Paint()
          ..color = Colors.amber.withOpacity(0.1)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(projectile.position, projectile.radius * 5.0, glowPaint3);
      }
      // Para projéteis normais, adicionar um efeito de brilho simples
      else {
        final glowPaint = Paint()
          ..color = projectile.color.withOpacity(0.5)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(projectile.position, projectile.radius * 1.5, glowPaint);
      }
    } catch (e) {
      debugPrint('Erro ao desenhar projétil: $e');
    }
  }

  void _drawPowerNameAnimation(Canvas canvas) {
    final animation = gameController.currentPowerNameAnimation;
    if (animation == null) return;

    final screenCenter = Offset(
      gameController.screenSize.width / 2,
      gameController.screenSize.height * 0.2, // Posicionamento mais alto para não atrapalhar a jogabilidade
    );

    // Cores baseadas no tipo de poder
    final powerColor = _getPowerColor(animation.powerName);

    // Configurar o estilo do texto - mais simples, porém com destaque
    final textStyle = TextStyle(
      fontSize: 42, // Tamanho menor
      fontWeight: FontWeight.bold,
      color: powerColor, // Cor principal do poder
      shadows: [
        Shadow(
          color: Colors.white.withOpacity(animation.opacity * 0.8),
          blurRadius: 12,
          offset: Offset(0, 0),
        ),
        Shadow(
          color: Colors.black.withOpacity(animation.opacity * 0.6),
          blurRadius: 4,
          offset: Offset(1, 1),
        ),
      ],
    );

    // Criar o TextPainter
    final textSpan = TextSpan(
      text: animation.powerName,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Layout e desenho do texto
    textPainter.layout(
      minWidth: 0,
      maxWidth: gameController.screenSize.width,
    );

    // Salvar estado atual do canvas
    canvas.save();

    // Aplicar transformações - posicionamento fixo e escala simples
    canvas.translate(screenCenter.dx, screenCenter.dy);
    canvas.scale(animation.scale);

    // Aplicar opacidade
    final paintOpacity = Paint()
      ..colorFilter = ColorFilter.mode(
          Colors.white.withOpacity(animation.opacity),
          BlendMode.srcIn);

    // Desenhar o texto com as transformações aplicadas
    canvas.saveLayer(
      Rect.fromLTWH(
        -textPainter.width / 2,
        -textPainter.height / 2,
        textPainter.width,
        textPainter.height,
      ),
      paintOpacity,
    );

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Restaurar o estado da camada
    canvas.restore();

    // Adicionar uma linha de destaque simples abaixo do texto
    final linePaint = Paint()
      ..color = powerColor.withOpacity(animation.opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawLine(
        Offset(-textPainter.width / 2, textPainter.height / 2 + 5),
        Offset(textPainter.width / 2, textPainter.height / 2 + 5),
        linePaint
    );

    // Restaurar o estado do canvas
    canvas.restore();
  }

  void _drawParticles(Canvas canvas, PowerNameAnimation animation, Offset center) {
    final random = Random(animation.startTime.millisecondsSinceEpoch);
    final powerColor = _getPowerColor(animation.powerName);

    final numParticles = 40;

    for (int i = 0; i < numParticles; i++) {
      // Posição baseada em tempo e índice
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * 300 * animation.scale;

      // Partículas mais afastadas do centro conforme a animação progride
      final particleX = center.dx + cos(angle) * distance;
      final particleY = center.dy + sin(angle) * distance;

      // Tamanho variável
      final size = 2.0 + random.nextDouble() * 6.0 * animation.opacity;

      // Opacidade baseada na distância do centro
      final particleOpacity = (1.0 - distance / 300) * animation.opacity;

      if (particleOpacity <= 0) continue;

      final particlePaint = Paint()
        ..color = powerColor.withOpacity(particleOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(particleX, particleY), size, particlePaint);
    }
  }

  Color _getPowerColor(String powerName) {
    if (powerName.contains("TIRO") || powerName.contains("MEGA")) {
      return Colors.amber;
    } else if (powerName.contains("BOMBA") || powerName.contains("EXPLOSÃO")) {
      return Colors.red;
    } else if (powerName.contains("TEMPORAL") || powerName.contains("CONTROLE")) {
      return Colors.purple;
    } else if (powerName.contains("MAGNÉTICO") || powerName.contains("ATRAÇÃO")) {
      return Colors.blue;
    } else if (powerName.contains("RÁPIDO") || powerName.contains("FÚRIA")) {
      return Colors.green;
    }
    return Colors.orange;
  }

  Color _getSecondaryColor(String powerName) {
    if (powerName.contains("TIRO PODEROSO")) {
      return Colors.orange;
    } else if (powerName.contains("BOMBA")) {
      return Colors.deepOrange;
    } else if (powerName.contains("TEMPORAL")) {
      return Colors.deepPurple;
    } else if (powerName.contains("MAGNÉTICO")) {
      return Colors.lightBlue;
    } else if (powerName.contains("RÁPIDO")) {
      return Colors.lightGreen;
    }
    return Colors.yellow;
  }

  void _drawLightRays(Canvas canvas, Offset center, PowerNameAnimation animation) {
    final powerColor = _getPowerColor(animation.powerName);
    final rayPaint = Paint()
      ..color = powerColor.withOpacity(animation.opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    final numRays = 12;
    final maxRayLength = gameController.screenSize.width * 0.5 * animation.scale;

    for (int i = 0; i < numRays; i++) {
      final angle = i * (2 * pi / numRays);
      final rayLength = maxRayLength * (0.5 + 0.5 * sin(animation.startTime.millisecondsSinceEpoch * 0.005 + i));

      final startPoint = Offset(
          center.dx + cos(angle) * 50,
          center.dy + sin(angle) * 50
      );

      final endPoint = Offset(
          center.dx + cos(angle) * rayLength,
          center.dy + sin(angle) * rayLength
      );

      final path = Path()
        ..moveTo(startPoint.dx, startPoint.dy)
        ..lineTo(endPoint.dx, endPoint.dy);

      canvas.drawPath(path, rayPaint);
    }
  }

  void _drawEnemy(Canvas canvas, Enemy enemy) {
    try {
      final paint = Paint()
        ..style = PaintingStyle.fill;

      if (enemy.type == EnemyType.normalAsteroid) {
        paint.color = Colors.grey.shade700;
      } else {
        paint.color = Colors.red.shade800;
      }

      // Salvar estado atual do canvas
      canvas.save();

      // Transladar para posição do inimigo
      canvas.translate(enemy.position.dx, enemy.position.dy);

      // Rotacionar para dar efeito de giro
      canvas.rotate(enemy.rotation);

      // Desenhar asteroide com forma irregular
      final path = Path();
      final radius = enemy.radius;

      // Criar forma de asteroide
      for (int i = 0; i < 10; i++) {
        final angle = i * 2 * pi / 10;
        final variation = (i % 2 == 0) ? 0.8 : 1.2;
        final x = cos(angle) * radius * variation;
        final y = sin(angle) * radius * variation;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      path.close();
      canvas.drawPath(path, paint);

      // Desenhar crateras
      final craterPaint = Paint()
        ..color = Colors.grey.shade900
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(radius * 0.3, -radius * 0.4), radius * 0.2, craterPaint);
      canvas.drawCircle(Offset(-radius * 0.4, radius * 0.2), radius * 0.15, craterPaint);

      // Restaurar o canvas
      canvas.restore();
    } catch (e) {
      debugPrint('Erro ao desenhar inimigo: $e');
    }
  }

  void _drawPowerUp(Canvas canvas, PowerUp powerUp) {
    try {
      final paint = Paint()
        ..style = PaintingStyle.fill;

      // Cor baseada no tipo
      switch (powerUp.type) {
        case PowerUpType.tripleShot:
          paint.color = Colors.orange;
          break;
        case PowerUpType.shield:
          paint.color = Colors.blue;
          break;
        case PowerUpType.speedBoost:
          paint.color = Colors.green;
          break;
        case PowerUpType.extraLife:
          paint.color = Colors.red;
          break;
      }

      // Efeito de brilho para power-ups de level up
      if (powerUp.isLevelUpBonus) {
        // Salvar estado do canvas para rotação
        canvas.save();

        // Transladar para o centro do power-up
        canvas.translate(powerUp.position.dx, powerUp.position.dy);

        // Rotacionar
        canvas.rotate(powerUp.rotationAngle);

        // Desenhar aura externa brilhante
        final outerGlowPaint = Paint()
          ..color = paint.color.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset.zero, powerUp.currentRadius * 1.8, outerGlowPaint);

        // Desenhar segunda aura mais intensa
        final innerGlowPaint = Paint()
          ..color = paint.color.withOpacity(0.5)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset.zero, powerUp.currentRadius * 1.4, innerGlowPaint);

        // Desenhar corpo principal do power-up
        canvas.drawCircle(Offset.zero, powerUp.currentRadius, paint);

        // Desenhar borda brilhante
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3; // Borda mais grossa

        canvas.drawCircle(Offset.zero, powerUp.currentRadius, borderPaint);

        // Desenhar estrelas ao redor (efeito especial)
        final starPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        for (int i = 0; i < 8; i++) {
          final angle = i * pi / 4 + powerUp.pulseValue / 2;
          final x = powerUp.currentRadius * 1.3 * cos(angle);
          final y = powerUp.currentRadius * 1.3 * sin(angle);

          // Tamanho da estrela pulsante
          final starSize = 2 + sin(powerUp.pulseValue + i) * 1;

          canvas.drawCircle(Offset(x, y), starSize, starPaint);
        }

        // Desenhar ícone do power-up
        const textStyle = TextStyle(
          color: Colors.white,
          fontSize: 16, // Ligeiramente maior
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(
          text: _getPowerUpIcon(powerUp.type),
          style: textStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );

        // Restaurar o canvas
        canvas.restore();
      } else {
        // Power-up normal (sem efeitos especiais)
        // Desenhar círculo do power-up
        canvas.drawCircle(powerUp.position, powerUp.radius, paint);

        // Desenhar borda
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(powerUp.position, powerUp.radius, borderPaint);

        // Desenhar ícone baseado no tipo
        const textStyle = TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(
          text: _getPowerUpIcon(powerUp.type),
          style: textStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          powerUp.position.translate(
            -textPainter.width / 2,
            -textPainter.height / 2,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao desenhar power-up: $e');
    }
  }

  String _getPowerUpIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.tripleShot:
        return '3X';
      case PowerUpType.shield:
        return 'S';
      case PowerUpType.speedBoost:
        return '+S';
      case PowerUpType.extraLife:
        return '+♥';
    }
  }

  void _drawExplosion(Canvas canvas, Explosion explosion) {
    try {
      // Cor base com opacidade
      final paint = Paint()
        ..color = explosion.color.withOpacity(explosion.opacity)
        ..style = PaintingStyle.fill;

      // Desenhar o círculo principal da explosão
      canvas.drawCircle(explosion.position, explosion.radius, paint);

      // Efeitos diferentes para explosões especiais vs. normais
      if (explosion.isSpecialEffect) {
        // Para efeitos especiais, desenhar vários anéis concêntricos

        // Anel externo
        final ringPaint = Paint()
          ..color = Colors.white.withOpacity(explosion.opacity * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

        canvas.drawCircle(explosion.position, explosion.radius * 0.9, ringPaint);

        // Anel médio
        final midRingPaint = Paint()
          ..color = Colors.white.withOpacity(explosion.opacity * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(explosion.position, explosion.radius * 0.7, midRingPaint);

        // Núcleo mais brilhante
        final corePaint = Paint()
          ..color = Colors.white.withOpacity(explosion.opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(explosion.position, explosion.radius * 0.4, corePaint);

        // Para bombas de área, adicionar partículas
        if (explosion.radius > 100) { // Assume que explosões grandes são bombas de área
          final random = Random();
          final particlePaint = Paint()
            ..color = explosion.color.withOpacity(explosion.opacity * 0.7)
            ..style = PaintingStyle.fill;

          // Desenhar algumas partículas aleatórias
          for (int i = 0; i < 15; i++) {
            final angle = random.nextDouble() * 2 * pi;
            final distance = random.nextDouble() * explosion.radius * 0.8;
            final particleSize = random.nextDouble() * 5 + 3;

            final particlePosition = Offset(
                explosion.position.dx + cos(angle) * distance,
                explosion.position.dy + sin(angle) * distance
            );

            canvas.drawCircle(particlePosition, particleSize, particlePaint);
          }
        }
      }
      // Para explosões normais, desenhar apenas um núcleo brilhante
      else {
        final innerPaint = Paint()
          ..color = Colors.yellow.withOpacity(explosion.opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(explosion.position, explosion.radius * 0.6, innerPaint);
      }
    } catch (e) {
      debugPrint('Erro ao desenhar explosão: $e');
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/enemy.dart';
import 'package:orbit_defender/entities/explosion.dart';
import 'package:orbit_defender/entities/power_up.dart';
import 'package:orbit_defender/entities/power_up_type.dart';
import 'package:orbit_defender/entities/projectile.dart';
import 'package:orbit_defender/game_controller.dart';

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
      final paint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;

      canvas.drawCircle(projectile.position, projectile.radius, paint);

      // Efeito de brilho
      final glowPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(projectile.position, projectile.radius * 1.5, glowPaint);
    } catch (e) {
      debugPrint('Erro ao desenhar projétil: $e');
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
      final paint = Paint()
        ..color = Colors.orange.withOpacity(explosion.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(explosion.position, explosion.radius, paint);

      final innerPaint = Paint()
        ..color = Colors.yellow.withOpacity(explosion.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(explosion.position, explosion.radius * 0.6, innerPaint);
    } catch (e) {
      debugPrint('Erro ao desenhar explosão: $e');
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}

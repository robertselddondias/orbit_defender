// Modifique a classe HUD para incluir o indicador de dificuldade

import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/game_state.dart';
import 'package:orbit_defender/game_controller.dart';

class HUD extends StatelessWidget {
  final GameController gameController;

  const HUD({Key? key, required this.gameController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Não mostrar o HUD se o jogo não estiver em andamento
    if (gameController.gameState == GameState.ready) {
      return const SizedBox.shrink();
    }

    // Garantir que o número de vidas seja sempre não-negativo
    final lives = gameController.lives > 0 ? gameController.lives : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pontuação
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${gameController.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Informações de onda
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.waves,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Onda ${gameController.wave}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Vidas
              Row(
                children: List.generate(
                  lives,
                      (index) => const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // NOVO: Barra de dificuldade
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NÍVEL ${gameController.difficultyLevel.toInt()}',
                      style: TextStyle(
                        color: _getDifficultyColor(gameController.difficultyLevel),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Próximo: ${_getNextDifficultyThreshold(gameController)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Stack(
                  children: [
                    // Fundo da barra
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Barra de progresso
                    FractionallySizedBox(
                      widthFactor: _getDifficultyProgress(gameController),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(gameController.difficultyLevel),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Cores para diferentes níveis de dificuldade
  Color _getDifficultyColor(double level) {
    if (level <= 3) {
      return Colors.green;
    } else if (level <= 6) {
      return Colors.orange;
    } else if (level <= 8) {
      return Colors.deepOrangeAccent;
    } else {
      return Colors.red;
    }
  }

  // Calcular o próximo limite de pontuação
  String _getNextDifficultyThreshold(GameController controller) {
    final currentLevel = controller.difficultyLevel.toInt();
    // Usamos 10 como nível máximo
    if (currentLevel >= 10) {
      return "MAX";
    }

    // Encontrar o próximo threshold
    // Nota: Isso depende da implementação exata dos thresholds
    // Você precisará adaptar isso para corresponder à estrutura real do seu controlador
    final nextThreshold = controller.getNextDifficultyThreshold();
    return "${nextThreshold - controller.score} pts";
  }

  // Calcular o progresso para o próximo nível
  double _getDifficultyProgress(GameController controller) {
    final currentLevel = controller.difficultyLevel.toInt();
    if (currentLevel >= 10) {
      return 1.0; // Nível máximo
    }

    // Pegar os thresholds atual e próximo
    final currentThreshold = controller.getCurrentDifficultyThreshold();
    final nextThreshold = controller.getNextDifficultyThreshold();

    // Calcular progresso
    final progress = (controller.score - currentThreshold) /
        (nextThreshold - currentThreshold);

    return progress.clamp(0.0, 1.0);
  }
}

import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/high_score.dart';
import 'package:orbit_defender/utils/high_score_manager.dart';

class HighScoreScreen extends StatelessWidget {
  final int currentScore;
  final int currentWave;
  final Function() onPlayAgain; // Usando Function() em vez de VoidCallback

  const HighScoreScreen({
    Key? key,
    required this.currentScore,
    required this.currentWave,
    required this.onPlayAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obter o tamanho da tela para ajustar dinamicamente
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: screenSize.width * 0.85,
        padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12.0 : 20.0,
            horizontal: 16.0
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A2137).withOpacity(0.95),
              const Color(0xFF000A1F).withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Game Over Text with Glow Effect
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [Colors.red, Colors.redAccent, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: isSmallScreen ? 28 : 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.red,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 16),

            // Current Score
            Text(
              'PONTUAÇÃO: $currentScore',
              style: TextStyle(
                fontSize: isSmallScreen ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: isSmallScreen ? 2 : 5),
            Text(
              'ONDAS: $currentWave',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                color: Colors.blue[300],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Ranking Title
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isSmallScreen ? 4 : 8
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.withOpacity(0.7), Colors.orange.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'RANKING DE PONTUAÇÕES',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 16),

            // Scores List - altura fixa para evitar overflow
            SizedBox(
              height: isSmallScreen ? 150 : 250,
              child: _buildHighScoresList(isSmallScreen),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // BOTÃO REINICIAR JOGO - Simplificado com um tratamento robusto
            SizedBox(
              width: 200,
              height: 50,
              child: MaterialButton(
                onPressed: () {
                  // Chamada direta do método onPlayAgain
                  onPlayAgain();

                  // Imprimir para debug
                  debugPrint("Botão 'Reiniciar Jogo' pressionado");
                },
                color: Colors.blue,
                textColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 5,
                splashColor: Colors.blueAccent,
                child: const Text(
                  'REINICIAR JOGO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighScoresList(bool isSmallScreen) {
    return FutureBuilder<List<HighScore>>(
      future: HighScoreManager.getHighScores(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Erro ao carregar pontuações',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final highScores = snapshot.data ?? [];

        if (highScores.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
            ),
            child: const Text(
              'Seja o primeiro a entrar no ranking!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        // Container com decoração
        return Container(
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
          ),
          // ListView para rolagem
          child: ListView.builder(
            itemCount: highScores.length,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemBuilder: (context, index) {
              final score = highScores[index];
              final isCurrentScore = score.score == currentScore &&
                  DateTime.now().difference(score.date).inMinutes < 1;

              return _buildScoreRow(score, index, isCurrentScore, isSmallScreen);
            },
          ),
        );
      },
    );
  }

  Widget _buildScoreRow(HighScore score, int index, bool isCurrentScore, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: isCurrentScore
            ? LinearGradient(
          colors: [Colors.blue.withOpacity(0.3), Colors.cyan.withOpacity(0.2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : index == 0
            ? LinearGradient(
          colors: [Colors.amber.withOpacity(0.3), Colors.orange.withOpacity(0.2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : null,
        borderRadius: BorderRadius.circular(10),
        border: isCurrentScore
            ? Border.all(color: Colors.blue.withOpacity(0.6), width: 1.5)
            : index == 0
            ? Border.all(color: Colors.amber.withOpacity(0.6), width: 1.5)
            : Border.all(color: Colors.blueGrey.withOpacity(0.3), width: 0.5),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isSmallScreen ? 6 : 10
      ),
      child: Row(
        children: [
          // Rank Number with Circle
          Container(
            width: isSmallScreen ? 24 : 30,
            height: isSmallScreen ? 24 : 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 0
                  ? Colors.amber.withOpacity(0.8)
                  : (index == 1 ? Colors.grey.shade300.withOpacity(0.8) :
              index == 2 ? Colors.brown.shade300.withOpacity(0.8) :
              Colors.blueGrey.withOpacity(0.5)),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
                color: index <= 2 ? Colors.black87 : Colors.white,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              score.formattedDate,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: isCurrentScore ? Colors.blue.shade300 : Colors.white70,
              ),
            ),
          ),
          // Wave
          Expanded(
            flex: 1,
            child: Text(
              'Onda ${score.wave}',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: isCurrentScore ? Colors.blue.shade300 : Colors.white70,
              ),
            ),
          ),
          // Score
          Text(
            '${score.score}',
            style: TextStyle(
              color: index == 0
                  ? Colors.amber
                  : (isCurrentScore ? Colors.blue.shade300 : Colors.white),
              fontWeight: index <= 2 || isCurrentScore ? FontWeight.bold : FontWeight.normal,
              fontSize: index == 0
                  ? (isSmallScreen ? 16 : 20)
                  : (isSmallScreen ? 14 : 16),
            ),
          ),
        ],
      ),
    );
  }
}

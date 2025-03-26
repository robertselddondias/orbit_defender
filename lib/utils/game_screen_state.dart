// Adicione este import
import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/game_state.dart';
import 'package:orbit_defender/game_controller.dart';
import 'package:orbit_defender/ui/game_over_dialog.dart';
import 'package:orbit_defender/ui/game_screen.dart';
import 'package:orbit_defender/ui/hud.dart';
import 'package:orbit_defender/utils/game_painter.dart';
import 'package:orbit_defender/utils/starfield_painter.dart';

class _GameScreenState extends State<GameScreen> {
  late GameController _gameController;
  bool _isGameOverDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _gameController = GameController();

    // Inicializar o controlador após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _gameController.initialize(size);

      // Atualizar UI quando o controlador emitir mudanças
      _gameController.addListener(_handleControllerChanged);
    });
  }

  void _handleControllerChanged() {
    if (!mounted) return;

    // Atualizar a UI
    setState(() {});

    // Verificar se é game over e mostrar diálogo
    if (_gameController.gameState == GameState.gameOver && !_isGameOverDialogShowing) {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    _isGameOverDialogShowing = true;

    // Use Future.delayed para garantir que a UI está estável
    Future.delayed(Duration.zero, () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameOverDialog(
          score: _gameController.score,
          onRestart: () {
            Navigator.of(context).pop();

            setState(() {
              _isGameOverDialogShowing = false;
            });

            // Pequeno delay antes de reiniciar
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _gameController.reset();
                _gameController.startGame();
              }
            });
          },
        ),
      ).then((_) {
        // Quando o diálogo é fechado de alguma forma
        _isGameOverDialogShowing = false;
      });
    });
  }

  @override
  void dispose() {
    _gameController.removeListener(_handleControllerChanged);
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fundo estrelado
          CustomPaint(
            painter: StarfieldPainter(),
            size: MediaQuery.of(context).size,
          ),

          // Área de jogo - Use opacidade reduzida durante game over
          Opacity(
            opacity: _gameController.gameState == GameState.gameOver ? 0.7 : 1.0,
            child: GestureDetector(
              onTapDown: (details) {
                // Ignore toques durante game over
                if (_gameController.gameState == GameState.gameOver) return;

                if (_gameController.gameState == GameState.ready) {
                  _gameController.startGame();
                } else if (_gameController.gameState == GameState.playing) {
                  _gameController.shootProjectile(details.localPosition);
                }
              },
              child: CustomPaint(
                painter: GamePainter(_gameController),
                size: MediaQuery.of(context).size,
              ),
            ),
          ),

          // HUD - Não mostrar durante game over
          if (_gameController.gameState != GameState.gameOver)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HUD(gameController: _gameController),
            ),

          if (_gameController.shouldShowDifficultyMessage)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _gameController.difficultyMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Botão de pausa - Não mostrar durante game over
          if (_gameController.gameState == GameState.playing ||
              _gameController.gameState == GameState.paused)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(
                  _gameController.gameState == GameState.paused
                      ? Icons.play_arrow
                      : Icons.pause,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => _gameController.pauseGame(),
              ),
            ),

          // Tela inicial
          if (_gameController.gameState == GameState.ready)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ORBIT DEFENDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Toque na tela para começar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 60),
                  Text(
                    'Toque em qualquer lugar para atirar',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Tela de pausa
          if (_gameController.gameState == GameState.paused)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Text(
                  'PAUSADO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Overlay de game over (vermelho suave)
          if (_gameController.gameState == GameState.gameOver)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.red.withOpacity(0.2),
            ),
        ],
      ),
    );
  }
}

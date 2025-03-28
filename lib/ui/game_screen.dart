import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/game_state.dart';
import 'package:orbit_defender/entities/high_score.dart';
import 'package:orbit_defender/entities/special_ability.dart';
import 'package:orbit_defender/game_controller.dart';
import 'package:orbit_defender/manager/game_manager.dart';
import 'package:orbit_defender/ui/hud.dart';
import 'package:orbit_defender/ui/menu_screen.dart';
import 'package:orbit_defender/ui/widgets/abilities_panel.dart';
import 'package:orbit_defender/utils/audio_manager.dart';
import 'package:orbit_defender/utils/game_painter.dart';
import 'package:orbit_defender/utils/high_score_manager.dart';
import 'package:orbit_defender/utils/parallax_starfield_painter.dart';
import 'package:orbit_defender/utils/responsive_utils.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  GameController? _gameController;
  bool _isGameOverDialogShowing = false;

  // Animação para o efeito de paralaxe
  late AnimationController _animationController;
  late Animation<double> _animation;


  @override
  void initState() {
    super.initState();

    // Inicializar animação para o fundo de paralaxe
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(hours: 2), // 2 horas para movimento muito lento
    );
    _animation = Tween<double>(begin: 0, end: 10).animate(_animationController);
    _animationController.forward();

    // Garantir que o áudio está inicializado
    _initializeAudio();

    _initializeGameServices();

    // Criar o jogo
    _createNewGame();

    // Automáticamente iniciar o jogo após a criação
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gameController != null && _gameController!.gameState == GameState.ready) {
        _gameController!.startGame();
        _ensureGameMusicPlaying();
      }
    });
  }

  void _initializeGameServices() async {
    try {
      final bool result = await GameServicesManager().initialize();
      debugPrint('Serviços de jogos inicializados: ${result ? 'Sucesso' : 'Falha'}');
    } catch (e) {
      debugPrint('Erro ao inicializar serviços de jogos: $e');
    }
  }

  void _initializeAudio() {
    try {
      // Inicializar o sistema de áudio no início
      AudioManager().initialize();
      debugPrint('Sistema de áudio inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar sistema de áudio: $e');
    }
  }

  void _createNewGame() {
    // Criar um novo controlador de jogo
    _gameController = GameController();

    // Inicializar em um post-frame callback para garantir que o contexto esteja disponível
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final size = MediaQuery.of(context).size;
      _gameController?.initialize(size);
      _gameController?.addListener(_handleControllerChanged);

      // Forçar atualização da UI
      setState(() {});
    });
  }

  void _handleControllerChanged() {
    if (!mounted || _gameController == null) return;

    // Atualizar UI
    setState(() {});

    // Verificar mudanças de estado que afetam o áudio
    final currentState = _gameController!.gameState;

    // Game Over
    if (currentState == GameState.gameOver && !_isGameOverDialogShowing) {
      _showGameOverScreen();
    }

    // Jogo iniciado - garantir que a música está tocando
    if (currentState == GameState.playing) {
      _ensureGameMusicPlaying();
    }

    // Jogo pausado - pausar a música
    if (currentState == GameState.paused) {
      _handlePauseAudio();
    }
  }

  void _ensureGameMusicPlaying() {
    try {
      // Verificar se a música já está tocando para evitar reiniciar
      if (!AudioManager().isMusicPlaying()) {
        debugPrint('Iniciando música do jogo');
        AudioManager().playMusic('game_music.mp3');
      }
    } catch (e) {
      debugPrint('Erro ao iniciar música do jogo: $e');
    }
  }

  void _handlePauseAudio() {
    try {
      debugPrint('Pausando música do jogo');
      AudioManager().pauseMusic();
    } catch (e) {
      debugPrint('Erro ao pausar música: $e');
    }
  }

  void _showGameOverScreen() {
    _isGameOverDialogShowing = true;

    // Parar música e tocar som de game over
    try {
      debugPrint('Game Over: Parando música e tocando som de game over');
      AudioManager().stopMusic(); // Garantir que a música pare completamente
      AudioManager().playGameOverSound();
    } catch (e) {
      debugPrint('Erro ao controlar áudio de game over: $e');
    }

    // Salvar pontuação
    HighScoreManager.addScore(_gameController!.score, _gameController!.wave);

    _submitScoreToGameServices();

    // Mostrar tela de game over
    _showGameOverDialog();
  }

  void _submitScoreToGameServices() async {
    if (_gameController == null) return;

    final int score = _gameController!.score;
    final int wave = _gameController!.wave;

    try {
      await GameServicesManager().processGameOver(score, wave);
      debugPrint('Pontuação enviada para serviços de jogos');
    } catch (e) {
      debugPrint('Erro ao enviar pontuação para serviços de jogos: $e');
    }
  }

  void _showGameOverDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _buildGameOverDialog(dialogContext),
    );
  }

  // Substitua o método _buildGameOverDialog por esta versão corrigida
  Widget _buildGameOverDialog(BuildContext dialogContext) {
    if (_gameController == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(dialogContext).size;
    final responsive = ResponsiveUtils(context: dialogContext);

    return WillPopScope(
      onWillPop: () async => false, // Impedir que o usuário feche o diálogo com botão voltar
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(responsive.dp(15)),
        child: FutureBuilder<List<HighScore>>(
          future: HighScoreManager.getHighScores(),
          builder: (context, snapshot) {
            final highScores = snapshot.data ?? [];

            return Container(
              width: screenSize.width * (responsive.isTablet ? 0.7 : 0.9),
              // Removemos o padding vertical fixo e usamos constraints para limitar altura
              padding: EdgeInsets.symmetric(
                  vertical: responsive.dp(15),
                  horizontal: responsive.dp(16)
              ),
              constraints: BoxConstraints(
                maxHeight: screenSize.height * 0.85, // Limita a altura máxima do diálogo
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
                borderRadius: BorderRadius.circular(responsive.dp(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: responsive.dp(20),
                    spreadRadius: responsive.dp(5),
                  ),
                ],
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: responsive.dp(2),
                ),
              ),
              // Usamos uma SingleChildScrollView para permitir rolagem em dispositivos menores
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Game Over Text
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
                          fontSize: responsive.dp(30), // Reduzido de 34 para 30
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: responsive.dp(10.0),
                              color: Colors.red,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.dp(12)), // Reduzido de 16 para 12

                    // Current Score
                    Text(
                      'PONTUAÇÃO: ${_gameController!.score}',
                      style: TextStyle(
                        fontSize: responsive.dp(26), // Reduzido de 28 para 26
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: responsive.dp(4)), // Reduzido de 5 para 4
                    Text(
                      'ONDAS: ${_gameController!.wave}',
                      style: TextStyle(
                        fontSize: responsive.dp(16), // Reduzido de 18 para 16
                        color: Colors.blue[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: responsive.dp(16)), // Reduzido de 20 para 16

                    // Ranking Title
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: responsive.dp(12), // Reduzido de 16 para 12
                          vertical: responsive.dp(6) // Reduzido de 8 para 6
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.withOpacity(0.7), Colors.orange.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(responsive.dp(12)),
                      ),
                      child: Text(
                        'RANKING DE PONTUAÇÕES',
                        style: TextStyle(
                          fontSize: responsive.dp(18), // Reduzido de 20 para 18
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.dp(12)), // Reduzido de 16 para 12

                    // Scores List - altura adaptativa com base no dispositivo e espaço disponível
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: responsive.screenHeight * (responsive.isTablet ? 0.35 : 0.25), // Reduzido de 0.4/0.3 para 0.35/0.25
                      ),
                      child: _buildHighScoresList(highScores, responsive),
                    ),

                    SizedBox(height: responsive.dp(16)), // Reduzido de 20 para 16

                    // Botões de ação - usando layout flexível para evitar overflow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              elevation: 5,
                              padding: EdgeInsets.symmetric(
                                  horizontal: responsive.dp(8),
                                  vertical: responsive.dp(12)
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(responsive.dp(30)),
                              ),
                            ),
                            onPressed: () {
                              // Fechar este diálogo primeiro
                              Navigator.of(dialogContext).pop();

                              // Depois criar um novo jogo
                              _restartGame();
                            },
                            child: Text(
                              'REINICIAR',
                              style: TextStyle(
                                fontSize: responsive.dp(13),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: responsive.dp(10)),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade600,
                              foregroundColor: Colors.white,
                              elevation: 5,
                              padding: EdgeInsets.symmetric(
                                  horizontal: responsive.dp(8),
                                  vertical: responsive.dp(12)
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(responsive.dp(30)),
                              ),
                            ),
                            onPressed: () {
                              // Fechar este diálogo primeiro
                              Navigator.of(dialogContext).pop();

                              // Navegar para o menu principal
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => MenuScreen()),
                              );
                            },
                            child: Text(
                              'MENU',
                              style: TextStyle(
                                fontSize: responsive.dp(13),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: responsive.dp(10)),

// BOTÕES DE SERVIÇOS DE JOGO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // BOTÃO LEADERBOARD GLOBAL
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
                              foregroundColor: Colors.white,
                              elevation: 5,
                              padding: EdgeInsets.symmetric(
                                  horizontal: responsive.dp(8),
                                  vertical: responsive.dp(12)
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(responsive.dp(30)),
                              ),
                            ),
                            onPressed: () {
                              // Mostrar leaderboard global
                              GameServicesManager().showLeaderboard();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min, // Adicione esta linha
                              children: [
                                Icon(Icons.leaderboard, size: responsive.dp(14)), // Reduza o tamanho do ícone
                                SizedBox(width: responsive.dp(4)), // Reduza o espaçamento
                                Flexible( // Envolva o texto com Flexible
                                  child: Text(
                                    'RANKING',
                                    style: TextStyle(
                                      fontSize: responsive.dp(12), // Reduza o tamanho da fonte
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5, // Reduza o espaçamento entre letras
                                    ),
                                    overflow: TextOverflow.ellipsis, // Permite que o texto seja cortado com "..." se necessário
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(width: responsive.dp(10)),

                        // BOTÃO CONQUISTAS
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              elevation: 5,
                              padding: EdgeInsets.symmetric(
                                  horizontal: responsive.dp(8),
                                  vertical: responsive.dp(12)
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(responsive.dp(30)),
                              ),
                            ),
                            onPressed: () {
                              // Mostrar tela de conquistas
                              GameServicesManager().showAchievements();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min, // Adicione esta linha para minimizar o espaço
                              children: [
                                Icon(Icons.emoji_events, size: responsive.dp(14)), // Reduza o tamanho do ícone
                                SizedBox(width: responsive.dp(4)), // Reduza o espaçamento
                                Flexible( // Envolva o texto com Flexible
                                  child: Text(
                                    'CONQUISTAS',
                                    style: TextStyle(
                                      fontSize: responsive.dp(12), // Reduza o tamanho da fonte
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5, // Reduza o espaçamento entre letras
                                    ),
                                    overflow: TextOverflow.ellipsis, // Permite que o texto seja cortado se necessário
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _restartGame() {
    debugPrint('Reiniciando jogo...');

    // Limpar estado
    _isGameOverDialogShowing = false;

    // Limpar o controlador atual e garantir que todo áudio pare
    if (_gameController != null) {
      _gameController!.removeListener(_handleControllerChanged);
      _gameController!.dispose();
      _gameController = null;
    }

    // Parar todo o áudio antes de reiniciar
    try {
      AudioManager().stopMusic();
      AudioManager().stopAllSounds();
      debugPrint('Todo áudio foi interrompido para reinício do jogo');
    } catch (e) {
      debugPrint('Erro ao interromper áudio: $e');
    }

    // Criar um novo jogo
    _createNewGame();

    // Iniciar o jogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _gameController == null) return;

      _gameController!.startGame();

      // Garantir que a música de jogo começa a tocar
      _ensureGameMusicPlaying();

      setState(() {});
    });
  }

  @override
  void dispose() {
    // Parar áudio quando a tela for descartada
    try {
      AudioManager().stopMusic();
      AudioManager().stopAllSounds();
      debugPrint('Áudio interrompido ao sair da tela');
    } catch (e) {
      debugPrint('Erro ao interromper áudio em dispose: $e');
    }

    // Limpar recursos
    _animationController.dispose();

    if (_gameController != null) {
      _gameController!.removeListener(_handleControllerChanged);
      _gameController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Criar utilitário responsivo
    final responsive = ResponsiveUtils(context: context);

    // Verificar se o controlador está inicializado
    if (_gameController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fundo estrelado com paralaxe
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParallaxStarfieldPainter(
                  animationValue: _animation.value,
                  starCount: 120,
                  // Velocidades extremamente baixas
                  nearStarsSpeed: 0.002,
                  midStarsSpeed: 0.0008,
                  farStarsSpeed: 0.0002,
                ),
                size: MediaQuery.of(context).size,
              );
            },
          ),

          // Área de jogo
          Opacity(
            opacity: _gameController!.gameState == GameState.gameOver ? 0.7 : 1.0,
            child: GestureDetector(
              onTapDown: (details) {
                if (_gameController!.gameState == GameState.gameOver ||
                    _gameController!.gameState == GameState.paused) {
                  return;
                }

                // Removemos a verificação de GameState.ready, pois o jogo já começa em playing
                if (_gameController!.gameState == GameState.playing) {
                  _gameController!.shootProjectile(details.localPosition);
                }
              },
              child: CustomPaint(
                painter: GamePainter(_gameController!),
                size: MediaQuery.of(context).size,
              ),
            ),
          ),

          // HUD
          if (_gameController!.gameState != GameState.gameOver)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HUD(gameController: _gameController!),
            ),

          // Painel de Habilidades Especiais
          if (_gameController!.gameState == GameState.playing)
            Positioned(
              bottom: responsive.dp(30),
              left: 0,
              right: 0,
              child: Center(
                child: AbilitiesPanel(
                  onAbilityActivated: (SpecialAbilityType type) {
                    _gameController!.activateSpecialAbility(type);
                  },
                ),
              ),
            ),

          // Botão de pausa - ajustado para diferentes tamanhos de tela
          if (_gameController!.gameState == GameState.playing ||
              _gameController!.gameState == GameState.paused)
            Positioned(
              top: responsive.dp(40),
              right: responsive.dp(20),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _gameController!.pauseGame();

                    // Alternar o estado da música com base no estado do jogo
                    if (_gameController!.gameState == GameState.paused) {
                      _handlePauseAudio();
                    } else if (_gameController!.gameState == GameState.playing) {
                      _ensureGameMusicPlaying();
                    }
                  });
                },
                child: Container(
                  width: responsive.dp(50),
                  height: responsive.dp(50),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _gameController!.gameState == GameState.paused
                          ? Icons.play_arrow
                          : Icons.pause,
                      color: Colors.white,
                      size: responsive.dp(30),
                    ),
                  ),
                ),
              ),
            ),

          // Tela de pausa
          if (_gameController!.gameState == GameState.paused)
            _buildPauseScreen(responsive),

          // Overlay de game over (vermelho suave)
          if (_gameController!.gameState == GameState.gameOver)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.red.withOpacity(0.2),
            ),
          if (_gameController != null && _gameController!.gameState == GameState.playing)
            Positioned(
              bottom: responsive.dp(30),
              left: 0,
              right: 0,
              child: Center(
                child: AbilitiesPanel(
                  onAbilityActivated: (SpecialAbilityType type) {
                    _gameController!.activateSpecialAbility(type);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // void _registerSpecialAbilitySounds() {
  //   try {
  //     // Registrar os sons para as habilidades especiais
  //     AudioManager().preloadSound('super_shot.mp3');
  //     AudioManager().preloadSound('area_bomb.mp3');
  //     AudioManager().preloadSound('time_warp.mp3');
  //     AudioManager().preloadSound('magnet_field.mp3');
  //     AudioManager().preloadSound('rapid_fire.mp3');
  //   } catch (e) {
  //     debugPrint('Erro ao pré-carregar sons de habilidades: $e');
  //   }
  // }

  Widget _buildPauseScreen(ResponsiveUtils responsive) {
    return Container(
      color: Colors.black54,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PAUSADO',
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.dp(32),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsive.dp(40)),
            GestureDetector(
              onTap: () {
                setState(() {
                  _gameController!.pauseGame();

                  // Retomar música quando o jogo for despausado
                  if (_gameController!.gameState == GameState.playing) {
                    try {
                      debugPrint('Retomando música após pausa');
                      AudioManager().resumeMusic();
                    } catch (e) {
                      debugPrint('Erro ao retomar música: $e');
                    }
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: responsive.dp(30),
                    vertical: responsive.dp(15)
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(responsive.dp(10)),
                ),
                child: Text(
                  'CONTINUAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.dp(18),
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

  Widget _buildHighScoresList(List<HighScore> highScores, ResponsiveUtils responsive) {
    if (highScores.isEmpty) {
      return Container(
        padding: EdgeInsets.all(responsive.dp(16)),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(responsive.dp(12)),
          border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
        ),
        child: Text(
          'Seja o primeiro a entrar no ranking!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: responsive.dp(16),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(responsive.dp(16)),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
      ),
      child: ListView.builder(
        itemCount: highScores.length,
        padding: EdgeInsets.symmetric(vertical: responsive.dp(4)),
        itemBuilder: (context, index) {
          final score = highScores[index];
          final isCurrentScore = _gameController != null &&
              score.score == _gameController!.score &&
              DateTime.now().difference(score.date).inMinutes < 1;

          return _buildScoreRow(score, index, isCurrentScore, responsive);
        },
      ),
    );
  }

  Widget _buildScoreRow(HighScore score, int index, bool isCurrentScore, ResponsiveUtils responsive) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: responsive.dp(8),
          vertical: responsive.dp(3)
      ),
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
        borderRadius: BorderRadius.circular(responsive.dp(10)),
        border: isCurrentScore
            ? Border.all(color: Colors.blue.withOpacity(0.6), width: responsive.dp(1.5))
            : index == 0
            ? Border.all(color: Colors.amber.withOpacity(0.6), width: responsive.dp(1.5))
            : Border.all(color: Colors.blueGrey.withOpacity(0.3), width: responsive.dp(0.5)),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: responsive.dp(12),
          vertical: responsive.dp(10)
      ),
      child: Row(
        children: [
          // Rank Number with Circle
          Container(
            width: responsive.dp(30),
            height: responsive.dp(30),
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
                fontSize: responsive.dp(14),
                color: index <= 2 ? Colors.black87 : Colors.white,
              ),
            ),
          ),
          SizedBox(width: responsive.dp(12)),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              score.formattedDate,
              style: TextStyle(
                fontSize: responsive.dp(14),
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
                fontSize: responsive.dp(14),
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
                  ? responsive.dp(20)
                  : responsive.dp(16),
            ),
          ),
        ],
      ),
    );
  }
}

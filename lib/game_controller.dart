// Controlador principal do jogo
import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:orbit_defender/entities/cannon.dart';
import 'package:orbit_defender/entities/enemy.dart';
import 'package:orbit_defender/entities/explosion.dart';
import 'package:orbit_defender/entities/game_state.dart';
import 'package:orbit_defender/entities/power_up.dart';
import 'package:orbit_defender/entities/power_up_type.dart';
import 'package:orbit_defender/entities/projectile.dart';
import 'package:orbit_defender/utils/audio_manager.dart';
import 'package:orbit_defender/utils/high_score_manager.dart';
import 'package:orbit_defender/utils/math_utils.dart';

class GameController extends ChangeNotifier {
  // Flag de inicialização
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Estado do jogo
  GameState _gameState = GameState.ready;
  GameState get gameState => _gameState;

  // Dimensões da tela
  late Size _screenSize;
  Size get screenSize => _screenSize;

  // Pontuação e vidas
  int _score = 0;
  int get score => _score;

  int _lives = 3;
  int get lives => _lives;

  int _wave = 1;
  int get wave => _wave;

  // Entidades
  Cannon? _cannon;
  Cannon get cannon => _cannon ?? Cannon(position: Offset.zero, radius: 25);

  final List<Projectile> _projectiles = [];
  List<Projectile> get projectiles => _projectiles;

  final List<Enemy> _enemies = [];
  List<Enemy> get enemies => _enemies;

  final List<PowerUp> _powerUps = [];
  List<PowerUp> get powerUps => _powerUps;

  final List<Explosion> _explosions = [];
  List<Explosion> get explosions => _explosions;

  // Timers
  Timer? _gameLoop;
  Timer? _enemySpawner;
  Timer? _powerUpSpawner;
  Timer? _waveTimer;

  // Random number generator
  final Random _random = Random();

  double _difficultyLevel = 1.0;
  double get difficultyLevel => _difficultyLevel;

// Pontuações para níveis de dificuldade
  final List<int> _difficultyThresholds = [
    0,       // Nível 1
    500,     // Nível 2 - começa mais cedo (500 pontos)
    1500,    // Nível 3
    3000,    // Nível 4
    5000,    // Nível 5
    8000,    // Nível 6
    12000,   // Nível 7
    18000,   // Nível 8
    25000,   // Nível 9
    35000,   // Nível 10 - máximo em 35000 pontos
  ];

// Tempos entre spawns de inimigos por nível (em milissegundos)
  final List<int> _enemySpawnIntervals = [
    800,   // Nível 1: a cada 0.8 segundos (quase 2x mais rápido que antes)
    700,   // Nível 2
    600,   // Nível 3
    500,   // Nível 4
    450,   // Nível 5
    400,   // Nível 6
    350,   // Nível 7
    300,   // Nível 8
    250,   // Nível 9
    200,   // Nível 10: a cada 0.2 segundos (MUITO frequente!)
  ];

// Probabilidade de inimigos rápidos por nível (porcentagem)
  final List<double> _fastEnemyProbabilities = [
    0.2,   // Nível 1: 20%
    0.25,  // Nível 2
    0.3,   // Nível 3
    0.35,  // Nível 4
    0.4,   // Nível 5
    0.45,  // Nível 6
    0.5,   // Nível 7
    0.55,  // Nível 8
    0.6,   // Nível 9
    0.7,   // Nível 10: 70%
  ];

  final List<int> _powerUpSpawnIntervals = [
    20,   // Nível 1: a cada 20 segundos (era 15)
    18,   // Nível 2: (era 13)
    16,   // Nível 3: (era 11)
    14,   // Nível 4: (era 10)
    12,   // Nível 5: (era 9)
    11,   // Nível 6: (era 8)
    10,   // Nível 7: (era 7)
    9,    // Nível 8: (era 6)
    8,    // Nível 9: (era 5)
    7,    // Nível 10: a cada 7 segundos (era 4)
  ];

// Probabilidade de spawn de power-up por nível (percentual)
  final List<double> _powerUpProbabilities = [
    0.5,   // Nível 1: 50% de chance (era 60%)
    0.55,  // Nível 2
    0.6,   // Nível 3
    0.65,  // Nível 4
    0.7,   // Nível 5
    0.75,  // Nível 6
    0.8,   // Nível 7
    0.85,  // Nível 8
    0.9,   // Nível 9
    0.95,  // Nível 10: 95% de chance (era 100%)
  ];

// Multiplicadores de velocidade base por nível
  final List<double> _speedMultipliers = [
    0.7,   // Nível 1: mais lento no começo
    0.9,   // Nível 2
    1.1,   // Nível 3
    1.3,   // Nível 4
    1.5,   // Nível 5
    1.7,   // Nível 6
    1.9,   // Nível 7
    2.2,   // Nível 8
    2.5,   // Nível 9
    3.0,   // Nível 10: 3x mais rápido que a velocidade base
  ];

  bool _showingDifficultyChange = false;
  String _difficultyMessage = "";
  DateTime? _difficultyMessageTime;

  bool _isNewHighScore = false;
  bool get isNewHighScore => _isNewHighScore;


  final Map<PowerUpType, int> _collectedPowerUps = {
    PowerUpType.tripleShot: 0,
    PowerUpType.shield: 0,
    PowerUpType.speedBoost: 0,
    PowerUpType.extraLife: 0,
  };

  // Debug
  bool _debugMode = false;
  set debugMode(bool value) {
    _debugMode = value;
    if (_debugMode) {
      debugPrint('Modo de depuração ativado');
    }
  }

  void _log(String message) {
    if (_debugMode) {
      debugPrint('GameController: $message');
    }
  }

  // Inicialização do controlador
  void initialize(Size screenSize) {
    _screenSize = screenSize;

    // Criar canhão no centro da tela
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    _cannon = Cannon(position: center, radius: 25);

    // Inicializar o gerenciador de áudio
    AudioManager().initialize();

    _isInitialized = true;
    _log('Controlador inicializado com tamanho de tela: $screenSize');

    reset();
  }

  String getDifficultyDetails() {
    final int index = (_difficultyLevel - 1).clamp(0, 9).toInt();

    return '''
  Nível de Dificuldade: ${_difficultyLevel.toInt()} (${_difficultyLevel.toStringAsFixed(1)})
  Pontuação: $_score
  Próximo nível: ${index < 9 ? _difficultyThresholds[index + 1] : "MAX"}
  Intervalo de spawn: ${_enemySpawnIntervals[index]} ms
  Multiplicador de velocidade: ${_speedMultipliers[index].toStringAsFixed(1)}x
  Probabilidade de inimigos rápidos: ${(_fastEnemyProbabilities[index] * 100).toInt()}%
  ''';
  }

  void _updateDifficultyLevel() {
    // Nível de dificuldade anterior
    final double previousLevel = _difficultyLevel;

    // Encontrar o nível com base nos thresholds
    int level = 1;
    for (int i = 1; i < _difficultyThresholds.length; i++) {
      if (_score >= _difficultyThresholds[i]) {
        level = i + 1;
      } else {
        break;
      }
    }

    // Converter para valor de dificuldade (1.0 - 10.0)
    _difficultyLevel = level.toDouble();

    // Se o nível de dificuldade mudou, atualizar intervalos de spawn
    if (_difficultyLevel != previousLevel) {
      _updateSpawnIntervals();

      _updatePowerUpSpawner();

      // Se aumentou, mostrar mensagem
      if (_difficultyLevel > previousLevel) {
        _showDifficultyChangeMessage();
        _spawnLevelUpPowerUps();
      }
    }

    _log('Dificuldade atualizada: Nível $level (${_difficultyLevel.toStringAsFixed(1)})');
  }

  void _spawnLevelUpPowerUps() {
    _log('Criando power-ups de novo nível!');

    // Calcular número de power-ups baseado no nível
    final int newLevel = _difficultyLevel.toInt();
    final int numPowerUps = newLevel + 1; // Nível 2 = 3 power-ups, Nível 10 = 11 power-ups

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_gameState == GameState.playing) {
        _spawnPowerUp(isLevelUpBonus: true);
      }
    });

    // Tocar som especial para banquete de power-ups
    try {
      AudioManager().playSound('powerup_bonanza');
    } catch (e) {
      _log('Erro ao tocar som de banquete de power-ups: $e');
    }
  }

  void _spawnPowerUp({bool isLevelUpBonus = false}) {
    if (!_isInitialized || _gameState != GameState.playing) return;

    PowerUpType type;

    if (isLevelUpBonus) {
      // Para power-ups de level up, usar lógica baseada no nível e raridade
      final double rand = _random.nextDouble();
      final int level = _difficultyLevel.toInt();

      if (_lives < 2 && rand < 0.4) {
        // Se o jogador tem poucas vidas, aumentar chance de vida extra
        type = PowerUpType.extraLife;
      } else if (level >= 5 && rand < 0.5) {
        // Em níveis mais altos, dar o tipo menos coletado
        type = _getLeastCollectedPowerUpType();
      } else if (rand < 0.7) {
        // 20% de chance de escudo
        type = PowerUpType.shield;
      } else if (rand < 0.9) {
        // 20% de chance para tiro triplo
        type = PowerUpType.tripleShot;
      } else {
        // 10% de chance para speedBoost
        type = PowerUpType.speedBoost;
      }
    } else {
      // Para power-ups normais, usar uma distribuição balanceada
      final double rand = _random.nextDouble();

      if (_lives <= 2 && rand < 0.3) {
        // Se o jogador estiver com poucas vidas, mais chance de vida extra
        type = PowerUpType.extraLife;
      } else if (rand < 0.4) {
        // 10% chance (ou 40% se não precisou de vida) para vida extra
        type = PowerUpType.extraLife;
      } else if (rand < 0.6) {
        // 20% chance para escudo
        type = PowerUpType.shield;
      } else if (rand < 0.8) {
        // 20% chance para tiro triplo
        type = PowerUpType.tripleShot;
      } else {
        // 20% chance para boost de velocidade
        type = PowerUpType.speedBoost;
      }
    }

    // Margem de segurança para não aparecer muito perto das bordas
    const margin = 50.0;

    // Posição para power-ups normais: aleatória na tela
    // Para power-ups de level up: posicionados em círculo ao redor do jogador
    Offset position;

    if (isLevelUpBonus && _cannon != null) {
      // Para power-ups de level up, criar em círculo em volta do jogador
      final int newLevel = _difficultyLevel.toInt();
      final int totalPowerUps = newLevel + 1;
      final int index = _powerUps.length % totalPowerUps;
      final double angle = (index / totalPowerUps) * 2 * pi;
      const double radius = 100.0; // Distância do jogador

      // Calcular posição em círculo
      position = Offset(
        _cannon!.position.dx + radius * cos(angle),
        _cannon!.position.dy + radius * sin(angle),
      );

      // Garantir que está dentro dos limites da tela
      position = Offset(
        position.dx.clamp(margin, _screenSize.width - margin),
        position.dy.clamp(margin, _screenSize.height - margin),
      );
    } else {
      // Posição aleatória na tela para power-ups normais
      position = Offset(
        margin + _random.nextDouble() * (_screenSize.width - 2 * margin),
        margin + _random.nextDouble() * (_screenSize.height - 2 * margin),
      );
    }

    // Direção aleatória para power-ups normais
    // Para power-ups de level up: direção em direção ao jogador
    Offset direction;

    if (isLevelUpBonus && _cannon != null) {
      // Direção lentamente em direção ao jogador
      direction = (_cannon!.position - position).normalized();
    } else {
      // Direção aleatória para power-ups normais
      direction = Offset(
        _random.nextDouble() * 2 - 1,
        _random.nextDouble() * 2 - 1,
      ).normalized();
    }

    // Velocidade: mais rápida para power-ups de level up
    double speed = isLevelUpBonus ? 0.5 : 1.0;

    // Criar power-up
    final powerUp = PowerUp(
      position: position,
      direction: direction,
      speed: speed,
      radius: 20,
      type: type,
      isLevelUpBonus: isLevelUpBonus, // Definir a propriedade
    );

    _powerUps.add(powerUp);
    _log('Power-up criado: $type em $position${isLevelUpBonus ? ' (Bônus de level up)' : ''}');
  }

  void _showDifficultyChangeMessage() {
    _showingDifficultyChange = true;
    _difficultyMessage = "DIFICULDADE AUMENTADA: NÍVEL ${_difficultyLevel.toInt()}";
    _difficultyMessageTime = DateTime.now();

    // Reproduzir som especial para aumento de dificuldade
    try {
      AudioManager().playSound('difficulty_up');
    } catch (e) {
      _log('Erro ao reproduzir som de aumento de dificuldade: $e');
    }

    // Esconder a mensagem após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      _showingDifficultyChange = false;
      notifyListeners();
    });

    notifyListeners();
  }

  String get difficultyMessage => _difficultyMessage;

  bool get shouldShowDifficultyMessage {
    if (!_showingDifficultyChange) return false;
    if (_difficultyMessageTime == null) return false;

    // Só mostrar a mensagem se estiver dentro de 3 segundos da mudança
    final difference = DateTime.now().difference(_difficultyMessageTime!);
    return difference.inSeconds < 3;
  }

  void _updateSpawnIntervals() {
    // Determinar o índice de dificuldade (0-9)
    final int index = (_difficultyLevel - 1).clamp(0, 9).toInt();

    // Obter o intervalo para o nível atual
    final int interval = _enemySpawnIntervals[index];

    // Atualizar timer de spawn de inimigos
    _updateEnemySpawner(interval);

    _log('Intervalo de spawn atualizado: ${interval}ms (Nível ${_difficultyLevel.toInt()})');
  }

  void _updateEnemySpawner(int intervalMs) {
    // Verificar se o intervalo é válido
    if (intervalMs <= 0) {
      _log('ERRO: Tentativa de definir intervalo de spawn inválido: $intervalMs');
      intervalMs = 500; // Valor padrão seguro
    }

    // Cancelar spawner existente
    if (_enemySpawner != null) {
      _enemySpawner!.cancel();
      _enemySpawner = null;
    }

    // Iniciar novo spawner com intervalo baseado na dificuldade
    _enemySpawner = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_gameState == GameState.playing) {
        _spawnEnemy();
      }
    });

    _log('Spawner de inimigos atualizado: intervalo = $intervalMs ms');
  }

  // Reiniciar o jogo
  void reset() {
    if (!_isInitialized) return;

    _score = 0;
    _lives = 3;
    _wave = 1;
    _difficultyLevel = 1.0; // Reset da dificuldade

    // Limpar contadores de power-ups
    for (final type in PowerUpType.values) {
      _collectedPowerUps[type] = 0;
    }

    _projectiles.clear();
    _enemies.clear();
    _powerUps.clear();
    _explosions.clear();

    _cannon?.reset();

    // Parar todos os timers
    _stopTimers();

    _gameState = GameState.ready;
    _log('Jogo reiniciado');
    notifyListeners();
  }

  // Iniciar o jogo
  void startGame() {
    if (_gameState == GameState.ready || _gameState == GameState.gameOver) {
      _gameState = GameState.playing;

      // Iniciar com dificuldade inicial
      _difficultyLevel = 1.0;
      _updateDifficultyLevel();

      // Iniciar música de fundo
      try {
        AudioManager().playMusic('game_music.mp3');
      } catch (e) {
        _log('Erro ao iniciar música: $e');
      }

      // Iniciar loop principal
      _startGameLoop();

      // Iniciar spawners com intervalos baseados na dificuldade inicial
      // Use diretamente o primeiro valor da lista para garantir
      _startEnemySpawner(); // Isso chamará _updateSpawnIntervals()
      _startPowerUpSpawner();

      // Iniciar timer de ondas
      _startWaveTimer();

      _log('Jogo iniciado com intervalo de spawn: ${_enemySpawnIntervals[0]}ms');
      notifyListeners();
    }
  }

  // Pausar/retomar o jogo
  void pauseGame() {
    _log('Método pauseGame() chamado. Estado atual: $_gameState');

    if (_gameState == GameState.playing) {
      // Pausar o jogo
      _gameState = GameState.paused;

      // Pausar música
      AudioManager().pauseMusic();

      // Parar todos os timers
      _stopTimers();

      _log('Jogo pausado');
      notifyListeners();
    }
    else if (_gameState == GameState.paused) {
      // Retomar o jogo
      _gameState = GameState.playing;

      // Retomar música
      AudioManager().resumeMusic();

      // Reiniciar loop e spawners
      _startGameLoop();
      _startEnemySpawner();
      _startPowerUpSpawner();
      _startWaveTimer();

      _log('Jogo retomado');
      notifyListeners();
    }
  }

  // Game over
  void _gameOver() {
    // Evitar múltiplas chamadas
    if (_gameState == GameState.gameOver) return;

    _log('Game Over!');

    // Parar todos os timers
    _stopTimers();

    // Parar música e tocar som de game over
    AudioManager().stopMusic();
    AudioManager().playGameOverSound();

    _saveHighScore();

    // Limpar projéteis e power-ups
    _projectiles.clear();
    _powerUps.clear();

    // Mudar estado
    _gameState = GameState.gameOver;

    notifyListeners();
  }

  // Adicione este novo método para salvar a pontuação
  Future<void> _saveHighScore() async {
    try {
      _isNewHighScore = await HighScoreManager.addScore(_score, _wave);

      if (_isNewHighScore) {
        _log('Nova pontuação alta registrada: $_score');
        // Você pode adicionar um som especial para novo recorde
        try {
          AudioManager().playSound('new_high_score');
        } catch (e) {
          _log('Erro ao tocar som de novo recorde: $e');
        }
      }
    } catch (e) {
      _log('Erro ao salvar pontuação: $e');
    }
  }

  // Loop principal do jogo
  void _startGameLoop() {
    _log('Iniciando loop principal do jogo');

    // Cancelar loop existente
    _gameLoop?.cancel();

    // Iniciar novo loop
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_gameState == GameState.playing) {
        _updateGame();
        notifyListeners();
      }
    });
  }

  // Timer de ondas
  void _startWaveTimer() {
    _log('Iniciando timer de ondas');

    // Cancelar timer existente
    _waveTimer?.cancel();

    // Criar primeiro grupo de inimigos
    _spawnWave();

    final int index = (_difficultyLevel - 1).clamp(0, 9).toInt();
    final int intervalSeconds = 30 - (index * 1.5).round();

    // Iniciar timer para ondas subsequentes
    _waveTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      if (_gameState == GameState.playing) {
        _wave++;
        _log('Nova onda iniciada: $_wave');
        _spawnWave();
      }
    });
  }

  // Spawner de inimigos
  void _startEnemySpawner() {
    _log('Iniciando spawner de inimigos');
    _updateSpawnIntervals();
  }

  // Spawner de power-ups
  void _startPowerUpSpawner() {
    _log('Iniciando spawner de power-ups');

    // Cancelar spawner existente
    _powerUpSpawner?.cancel();

    final int index = (_difficultyLevel - 1).clamp(0, 9).toInt();
    final int intervalSeconds = _powerUpSpawnIntervals[index];

    // Iniciar novo spawner
    _powerUpSpawner = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      if (_gameState == GameState.playing) {
        // Obter probabilidade de spawn baseada no nível
        final double spawnProbability = _powerUpProbabilities[index];

        // Verificar se o power-up deve aparecer
        if (_random.nextDouble() < spawnProbability) {
          _spawnPowerUp();
        }
      }
    });
  }

  void _updatePowerUpSpawner() {
    // Verificar se o jogo está em andamento
    if (_gameState != GameState.playing) return;

    // Reiniciar o spawner de power-ups com novos valores
    _startPowerUpSpawner();
  }


  void _stopTimers() {
    if (_gameLoop != null) {
      _gameLoop!.cancel();
      _gameLoop = null;
      _log('Loop principal parado');
    }

    if (_enemySpawner != null) {
      _enemySpawner!.cancel();
      _enemySpawner = null;
      _log('Spawner de inimigos parado');
    }

    if (_powerUpSpawner != null) {
      _powerUpSpawner!.cancel();
      _powerUpSpawner = null;
      _log('Spawner de power-ups parado');
    }

    if (_waveTimer != null) {
      _waveTimer!.cancel();
      _waveTimer = null;
      _log('Timer de ondas parado');
    }
  }

  // Atualizar estado do jogo
  void _updateGame() {
    if (!_isInitialized || _gameState != GameState.playing) return;

    _updateDifficultyLevel();

    // Atualizar projéteis
    for (int i = _projectiles.length - 1; i >= 0; i--) {
      _projectiles[i].update();

      // Remover projéteis fora da tela
      if (!_isOnScreen(_projectiles[i].position, buffer: 20)) {
        _projectiles.removeAt(i);
      }
    }

    // Atualizar inimigos
    for (int i = _enemies.length - 1; i >= 0; i--) {
      _enemies[i].update();

      // Verificar colisão com o canhão
      if (_cannon != null && circleCollision(
          _cannon!.position, _cannon!.radius,
          _enemies[i].position, _enemies[i].radius)) {

        // Criar explosão
        _addExplosion(_enemies[i].position);

        // Tocar som de explosão
        AudioManager().playSmallExplosionSound();

        // Remover inimigo
        _enemies.removeAt(i);

        // Não reduzir vida se tiver escudo
        if (!_cannon!.hasPowerUp(PowerUpType.shield)) {
          // Tocar som de dano
          AudioManager().playPlayerHitSound();

          _lives = (_lives - 1).clamp(0, 5);

          // Verificar game over
          if (_lives <= 0) {
            _gameOver();
            return;
          }
        } else {
          // Som de escudo absorvendo impacto
          AudioManager().playShieldSound();
        }

        continue;
      }

      // Verificar colisão com projéteis
      bool hit = false;
      for (int j = _projectiles.length - 1; j >= 0; j--) {
        if (circleCollision(
            _projectiles[j].position, _projectiles[j].radius,
            _enemies[i].position, _enemies[i].radius)) {

          // Adicionar pontos
          _score += _enemies[i].pointValue;

          // Criar explosão
          _addExplosion(_enemies[i].position);

          AudioManager().playSmallExplosionSound();

          // Chance de criar power-up quando inimigo é destruído
          // Ajustar probabilidade baseada no tipo de inimigo
          double powerUpChance = _enemies[i].type == EnemyType.fastAsteroid ? 0.15 : 0.08;

          // Aumentar ligeiramente a chance com o nível de dificuldade
          final int index = (_difficultyLevel - 1).clamp(0, 9).toInt();
          powerUpChance += index * 0.01; // Aumenta 1% por nível

          if (_random.nextDouble() < powerUpChance) {
            // Criar power-up na posição do inimigo destruído
            final powerUp = PowerUp(
              position: _enemies[i].position,
              direction: Offset(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1).normalized(),
              speed: 0.5, // Velocidade reduzida para dar tempo de pegar
              radius: 20,
              type: _getRandomPowerUpType(),
              isLevelUpBonus: false,
            );

            _powerUps.add(powerUp);
            _log('Power-up criado após destruir inimigo: ${powerUp.type}');
          }

          // Remover projétil e inimigo
          _projectiles.removeAt(j);
          hit = true;
          break;
        }
        }

      if (hit) {
        _enemies.removeAt(i);
        continue;
      }

      // Remover inimigos fora da tela
      if (!_isOnScreen(_enemies[i].position, buffer: 50)) {
        _enemies.removeAt(i);
      }
    }

    // Atualizar power-ups
    for (int i = _powerUps.length - 1; i >= 0; i--) {
      if (_cannon != null) {
        // Usar o método de atração
        _powerUps[i].updateAttraction(_cannon!.position, 8.0); // Velocidade de atração
      } else {
        _powerUps[i].update();
      }

      // Verificar colisão com o canhão
      if (_cannon != null && circleCollision(
          _cannon!.position, _cannon!.radius,
          _powerUps[i].position, _powerUps[i].radius)) {

        // Aplicar efeito do power-up
        _applyPowerUp(_powerUps[i].type);

        // Remover power-up
        _powerUps.removeAt(i);
        continue;
      }

      // Verificar colisão com projéteis
      bool hit = false;
      for (int j = _projectiles.length - 1; j >= 0; j--) {
        if (circleCollision(
            _projectiles[j].position, _projectiles[j].radius,
            _powerUps[i].position, _powerUps[i].radius)) {

          // Em vez de destruir, ativar a atração
          _powerUps[i].isAttracted = true;

          // Tocar um som de "ping"
          try {
            AudioManager().playSound('powerup_ping'); // Você precisará adicionar este som
          } catch (e) {
            debugPrint('Erro ao tocar som de ping: $e');
          }

          // Remover apenas o projétil
          _projectiles.removeAt(j);
          hit = true;
          break;
        }
      }

      // Remover power-ups fora da tela
      if (!_isOnScreen(_powerUps[i].position, buffer: 20)) {
        _powerUps.removeAt(i);
      }
    }

    // Atualizar explosões
    for (int i = _explosions.length - 1; i >= 0; i--) {
      _explosions[i].update();

      // Remover explosões terminadas
      if (_explosions[i].isDone) {
        _explosions.removeAt(i);
      }
    }
  }

  PowerUpType _getRandomPowerUpType() {
    // Probabilidades ajustadas para cada tipo de power-up
    final double rand = _random.nextDouble();

    // Se o jogador estiver com poucas vidas, aumentar chance de vida extra
    if (_lives <= 2 && rand < 0.35) {
      return PowerUpType.extraLife;
    }

    // Caso contrário, distribuição normal
    if (rand < 0.3) {
      return PowerUpType.tripleShot;
    } else if (rand < 0.6) {
      return PowerUpType.shield;
    } else if (rand < 0.85) {
      return PowerUpType.speedBoost;
    } else {
      return PowerUpType.extraLife;
    }
  }

  void _applyPowerUp(PowerUpType type) {
    if (_cannon == null) return;

    // Tocar som de power-up coletado
    try {
      AudioManager().playPowerUpSound();
    } catch (e) {
      _log('Erro ao tocar som de power-up: $e');
    }

    // Incrementar contador para este tipo
    _collectedPowerUps[type] = (_collectedPowerUps[type] ?? 0) + 1;

    _log('Aplicando power-up: $type (Total coletado: ${_collectedPowerUps[type]})');

    switch (type) {
      case PowerUpType.tripleShot:
        _cannon!.activatePowerUp(type, duration: const Duration(seconds: 10));
        break;
      case PowerUpType.shield:
        _cannon!.activatePowerUp(type, duration: const Duration(seconds: 8));
        // Som adicional para o escudo
        try {
          AudioManager().playShieldSound();
        } catch (e) {
          _log('Erro ao tocar som de escudo: $e');
        }
        break;
      case PowerUpType.speedBoost:
        _cannon!.activatePowerUp(type, duration: const Duration(seconds: 15));
        break;
      case PowerUpType.extraLife:
        _lives = min(_lives + 1, 5);
        break;
    }
  }

  PowerUpType _getLeastCollectedPowerUpType() {
    // Criar uma lista ordenada de tipos por quantidade coletada
    final sortedTypes = PowerUpType.values.toList()
      ..sort((a, b) => (_collectedPowerUps[a] ?? 0).compareTo(_collectedPowerUps[b] ?? 0));

    // Retornar o tipo menos coletado
    return sortedTypes.first;
  }

  // Verificar se um ponto está na tela
  bool _isOnScreen(Offset position, {double buffer = 0}) {
    return position.dx >= -buffer &&
        position.dx <= _screenSize.width + buffer &&
        position.dy >= -buffer &&
        position.dy <= _screenSize.height + buffer;
  }

  // Criar uma onda de inimigos
  void _spawnWave() {
    _log('Criando onda de inimigos: $_wave');

    // Tocar som de início de onda
    // AudioManager().playWaveStartSound();

    // Determinar o índice de dificuldade (0-9)
    final int index = (_difficultyLevel - 1).clamp(0, 9).toInt();

    // Base de inimigos por onda
    final baseCount = 5 + _wave * 2;

    // Aumentar o número com a dificuldade (até 50% mais inimigos no nível máximo)
    final difficultyMultiplier = 1.0 + (index * 0.05); // 1.0 -> 1.45
    final count = (baseCount * difficultyMultiplier).round();

    _log('Spawning $count inimigos na onda $_wave (dificuldade ${_difficultyLevel.toStringAsFixed(1)})');

    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (_gameState == GameState.playing) {
          _spawnEnemy();
        }
      });
    }
  }

  // Criar inimigo individual
  void _spawnEnemy() {
    if (!_isInitialized || _gameState != GameState.playing) return;

    final int index = (_difficultyLevel - 1).clamp(0, 9).toInt();

    final enemyType = _random.nextDouble() < _fastEnemyProbabilities[index]
        ? EnemyType.fastAsteroid
        : EnemyType.normalAsteroid;

    Offset position;
    final side = _random.nextInt(4);


    switch (side) {
      case 0: // Topo
        position = Offset(
          _random.nextDouble() * _screenSize.width,
          -50,
        );
        break;
      case 1: // Direita
        position = Offset(
          _screenSize.width + 50,
          _random.nextDouble() * _screenSize.height,
        );
        break;
      case 2: // Baixo
        position = Offset(
          _random.nextDouble() * _screenSize.width,
          _screenSize.height + 50,
        );
        break;
      case 3: // Esquerda
        position = Offset(
          -50,
          _random.nextDouble() * _screenSize.height,
        );
        break;
      default:
        position = const Offset(0, 0);
    }

    // Calcular direção para o centro
    final direction = (_cannon != null)
        ? (_cannon!.position - position).normalized()
        : Offset(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1).normalized();

    double speedMultiplier = _speedMultipliers[index];
    double speed = enemyType == EnemyType.fastAsteroid
        ? 3.0 + (_wave * 0.2) * speedMultiplier
        : 2.0 + (_wave * 0.1) * speedMultiplier;

    if (enemyType == EnemyType.fastAsteroid) {
      speed = 2.0 + (_wave * 0.2) * speedMultiplier;
    } else {
      speed = 1.0 + (_wave * 0.1) * speedMultiplier;
    }

    final enemy = Enemy(
      position: position,
      direction: direction,
      speed: speed,
      radius: enemyType == EnemyType.fastAsteroid ? 15 : 25,
      type: enemyType,
      rotation: _random.nextDouble() * 2 * pi,
      pointValue: enemyType == EnemyType.fastAsteroid ? 150 : 100,
    );

    _enemies.add(enemy);

    if (_random.nextDouble() < 0.05) {
      _log('Inimigo criado - Tipo: $enemyType, Velocidade: $speed (Nível ${_difficultyLevel.toInt()})');
    }
  }

  // Obter o threshold atual com base no nível de dificuldade
  int getCurrentDifficultyThreshold() {
    final level = _difficultyLevel.toInt();
    if (level <= 1) return 0;
    if (level > _difficultyThresholds.length) return _difficultyThresholds.last;
    return _difficultyThresholds[level - 1];
  }

// Obter o próximo threshold
  int getNextDifficultyThreshold() {
    final level = _difficultyLevel.toInt();
    if (level >= _difficultyThresholds.length) return _difficultyThresholds.last;
    return _difficultyThresholds[level];
  }

  // Adicionar explosão
  void _addExplosion(Offset position) {
    final explosion = Explosion(position: position);
    _explosions.add(explosion);
  }

  // Atirar projétil
  void shootProjectile(Offset targetPosition) {
    if (_gameState != GameState.playing || !_isInitialized || _cannon == null) return;

    // Tocar som de tiro
    AudioManager().playLaserSound();

    // Calcular direção
    final direction = (targetPosition - _cannon!.position).normalized();

    // Verificar se há poder de tiro triplo ativo
    if (_cannon!.hasPowerUp(PowerUpType.tripleShot)) {
      // Atirar 3 projéteis em leque
      for (int i = -1; i <= 1; i++) {
        final angle = i * 0.2;
        final rotatedDirection = Offset(
          direction.dx * cos(angle) - direction.dy * sin(angle),
          direction.dx * sin(angle) + direction.dy * cos(angle),
        );

        _addProjectile(rotatedDirection);
      }
    } else {
      // Tiro normal
      _addProjectile(direction);
    }
  }

  // Adicionar projétil
  void _addProjectile(Offset direction) {
    if (_cannon == null) return;

    // Ajustar velocidade se tiver boost de velocidade
    double speed = 10.0;
    if (_cannon!.hasPowerUp(PowerUpType.speedBoost)) {
      speed = 15.0;
    }

    final projectile = Projectile(
      position: _cannon!.position,
      direction: direction,
      speed: speed,
      radius: 5,
    );

    _projectiles.add(projectile);
  }

  // Detectar colisão entre círculos
  bool circleCollision(Offset center1, double radius1, Offset center2, double radius2) {
    final dx = center1.dx - center2.dx;
    final dy = center1.dy - center2.dy;
    final distance = sqrt(dx * dx + dy * dy);
    return distance < (radius1 + radius2);
  }

  // Limpar recursos ao fechar
  @override
  void dispose() {
    _stopTimers();
    AudioManager().dispose();
    super.dispose();
  }

  // Método apenas para testes - você pode remover em produção
  void testStateTransition() {
    _log('======= TESTE DE TRANSIÇÃO DE ESTADOS =======');

    _log('Estado atual: $_gameState');

    // Teste de pausa
    if (_gameState == GameState.playing) {
      _log('Tentando pausar...');
      _gameState = GameState.paused;
      _log('Novo estado: $_gameState');

      // Teste de retomada
      _log('Tentando retomar...');
      _gameState = GameState.playing;
      _log('Novo estado: $_gameState');
    } else if (_gameState == GameState.paused) {
      _log('Tentando retomar...');
      _gameState = GameState.playing;
      _log('Novo estado: $_gameState');
    } else {
      _log('Estado atual não permite pausar/retomar');
    }

    _log('====== FIM DO TESTE ======');

    notifyListeners();
  }

  void cheatIncreaseDifficulty() {
    if (_gameState != GameState.playing) return;

    // Aumentar a pontuação para o próximo nível
    final int currentLevel = _difficultyLevel.toInt();
    if (currentLevel < _difficultyThresholds.length - 1) {
      _score = _difficultyThresholds[currentLevel];
      _updateDifficultyLevel();
      _log('Cheat ativado: Dificuldade aumentada para nível ${_difficultyLevel.toInt()}');
    }
  }
}

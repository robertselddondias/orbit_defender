import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';

class GameServicesManager {
  static final GameServicesManager _instance = GameServicesManager._internal();

  factory GameServicesManager() {
    return _instance;
  }

  GameServicesManager._internal();

  bool _isInitialized = false;
  bool _isSignedIn = false;

  // Leaderboard IDs
  static const String _androidLeaderboardId = 'CgkIqtiUiuQYEAIQAQ';
  static const String _iosLeaderboardId = 'ORBIT_DEFENDER_LEADERBOARD_MAIOR';

  // Achievement IDs
  static const Map<String, Map<String, String>> _achievementIds = {
    'wave_5': {
      'android': 'CgkIqtiUiuQYEAIQAg',
      'ios': 'ORBIT_DEFENDER_ACHIEVEMENT_ID_WAVE_5',
    },
    'wave_10': {
      'android': 'CgkIqtiUiuQYEAIQAw',
      'ios': 'ORBIT_DEFENDER_ACHIEVEMENT_ID_WAVE_10',
    },
    'wave_20': {
      'android': 'YOUR_ANDROID_ACHIEVEMENT_ID_WAVE_20',
      'ios': 'ORBIT_DEFENDER_ACHIEVEMENT_ID_WAVE_20',
    },
    'score_10000': {
      'android': 'YOUR_ANDROID_ACHIEVEMENT_ID_SCORE_10000',
      'ios': 'ORBIT_DEFENDER_ACHIEVEMENT_ID_SCORE_10000',
    },
  };

  /// Inicializa o serviço de jogos (Game Center/Play Games)
  Future<bool> initialize() async {
    if (_isInitialized) return _isSignedIn;

    try {
      debugPrint('Iniciando serviços de jogos...');

      await GamesServices.signIn();
      _isSignedIn = true;
      _isInitialized = true;

      debugPrint('Serviços de jogos inicializados com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro ao inicializar serviços de jogos: $e');
      _isInitialized = true; // Marcamos como inicializado mesmo com erro para não tentar repetidamente
      _isSignedIn = false;
      return false;
    }
  }

  /// Submete a pontuação ao leaderboard
  Future<bool> submitScore(int score) async {
    if (Platform.isIOS) {
      debugPrint('Enviando pontuação no iOS: $score');
      debugPrint('ID do Leaderboard iOS: $_iosLeaderboardId');
    }

    // Evite tentativas de inicialização repetidas
    if (!_isInitialized) {
      _isInitialized = await initialize();
      if (!_isInitialized) {
        debugPrint('Falha ao inicializar Game Services');
        return false;
      }
    }

    if (!_isSignedIn) {
      // Para iOS, o sign-in funciona diferente do Android
      if (Platform.isIOS) {
        try {
          // Tentativa específica para iOS
          await GamesServices.signIn();
          _isSignedIn = true;
        } catch (e) {
          debugPrint('Erro ao fazer login no Game Center: $e');
          return false;
        }
      } else {
        debugPrint('Usuário não está logado nos serviços de jogos');
        return false;
      }
    }

    try {
      debugPrint('Tentando enviar pontuação: $score');

      // Certifique-se de que os IDs estão definidos e não são nulos/vazios
      if (Platform.isIOS && _iosLeaderboardId.isEmpty) {
        debugPrint('ID do leaderboard iOS não está configurado corretamente');
        return false;
      } else if (Platform.isAndroid && _androidLeaderboardId.isEmpty) {
        debugPrint('ID do leaderboard Android não está configurado corretamente');
        return false;
      }

      // Para iOS, as vezes funciona melhor usar apenas o ID correspondente à plataforma
      if (Platform.isIOS) {
        await GamesServices.submitScore(
          score: Score(
            iOSLeaderboardID: _iosLeaderboardId,
            value: score,
          ),
        );
      } else {
        await GamesServices.submitScore(
          score: Score(
            androidLeaderboardID: _androidLeaderboardId,
            iOSLeaderboardID: _iosLeaderboardId,
            value: score,
          ),
        );
      }

      debugPrint('Pontuação $score enviada com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro detalhado ao enviar pontuação: $e');
      if (e is PlatformException) {
        debugPrint('Código do erro: ${e.code}');
        debugPrint('Mensagem do erro: ${e.message}');
        debugPrint('Detalhes do erro: ${e.details}');
      }
      return false;
    }
  }

  /// Mostra a tela de leaderboard
  Future<void> showLeaderboard() async {
    try {
      // Forçar nova inicialização para garantir que estamos autenticados
      final bool initialized = await initialize();

      if (!initialized || !_isSignedIn) {
        debugPrint('Não foi possível mostrar leaderboard: usuário não está autenticado');
        return;
      }

      debugPrint('Tentando mostrar leaderboard com ID Android: $_androidLeaderboardId');

      // No Android, às vezes é necessário especificar apenas o ID da plataforma atual
      if (Platform.isAndroid) {
        await GamesServices.showLeaderboards(
          androidLeaderboardID: _androidLeaderboardId,
        );
      } else {
        await GamesServices.showLeaderboards(
          androidLeaderboardID: _androidLeaderboardId,
          iOSLeaderboardID: _iosLeaderboardId,
        );
      }

      debugPrint('Leaderboard exibido com sucesso');
    } catch (e) {
      debugPrint('Erro detalhado ao mostrar leaderboard: $e');

      // Tentar mostrar apenas o leaderboard principal se falhar
      if (Platform.isAndroid) {
        try {
          await GamesServices.showLeaderboards();
          debugPrint('Leaderboard exibido usando método alternativo');
        } catch (e2) {
          debugPrint('Falha total ao exibir leaderboard: $e2');
        }
      }
    }
  }

  /// Desbloqueia uma conquista (achievement)
  Future<bool> unlockAchievement(String achievementId) async {
    if (!_isInitialized) await initialize();
    if (!_isSignedIn) return false;

    try {
      final String androidId = _achievementIds[achievementId]?['android'] ?? '';
      final String iosId = _achievementIds[achievementId]?['ios'] ?? '';

      if (androidId.isEmpty || iosId.isEmpty) {
        debugPrint('ID de conquista inválido: $achievementId');
        return false;
      }

      await GamesServices.unlock(
        achievement: Achievement(
          androidID: androidId,
          iOSID: iosId,
          percentComplete: 100,
        ),
      );

      debugPrint('Conquista $achievementId desbloqueada com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro ao desbloquear conquista: $e');
      return false;
    }
  }

  /// Mostra a tela de conquistas (achievements)
  Future<void> showAchievements() async {
    if (!_isInitialized) await initialize();
    if (!_isSignedIn) return;

    try {
      await GamesServices.showAchievements();
    } catch (e) {
      debugPrint('Erro ao mostrar conquistas: $e');
    }
  }

  /// Verifica e desbloqueia conquistas com base na pontuação e onda
  Future<void> checkAndUnlockAchievements(int score, int wave) async {
    if (!_isInitialized) await initialize();
    if (!_isSignedIn) return;

    // Conquistas baseadas em ondas
    if (wave >= 5) {
      await unlockAchievement('wave_5');
    }

    if (wave >= 10) {
      await unlockAchievement('wave_10');
    }

    if (wave >= 20) {
      await unlockAchievement('wave_20');
    }

    // Conquistas baseadas em pontuação
    if (score >= 10000) {
      await unlockAchievement('score_10000');
    }
  }

  /// Processa a pontuação no fim do jogo (submete ao online e verifica conquistas)
  Future<void> processGameOver(int score, int wave) async {
    if (!_isInitialized) await initialize();

    // Mesmo se não estiver logado, tentamos inicializar novamente
    if (!_isSignedIn) {
      await initialize();
    }

    if (_isSignedIn) {
      // Enviar pontuação
      await submitScore(score);

      // Verificar conquistas
      await checkAndUnlockAchievements(score, wave);
    }
  }

  /// Retorna o status de login
  bool get isSignedIn => _isSignedIn;
}

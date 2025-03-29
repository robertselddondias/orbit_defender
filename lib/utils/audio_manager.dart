import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  // Singleton
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Players
  AudioPlayer? _musicPlayer;
  final Map<String, AudioPlayer> _soundPlayers = {};

  // Estado
  bool _initialized = false;
  bool _musicEnabled = true;
  bool _soundEnabled = true;
  String? _currentMusic;
  bool _isPaused = false;

  // Volume
  double _musicVolume = 0.5;
  double _soundVolume = 0.8;

  // Inicialização
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _musicPlayer = AudioPlayer();
      // Configurar como loop por padrão
      await _musicPlayer?.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer?.setVolume(_musicVolume);

      _initialized = true;
      debugPrint('AudioManager: inicializado com sucesso');
    } catch (e) {
      debugPrint('AudioManager: erro na inicialização: $e');
      _initialized = false;
    }
  }

  // Verificação de inicialização
  void _checkInitialization() {
    if (!_initialized) {
      debugPrint('AudioManager: não inicializado. Inicializando agora...');
      initialize();
    }
  }

  // Tocar música
  Future<void> playMusic(String assetPath) async {
    _checkInitialization();

    if (!_musicEnabled || _musicPlayer == null) return;

    try {
      // Se for a mesma música e estiver pausada, apenas retome
      if (_currentMusic == assetPath && _isPaused) {
        return resumeMusic();
      }

      // Parar música atual se houver
      await stopMusic();

      // Iniciar nova música
      _currentMusic = assetPath;
      _isPaused = false;

      // Carregar e tocar o áudio
      await _musicPlayer?.play(AssetSource('sounds/$assetPath'));
      await _musicPlayer?.setVolume(_musicVolume);

      debugPrint('AudioManager: música iniciada: $assetPath');
    } catch (e) {
      debugPrint('AudioManager: erro ao tocar música: $e');
    }
  }

  // Parar música
  Future<void> stopMusic() async {
    if (_musicPlayer == null) return;

    try {
      await _musicPlayer?.stop();
      _currentMusic = null;
      _isPaused = false;
      debugPrint('AudioManager: música parada');
    } catch (e) {
      debugPrint('AudioManager: erro ao parar música: $e');
    }
  }

  // Pausar música
  Future<void> pauseMusic() async {
    if (_musicPlayer == null || _currentMusic == null) return;

    try {
      await _musicPlayer?.pause();
      _isPaused = true;
      debugPrint('AudioManager: música pausada');
    } catch (e) {
      debugPrint('AudioManager: erro ao pausar música: $e');
    }
  }

  // Retomar música
  Future<void> resumeMusic() async {
    if (_musicPlayer == null || _currentMusic == null || !_isPaused) return;

    try {
      await _musicPlayer?.resume();
      _isPaused = false;
      debugPrint('AudioManager: música retomada');
    } catch (e) {
      debugPrint('AudioManager: erro ao retomar música: $e');
    }
  }

  // Verificar se a música está tocando
  bool isMusicPlaying() {
    return _musicPlayer?.state == PlayerState.playing;
  }

  // Tocar efeito sonoro
  Future<void> playSound(String soundName, {double? volume}) async {
    _checkInitialization();

    if (!_soundEnabled) return;

    try {
      // Criar novo player ou reutilizar existente
      final player = _soundPlayers[soundName] ?? AudioPlayer();
      _soundPlayers[soundName] = player;

      // Configurar o som
      await player.setReleaseMode(ReleaseMode.release); // Liberar após tocar
      await player.setVolume(volume ?? _soundVolume);

      // Tocar o som
      await player.play(AssetSource('sounds/$soundName.mp3'));

      debugPrint('AudioManager: som reproduzido: $soundName');
    } catch (e) {
      debugPrint('AudioManager: erro ao tocar som $soundName: $e');
    }
  }

  // Sons específicos do jogo
  Future<void> playLaserSound() async {
    await playSound('laser', volume: 0.4);
  }

  Future<void> playSmallExplosionSound() async {
    await playSound('explosion_small', volume: 0.5);
  }

  Future<void> playPlayerHitSound() async {
    await playSound('player_hit', volume: 0.6);
  }

  Future<void> playShieldSound() async {
    await playSound('shield', volume: 0.5);
  }

  Future<void> playPowerUpSound() async {
    await playSound('powerup', volume: 0.7);
  }

  Future<void> playWaveStartSound() async {
    await playSound('wave_start', volume: 0.6);
  }

  Future<void> playGameOverSound() async {
    await playSound('game_over', volume: 1.0);
  }

  Future<void> playSuperShotSound() async {
    await playSound('super_shot', volume: 0.7);
  }

  Future<void> playAreaBombSound() async {
    await playSound('area_bomb', volume: 0.8);
  }

  Future<void> playTimeWarpSound() async {
    await playSound('time_warp', volume: 0.6);
  }

  Future<void> playMagnetFieldSound() async {
    await playSound('magnet_field', volume: 0.6);
  }

  Future<void> playRapidFireSound() async {
    await playSound('rapid_fire', volume: 0.5);
  }

  Future<void> playAbilityReadySound() async {
    await playSound('ability_ready', volume: 0.4);
  }

  Future<void> preloadSound(String soundFileName) async {
    _checkInitialization();

    if (!_soundEnabled) return;

    try {
      // Criar um player temporário apenas para carregar o som
      final player = AudioPlayer();

      // Configurar o som
      await player.setReleaseMode(ReleaseMode.release);

      // Apenas carregar o som, não reproduzi-lo
      await player.setSource(AssetSource('sounds/$soundFileName'));

      // Armazenar o player para uso posterior
      String soundName = soundFileName.replaceAll('.mp3', '').replaceAll('.wav', '');
      _soundPlayers[soundName] = player;

      debugPrint('AudioManager: som pré-carregado: $soundName');
    } catch (e) {
      debugPrint('AudioManager: erro ao pré-carregar som $soundFileName: $e');
    }
  }

  // Parar todos os sons
  Future<void> stopAllSounds() async {
    try {
      for (final player in _soundPlayers.values) {
        await player.stop();
      }
      debugPrint('AudioManager: todos os sons parados');
    } catch (e) {
      debugPrint('AudioManager: erro ao parar todos os sons: $e');
    }
  }

  // Controle de volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    if (_musicPlayer != null) {
      await _musicPlayer!.setVolume(_musicVolume);
    }
  }

  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
  }

  // Habilitar/desabilitar
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!_musicEnabled) {
      stopMusic();
    } else if (_currentMusic != null) {
      playMusic(_currentMusic!);
    }
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!_soundEnabled) {
      stopAllSounds();
    }
  }

  // Limpeza de recursos
  Future<void> dispose() async {
    try {
      await stopMusic();
      await stopAllSounds();

      await _musicPlayer?.dispose();
      for (final player in _soundPlayers.values) {
        await player.dispose();
      }

      _soundPlayers.clear();
      _initialized = false;
      _currentMusic = null;
      _isPaused = false;

      debugPrint('AudioManager: recursos liberados');
    } catch (e) {
      debugPrint('AudioManager: erro ao liberar recursos: $e');
    }
  }
}

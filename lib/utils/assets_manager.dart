import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Classe para gerenciar o carregamento e cache de assets do jogo
class AssetsManager {
  // Singleton
  static final AssetsManager _instance = AssetsManager._internal();
  factory AssetsManager() => _instance;
  AssetsManager._internal();

  // Caches para SVGs
  final Map<String, String> _svgCache = {};

  // Prefixo dos caminhos de assets
  static const String _imagePath = 'assets/images/';
  static const String _soundPath = 'assets/sounds/';

  // Lista de assets SVG para pré-carregar
  final List<String> _svgAssets = [
    'stars_bg.svg',
    'cannon.svg',
    'asteroid.svg',
    'projectile.svg',
    'explosion.svg',
    'power_ups.svg',
  ];

  // Lista de efeitos sonoros para pré-carregar
  final List<String> _soundAssets = [
    'laser_shot.mp3',
    'explosion_small.mp3',
    'explosion_large.mp3',
    'powerup_collect.mp3',
    'shield_activate.mp3',
    'player_hit.wav',
    'game_over.wav',
    'start.wav',
  ];

  /// Inicializa e pré-carrega todos os assets necessários
  Future<void> preloadAssets() async {
    // Simplificação para evitar problemas com precachePicture
    // Apenas carregamos o conteúdo dos SVGs na memória
    for (final asset in _svgAssets) {
      try {
        final String assetPath = _imagePath + asset;
        // Apenas carregar a string do SVG para o cache
        final String svgString = await rootBundle.loadString(assetPath);
        _svgCache[asset] = svgString;
        debugPrint('SVG carregado com sucesso: $asset');
      } catch (e) {
        debugPrint('Erro ao carregar SVG $asset: $e');
      }
    }

    // Aqui você pode adicionar pré-carregamento de sons com audioplayers
  }

  /// Retorna o caminho para um asset de imagem
  String getImagePath(String asset) => _imagePath + asset;

  /// Retorna o caminho para um asset de som
  String getSoundPath(String asset) => _soundPath + asset;

  /// Verifica se uma imagem está no cache
  bool isSvgCached(String asset) => _svgCache.containsKey(asset);

  /// Obtém um SVG do cache como string (se estiver disponível)
  String? getCachedSvgString(String asset) => _svgCache[asset];
}

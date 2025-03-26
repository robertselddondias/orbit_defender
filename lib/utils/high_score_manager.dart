import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:orbit_defender/entities/high_score.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighScoreManager {
  static const String _highScoresKey = 'high_scores';
  static const int _maxScores = 10; // Máximo de 10 pontuações

  // Carregar pontuações
  static Future<List<HighScore>> getHighScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_highScoresKey);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => HighScore.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erro ao carregar pontuações: $e');
      return [];
    }
  }

  // Salvar pontuações
  static Future<void> saveHighScores(List<HighScore> highScores) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
      highScores.map((score) => score.toJson()).toList();
      await prefs.setString(_highScoresKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erro ao salvar pontuações: $e');
    }
  }

  // Adicionar nova pontuação
  static Future<bool> addScore(int score, int wave) async {
    try {
      final List<HighScore> highScores = await getHighScores();

      // Criar nova entrada
      final newScore = HighScore(
        score: score,
        date: DateTime.now(),
        wave: wave,
      );

      // Verificar se é uma pontuação alta o suficiente para entrar no ranking
      if (highScores.length < _maxScores || score > highScores.last.score) {
        // Adicionar nova pontuação
        highScores.add(newScore);

        // Ordenar por pontuação (decrescente)
        highScores.sort((a, b) => b.score.compareTo(a.score));

        // Manter apenas as top _maxScores
        if (highScores.length > _maxScores) {
          highScores.removeRange(_maxScores, highScores.length);
        }

        // Salvar
        await saveHighScores(highScores);
        return true; // Nova pontuação adicionada ao ranking
      }

      return false; // Não foi alta o suficiente para o ranking
    } catch (e) {
      debugPrint('Erro ao adicionar pontuação: $e');
      return false;
    }
  }

  // Limpar todas as pontuações (para testes)
  static Future<void> clearAllScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_highScoresKey);
    } catch (e) {
      debugPrint('Erro ao limpar pontuações: $e');
    }
  }
}

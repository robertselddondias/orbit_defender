
class HighScore {
  final int score;
  final DateTime date;
  final int wave;

  HighScore({
    required this.score,
    required this.date,
    required this.wave,
  });

  // Converter para Map para armazenar no SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'date': date.toIso8601String(),
      'wave': wave,
    };
  }

  // Criar a partir de Map (ao ler do SharedPreferences)
  factory HighScore.fromJson(Map<String, dynamic> json) {
    return HighScore(
      score: json['score'] as int,
      date: DateTime.parse(json['date'] as String),
      wave: json['wave'] as int,
    );
  }

  // Formatação da data amigável
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

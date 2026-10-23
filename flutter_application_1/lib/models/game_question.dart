enum QuestionDifficulty { mudah, menengah, sulit, sangatSulit }

class GameQuestion {
  final String id;
  final String hint;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? relatedRestaurantId;
  final QuestionDifficulty difficulty; // Untuk filter level
  final String? imageUrl; // Foto otentik hidangan untuk soal tebak visual
  final String? category; // Kategori soal: Tebak Foto, Resep, Mitos/Fakta, dll.

  const GameQuestion({
    required this.id,
    required this.hint,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.relatedRestaurantId,
    this.difficulty = QuestionDifficulty.mudah,
    this.imageUrl,
    this.category,
  });
}


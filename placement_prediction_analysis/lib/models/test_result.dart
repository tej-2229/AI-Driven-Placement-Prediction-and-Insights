class TestResult {
  final String id;
  final String companyName;
  final double overallPercentage;
  final int totalQuestions;
  final int totalScore;
  final List<CategoryResult> categories;

  TestResult({
    required this.id,
    required this.companyName,
    required this.overallPercentage,
    required this.totalQuestions,
    required this.totalScore,
    required this.categories,
  });

  factory TestResult.fromMap(String id, Map<String, dynamic> map) {
    return TestResult(
      id: id,
      companyName: map['companyName'] ?? 'Unknown Company',
      overallPercentage: (map['overallPercentage'] ?? 0).toDouble(),
      totalQuestions: map['totalQuestions'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      categories: (map['categories'] as List<dynamic>? ?? [])
          .map((e) => CategoryResult.fromMap(e))
          .toList(),
    );
  }

  // Helper methods to get specific category scores
  int get quantScore => categories
      .firstWhere(
        (cat) => cat.categoryName.toLowerCase().contains('quantitative'),
        orElse: () => CategoryResult.empty(),
      )
      .score;

  int get verbalScore => categories
      .firstWhere(
        (cat) => cat.categoryName.toLowerCase().contains('verbal'),
        orElse: () => CategoryResult.empty(),
      )
      .score;

  int get technicalScore => categories
      .firstWhere(
        (cat) => cat.categoryName.toLowerCase().contains('technical'),
        orElse: () => CategoryResult.empty(),
      )
      .score;
}

class CategoryResult {
  final String categoryName;
  final int score;
  final double scorePercentage;
  final int totalQuestions;

  CategoryResult({
    required this.categoryName,
    required this.score,
    required this.scorePercentage,
    required this.totalQuestions,
  });

  factory CategoryResult.fromMap(Map<String, dynamic> map) {
    return CategoryResult(
      categoryName: map['categoryName'] ?? 'Unknown Category',
      score: map['score'] ?? 0,
      scorePercentage: (map['scorePercentage'] ?? 0).toDouble(),
      totalQuestions: map['totalQuestions'] ?? 0,
    );
  }

  static CategoryResult empty() => CategoryResult(
        categoryName: '',
        score: 0,
        scorePercentage: 0,
        totalQuestions: 0,
      );
}
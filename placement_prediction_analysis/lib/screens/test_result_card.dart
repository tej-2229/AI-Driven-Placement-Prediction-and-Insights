import 'package:flutter/material.dart';
import 'package:placement_prediction_analysis/models/test_result.dart';

class TestResultCard extends StatelessWidget {
  final TestResult result;

  const TestResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.companyName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Overall: ${result.overallPercentage}%'),
                Text('Score: ${result.totalScore}/${result.totalQuestions}'),
              ],
            ),
            const SizedBox(height: 16),
            ...result.categories.map((category) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category.categoryName),
                      Text(
                          '${category.score}/${category.totalQuestions} (${category.scorePercentage}%)'),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
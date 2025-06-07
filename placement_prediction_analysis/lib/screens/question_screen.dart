import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AptitudeTestScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const AptitudeTestScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  _AptitudeTestScreenState createState() => _AptitudeTestScreenState();
}

class _AptitudeTestScreenState extends State<AptitudeTestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  String? selectedOption;
  int timerSeconds = 0;
  late Timer timer;
  int correctAnswers = 0;
  bool isLoading = true;
  bool testCompleted = false;
  bool quizStarted = false;
  bool instructionsRead = false;
  int currentCategoryIndex = 0;
  Map<String, int> categoryScores = {}; // Track scores for each category
  Map<String, List<Map<String, dynamic>>> categoryQuestions =
      {}; // Questions by category
  Map<String, int> categoryQuestionIndices =
      {}; // Current question index per category
  final bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(widget.companyId)
          .collection('categories')
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('No categories found');
      }

      setState(() {
        categories = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });

      // Initialize data structures for each category
      for (var category in categories) {
        categoryScores[category['id']] = 0;
        categoryQuestionIndices[category['id']] = 0;
      }

      // Load questions for the first category
      await _loadCategoryQuestions(categories[0]['id']);
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load categories. Please try again.')),
        );
      }
    }
  }

  Future<void> _loadCategoryQuestions(String categoryId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final questionsSnapshot = await _firestore
          .collection('companies')
          .doc(widget.companyId)
          .collection('categories')
          .doc(categoryId)
          .collection('questions')
          .get();

      final categoryQuestionsList = questionsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'question': doc['question'],
          'options': List<String>.from(doc['options']),
          'answer': doc['answer'],
          'categoryId': categoryId,
        };
      }).toList();

      setState(() {
        categoryQuestions[categoryId] = categoryQuestionsList;
        questions = categoryQuestionsList;
        currentQuestionIndex = 0;
        selectedOption = null;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching questions: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load questions. Please try again.')),
        );
      }
    }
  }

  String formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void handleOptionSelection(String option) {
    setState(() {
      selectedOption = option;
    });
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        timerSeconds++;
      });
    });
  }

  void nextQuestion() {
    final currentCategoryId = categories[currentCategoryIndex]['id'];
    final currentCategoryQuestions = categoryQuestions[currentCategoryId]!;

    // Update score if answer is correct
    if (selectedOption ==
        currentCategoryQuestions[currentQuestionIndex]['answer']) {
      categoryScores[currentCategoryId] =
          (categoryScores[currentCategoryId] ?? 0) + 1;
    }

    setState(() {
      // Check if we've reached the end of current category questions
      if (currentQuestionIndex < currentCategoryQuestions.length - 1) {
        currentQuestionIndex++;
        selectedOption = null;
      } else {
        // Move to next category or complete test
        _moveToNextCategory();
      }
    });
  }

  void _moveToNextCategory() {
    setState(() {
      selectedOption = null;

      // Check if there are more categories
      if (currentCategoryIndex < categories.length - 1) {
        currentCategoryIndex++;
        _loadCategoryQuestions(categories[currentCategoryIndex]['id']);
      } else {
        // All categories completed
        _completeTest();
      }
    });
  }

  void startQuiz() {
    if (instructionsRead) {
      setState(() {
        quizStarted = true;
        startTimer();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please confirm you have read the instructions')),
      );
    }
  }

  Future<void> _completeTest({bool savePartial = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Calculate total score
      int totalScore = 0;
      int totalQuestions = 0;

      // Prepare category results
      List<Map<String, dynamic>> categoryResults = [];

      for (var i = 0;
          i <= (savePartial ? currentCategoryIndex : categories.length - 1);
          i++) {
        final category = categories[i];
        final categoryId = category['id'];
        final questions = categoryQuestions[categoryId] ?? [];
        final score = categoryScores[categoryId] ?? 0;

        // For partial save, only count completed questions in current category
        final questionsCount = savePartial && i == currentCategoryIndex
            ? currentQuestionIndex + 1
            : questions.length;

        totalScore += score;
        totalQuestions += questionsCount;

        categoryResults.add({
          'categoryId': categoryId,
          'categoryName': category['name'],
          'score': score,
          'totalQuestions': questionsCount,
          'scorePercentage':
              questionsCount > 0 ? (score / questionsCount) * 100 : 0,
          'completed': savePartial && i == currentCategoryIndex ? false : true,
        });
      }

      final overallPercentage =
          totalQuestions > 0 ? (totalScore / totalQuestions) * 100 : 0;

      // Save results to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('testResults')
          .add({
        'companyId': widget.companyId,
        'companyName': widget.companyName,
        'categories': categoryResults,
        'totalScore': totalScore,
        'totalQuestions': totalQuestions,
        'overallPercentage': overallPercentage,
        'timestamp': FieldValue.serverTimestamp(),
        'timeTaken': timerSeconds,
        'completed': !savePartial,
      });

      // Update progress for each completed category
      for (var i = 0;
          i <= (savePartial ? currentCategoryIndex : categories.length - 1);
          i++) {
        final category = categories[i];
        final categoryId = category['id'];

        // Only update progress for fully completed categories
        if (!savePartial || i < currentCategoryIndex) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('categoryProgress')
              .doc(categoryId)
              .set({
            'highestScore':
                FieldValue.increment(categoryScores[categoryId] ?? 0),
            'attempts': FieldValue.increment(1),
            'lastAttempt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      if (!savePartial) {
        setState(() {
          testCompleted = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Test completed! Total Score: $totalScore/$totalQuestions'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving test results: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save test results. Please try again.')),
        );
      }
    }
  }

  Widget _buildInstructionsScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.school,
                  size: 60,
                ),
                SizedBox(height: 10),
                Text(
                  'Placement Preparation Quiz - ${widget.companyName}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  _buildInstructionItem(
                    icon: Icons.timer,
                    text: 'You have 15 minutes to complete the quiz',
                  ),
                  _buildInstructionItem(
                    icon: Icons.help_outline,
                    text: 'Answer all questions to the best of your ability',
                  ),
                  _buildInstructionItem(
                    icon: Icons.category,
                    text:
                        'You must complete all ${categories.length} categories: ${categories.map((c) => c['name']).join(', ')}',
                  ),
                  _buildInstructionItem(
                    icon: Icons.navigate_next,
                    text: 'Use the navigation panel to move between questions',
                  ),
                  _buildInstructionItem(
                    icon: Icons.check_circle,
                    text: 'Select only one answer per question',
                  ),
                  _buildInstructionItem(
                    icon: Icons.warning,
                    text: 'Once submitted, answers cannot be changed',
                  ),
                  _buildInstructionItem(
                    icon: Icons.block,
                    text: 'You cannot go back to previous categories',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Checkbox(
                    value: instructionsRead,
                    onChanged: (value) {
                      setState(() {
                        instructionsRead = value ?? false;
                      });
                    },
                    activeColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'I have read and understood the instructions given above',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: startQuiz,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8BB2B2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5),
              child: Text(
                'Start Quiz Now',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    final currentCategory = categories[currentCategoryIndex];
    final currentQuestion = questions[currentQuestionIndex];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Container: Question and Options
        Expanded(
          flex: 3,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timer and Total Questions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${formatTime(timerSeconds)}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Category: ${currentCategory['name']}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Question ${currentQuestionIndex + 1}/${questions.length}',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Question Number
                Text(
                  'Question ${currentQuestionIndex + 1}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // Question Text
                Text(
                  currentQuestion['question'],
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 20),

                // Options
                for (var option in currentQuestion['options'])
                  OptionButton(
                    text: option,
                    isSelected: selectedOption == option,
                    onTap: () => handleOptionSelection(option),
                  ),
                SizedBox(height: 20),

                // Next Question Button
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: selectedOption == null ? null : nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8BB2B2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      currentQuestionIndex == questions.length - 1 &&
                              currentCategoryIndex == categories.length - 1
                          ? 'Submit Test'
                          : currentQuestionIndex == questions.length - 1
                              ? 'Next Category'
                              : 'Next Question',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 16),

        // Right Container: Question Navigation Grid
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Categories Progress
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Categories Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    for (var category in categories)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: currentCategoryIndex ==
                                    categories.indexOf(category)
                                ? Colors.green
                                : categories.indexOf(category) <
                                        currentCategoryIndex
                                    ? Colors.blue
                                    : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${category['name']}: ${currentCategoryIndex > categories.indexOf(category) ? 'Completed' : currentCategoryIndex == categories.indexOf(category) ? 'In Progress' : 'Pending'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: currentCategoryIndex ==
                                      categories.indexOf(category)
                                  ? Colors.green
                                  : categories.indexOf(category) <
                                          currentCategoryIndex
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Current Category Progress
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Current Category Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Correct: ${categoryScores[categories[currentCategoryIndex]['id']] ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Incorrect: ${currentQuestionIndex - (categoryScores[categories[currentCategoryIndex]['id']] ?? 0)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Question Navigation Container
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Question Navigator',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    QuestionNavigation(
                      totalQuestions: questions.length,
                      currentQuestionIndex: currentQuestionIndex,
                      onTap: (index) {
                        if (index <= currentQuestionIndex) {
                          setState(() {
                            currentQuestionIndex = index;
                            selectedOption = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    // Calculate total score
    int totalScore = 0;
    int totalQuestions = 0;

    for (var category in categories) {
      final categoryId = category['id'];
      final questions = categoryQuestions[categoryId]!;
      totalScore += categoryScores[categoryId] ?? 0;
      totalQuestions += questions.length;
    }

    final overallPercentage = (totalScore / totalQuestions) * 100;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration, size: 80, color: Colors.amber),
          SizedBox(height: 20),
          Text(
            'Quiz Completed!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'Your Overall Score',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  '$totalScore out of $totalQuestions',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  '(${overallPercentage.toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  'Time Taken: ${formatTime(timerSeconds)}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Category-wise results
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Column(
              children: [
                Text(
                  'Category-wise Results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                for (var category in categories)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category['name'],
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${categoryScores[category['id']] ?? 0}/${categoryQuestions[category['id']]?.length ?? 0}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8BB2B2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Back to Companies',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (testCompleted) {
      return Scaffold(
        body: _buildResultsScreen(),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !quizStarted ? _buildInstructionsScreen() : _buildQuizScreen(),
      ),
    );
  }
}

class OptionButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          title: Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
          trailing:
              isSelected ? Icon(Icons.check_circle, color: Colors.blue) : null,
        ),
      ),
    );
  }
}

class QuestionNavigation extends StatelessWidget {
  final int totalQuestions;
  final int currentQuestionIndex;
  final Function(int) onTap;

  const QuestionNavigation({
    super.key,
    required this.totalQuestions,
    required this.currentQuestionIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < totalQuestions; i += 3)
          Row(
            //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int j = i; j < i + 3 && j < totalQuestions; j++)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: () => onTap(j),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: j < currentQuestionIndex
                            ? Colors.blue.withOpacity(0.2)
                            : null,
                        border: Border.all(
                          color: currentQuestionIndex == j
                              ? Colors.blue
                              : Colors.grey,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${j + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            color: j < currentQuestionIndex
                                ? Colors.blue
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

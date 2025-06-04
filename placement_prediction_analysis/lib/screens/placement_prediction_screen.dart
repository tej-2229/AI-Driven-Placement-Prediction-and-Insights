import 'package:flutter/material.dart';
import 'package:placement_prediction_analysis/models/test_result.dart';
import 'package:placement_prediction_analysis/models/user_model.dart';
import 'package:placement_prediction_analysis/screens/test_result_card.dart';
import 'package:placement_prediction_analysis/services/firebase_service.dart';
import 'package:placement_prediction_analysis/services/ml_service.dart'
    show MLService;

class PredictionScreen extends StatefulWidget {
  final String userId;

  const PredictionScreen({super.key, required this.userId});

  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final MLService _mlService = MLService();

  UserModel? _user;
  List<TestResult> _testResults = [];
  bool _isLoading = false;
  String _predictionResult = '';
  double _probability = 0.0;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      _user = await _firebaseService.getUserData(widget.userId);
      _testResults = await _firebaseService.getUserTestResults(widget.userId);

      if (_user != null) {
        await _predictPlacement();
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  

  Future<void> _predictPlacement() async {
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      final mlInput = _user!.toMLInput(_testResults);
      final result = await _mlService.predictPlacement(mlInput);

      setState(() {
        _predictionResult =
            result['placement_status'] == 1 ? 'Placed' : 'Not Placed';
        _probability = result['probability'];
        _suggestions = List<String>.from(result['suggestions']);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Placement Prediction',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      const Text('User data not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? screenWidth * 0.1 : 16.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Section
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.primaryColor,
                                    child: Text(
                                      _user!.name[0],
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _user!.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(
                                      Icons.school, 'CGPA: ${_user!.cgpa}'),
                                  _buildInfoChip(Icons.grade,
                                      '10th: ${_user!.tenthMarks}%'),
                                  _buildInfoChip(Icons.grade,
                                      '12th: ${_user!.twelfthMarks}%'),
                                  _buildInfoChip(Icons.work,
                                      'Projects: ${_user!.projects}'),
                                  _buildInfoChip(Icons.business_center,
                                      'Internships: ${_user!.internships}'),
                                  _buildInfoChip(Icons.code,
                                      'Skills: ${_user!.technicalSkills}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Test Results Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Test Results',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                            ],
                          ),
                          if (_testResults.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assessment_outlined,
                                      size: 48,
                                      color: theme.disabledColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No test results available',
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.disabledColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context)
                                            .size
                                            .width >
                                        800
                                    ? 3
                                    : MediaQuery.of(context).size.width > 600
                                        ? 2
                                        : 1,
                                crossAxisSpacing: 40,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.5,
                              ),
                              itemCount: _testResults.length,
                              itemBuilder: (context, index) {
                                return TestResultCard(
                                    result: _testResults[index]);
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Prediction Result Section
                      if (_predictionResult.isNotEmpty)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          child: Card(
                            elevation: 4,
                            color: 
                                 Colors.green
                                    .withOpacity(isDarkMode ? 0.2 : 0.1),
                                
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:  Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      
                                      Text(
                                        'Placement Prediction Probability: ${_probability.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color:  Colors.black
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: _probability / 100,
                                    backgroundColor: theme.dividerColor,
                                    color:  Colors.green,
                                    minHeight: 10,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  if (_suggestions.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Recommendations:',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._suggestions.map((s) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.arrow_right,
                                                color: theme.primaryColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  s,
                                                  style: theme
                                                      .textTheme.bodyMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Run Prediction Again'),
                          onPressed: _predictPlacement,
                          style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8BB2B2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      visualDensity: VisualDensity.compact,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
    );
  }
}

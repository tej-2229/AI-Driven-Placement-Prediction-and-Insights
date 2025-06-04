import 'package:placement_prediction_analysis/models/test_result.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double cgpa;
  final int tenthMarks;
  final int twelfthMarks;
  final int projects;
  final int internships;
  final String technicalSkills;
  final String languagesKnown;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.cgpa,
    required this.tenthMarks,
    required this.twelfthMarks,
    required this.projects,
    required this.internships,
    required this.technicalSkills,
    required this.languagesKnown,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      cgpa: (map['cgpa'] ?? 0).toDouble(),
      tenthMarks: map['tenthMarks'] ??
          map['tentMarks'] ??
          0, // Handle typo in your data
      twelfthMarks: map['twelfthMarks'] ?? 0,
      projects: map['projects'] ?? 0,
      internships: map['internships'] ?? 0,
      technicalSkills: map['technicalSkills'] ?? '',
      languagesKnown: map['languagesKnown'] ?? '',
    );
  }

  Map<String, dynamic> toMLInput(List<TestResult> testResults) {
  final latestTest = testResults.isNotEmpty ? testResults.last : null;
  return {
    '10thMarks': tenthMarks,
    '12thMarks': twelfthMarks,
    'GraduationMarks': (cgpa * 10).round(), // Convert CGPA (0-10 scale) to percentage
    'TechnicalScore': latestTest?.technicalScore ?? 15,
    'Quants': latestTest?.quantScore ?? 15,
    'Verbal': latestTest?.verbalScore ?? 15,
    'projects': projects,
    'internships': internships,
    'technicalSkills': technicalSkills.toLowerCase(),
  };
}

  //Convert to ML input format
  // Map<String, dynamic> toMLInput(List<TestResult> testResults) {
  //   final latestTest = testResults.isNotEmpty ? testResults.last : null;
  //   return {
  //     '10th Marks': tenthMarks,
  //     '12th Marks': twelfthMarks,
  //     'Graduation Marks': cgpa * 10, 
  //     // 'Technical Score (out of 20)': 15,
  //     // 'Quants': 15,
  //     // 'Verbal': 15,
  //     'Technical Score (out of 20)': latestTest?.technicalScore ?? 15,
  //     'Quants': latestTest?.quantScore ?? 15,
  //     'Verbal': latestTest?.verbalScore ?? 15,
  //     'Number of Projects': projects,
  //     'Number of Internships': internships,
  //     'Java': technicalSkills.toLowerCase().contains('java') ? 1 : 0,
  //     'Python': technicalSkills.toLowerCase().contains('python') ? 1 : 0,
  //     'C++': technicalSkills.toLowerCase().contains('c++') ? 1 : 0,
  //     'ML': technicalSkills.toLowerCase().contains('ml') ? 1 : 0,
  //     'AI': technicalSkills.toLowerCase().contains('ai') ? 1 : 0,
  //     'SQL': technicalSkills.toLowerCase().contains('sql') ? 1 : 0,
  //     'Tableau': technicalSkills.toLowerCase().contains('tableau') ? 1 : 0,
  //     'JavaScript':
  //         technicalSkills.toLowerCase().contains('javascript') ? 1 : 0,
  //     'DSA': technicalSkills.toLowerCase().contains('dsa') ? 1 : 0,
  //     'ReactJS': technicalSkills.toLowerCase().contains('reactjs') ? 1 : 0,
  //     'MongoDB': technicalSkills.toLowerCase().contains('mongodb') ? 1 : 0,
  //     'GenAI': technicalSkills.toLowerCase().contains('genai') ? 1 : 0,
  //     'MobileDev': technicalSkills.toLowerCase().contains('mobiledev') ? 1 : 0,
  //     'WebDev': technicalSkills.toLowerCase().contains('webdev') ? 1 : 0,
  //   };
  // }
}

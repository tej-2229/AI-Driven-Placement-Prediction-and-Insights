import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:placement_prediction_analysis/screens/quiz_screen.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key});

  @override
  _UserFormScreenState createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _tenthMarksController = TextEditingController();
  final TextEditingController _twelfthMarksController = TextEditingController();
  final TextEditingController _projectsController = TextEditingController();
  final TextEditingController _internshipsController = TextEditingController();
  final TextEditingController _technicalSkillsController =
      TextEditingController();
  final TextEditingController _languagesKnownController =
      TextEditingController();
  final TextEditingController _cgpaController = TextEditingController();

  bool _isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _fetchUserData();
    } else {
      print("No user logged in.");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    if (userId == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _tenthMarksController.text = data['tenthMarks']?.toString() ?? '';
          _twelfthMarksController.text = data['twelfthMarks']?.toString() ?? '';
          _projectsController.text = data['projects']?.toString() ?? '';
          _internshipsController.text = data['internships']?.toString() ?? '';
          _technicalSkillsController.text = data['technicalSkills'] ?? '';
          _languagesKnownController.text = data['languagesKnown'] ?? '';
          _cgpaController.text = data['cgpa']?.toString() ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': _fullNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'tenthMarks': double.tryParse(_tenthMarksController.text) ?? 0,
        'twelfthMarks': double.tryParse(_twelfthMarksController.text) ?? 0,
        'projects': int.tryParse(_projectsController.text) ?? 0,
        'internships': int.tryParse(_internshipsController.text) ?? 0,
        'technicalSkills': _technicalSkillsController.text,
        'languagesKnown': _languagesKnownController.text,
        'cgpa': double.tryParse(_cgpaController.text) ?? 0,
      });

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => QuizScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Form'), centerTitle: true, elevation: 0, automaticallyImplyLeading: false,),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Wrap(
                      spacing: 20,
                      runSpacing: 25,
                      children: [
                        _buildSizedTextField(_fullNameController, 'Full Name'),
                        _buildSizedTextField(_emailController, 'Email'),
                        _buildSizedTextField(_phoneController, 'Phone Number'),
                        _buildSizedTextField(
                            _tenthMarksController, '10th Marks (%)'),
                        _buildSizedTextField(
                            _twelfthMarksController, '12th Marks (%)'),
                        _buildSizedTextField(
                            _projectsController, 'Number of Projects'),
                        _buildSizedTextField(_internshipsController,
                            'Number of Internships'),
                        _buildSizedTextField(
                            _technicalSkillsController, 'Technical Skills'),
                        _buildSizedTextField(
                            _languagesKnownController, 'Languages (English, Hindi, etc.)'),
                        _buildSizedTextField(_cgpaController, 'CGPA (0-10)'),
                      ],
                    ),
                    SizedBox(height: 60),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8BB2B2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSizedTextField(TextEditingController controller, String label) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2.5 - 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

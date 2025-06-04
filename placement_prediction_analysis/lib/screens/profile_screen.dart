import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:placement_prediction_analysis/screens/home_screen.dart';

class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
        userData?.forEach((key, value) {
          String textValue;
          if (value is String) {
            textValue = value;
          } else if (value is int || value is double) {
            textValue = value.toString();
          } else {
            textValue = '';
          }
          _controllers[key] = TextEditingController(text: textValue);
        });

        setState(() {});
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = _auth.currentUser;
    if (user != null) {
      final updatedData = {
        for (var key in _controllers.keys)
          if (!_isNonEditableField(key)) key: _controllers[key]!.text,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  void _logout() async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pop(); 
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  bool _isNonEditableField(String key) {
    return ['email', 'phone', 'tenthMarks', 'twelfthMarks', 'cgpa']
        .contains(key);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 15,
        ),
        child: _buildDrawerContent(),
      ),
    );
  }

  Widget _buildDrawerContent() {
    return SizedBox(
      child: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 50),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF8BB2B2),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildEditableField('name', 'Full Name'),
                      _buildConditionalField('email', 'Email'),
                      _buildConditionalField('phone', 'Phone'),
                      _buildConditionalField('tenthMarks', '10th Marks'),
                      _buildConditionalField('twelfthMarks', '12th Marks'),
                      _buildConditionalField('cgpa', 'CGPA'),
                      _buildEditableField(
                          'technicalSkills', 'Technical Skills'),
                      _buildEditableField('languagesKnown', 'Languages Known'),
                      _buildEditableField('projects', 'Projects'),
                      _buildEditableField('internships', 'Internships'),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BB2B2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Logout',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEditableField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: const Icon(Icons.edit, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildConditionalField(String key, String label) {
    return userData?[key] == null
        ? _buildEditableField(key, label)
        : _buildNonEditableField(key, label);
  }

  Widget _buildNonEditableField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: TextEditingController(text: userData?[key]?.toString() ?? "Not provided"),
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: const Icon(Icons.remove, color: Colors.grey),
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

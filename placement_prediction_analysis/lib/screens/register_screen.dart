import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:placement_prediction_analysis/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: screenWidth > 800
                ? _buildDesktopLayout(authService, context)
                : _buildMobileLayout(authService, context),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(AuthService authService, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 450,
          height: 600,
          margin: EdgeInsets.fromLTRB(30, 30, 15, 30),
          padding: EdgeInsets.all(50),
          decoration: BoxDecoration(
            color: Color(0xFF8BB2B2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Center(
            child: Image.asset("assets/logo.png", height: 500, fit: BoxFit.contain),
          ),
        ),
        Container(
          width: 600,
          height: 600,
          margin: EdgeInsets.fromLTRB(15, 30, 30, 30),
          child: _buildRegistrationForm(authService, context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AuthService authService, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(70),
          color: Color(0xFF8BB2B2),
          width: double.infinity,
          child: Center(
              child: Image.asset("assets/logo.png", height: 500, fit: BoxFit.cover)),
        ),
        _buildRegistrationForm(authService, context),
      ],
    );
  }

  Widget _buildRegistrationForm(AuthService authService, BuildContext context) {
    return Container(
      width: 900,
      padding: EdgeInsets.all(70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Full Name'),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email Address'),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              final user = await authService.register(
                _emailController.text,
                _passwordController.text,
              );
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'name': _nameController.text,
                  'email': _emailController.text,
                  'createdAt': Timestamp.now(),
                });
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Success"),
                      content: Text("Account created successfully!"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: Text("OK"),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8BB2B2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Create Account'),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text(
              "Already have an account? Login",
              style: TextStyle(
                color: Color(0xFF8BB2B2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

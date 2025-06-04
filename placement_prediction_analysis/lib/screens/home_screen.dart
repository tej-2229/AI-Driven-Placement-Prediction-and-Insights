import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:placement_prediction_analysis/services/auth_service.dart';
import 'package:placement_prediction_analysis/screens/placement_prediction_screen.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'user_form_screen.dart';
import 'quiz_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isFormFilled = false;
  String userName = '';
  String userId = '';


  @override
  void initState() {
    super.initState();
    _checkUserForm();
  }

  Future<void> _checkUserForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          isFormFilled = true;
          userId = user.uid;
          userName = userDoc['name'] ?? 'User';
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.isLoggedIn();

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const ProfileDrawer(),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3FDFD), Color(0xFFCBF1F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 80),
            _buildFeatureCard(
              context,
              icon: Icons.edit_document,
              title: 'User Form',
              description: 'Fill in your academic and skill details',
              screen: const UserFormScreen(),
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              context,
              icon: Icons.quiz,
              title: 'Quiz',
              description: 'Test your technical skills',
              screen: QuizScreen(),
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              context,
              icon: Icons.bar_chart,
              title: 'Power BI Dashboard',
              description: 'Visualize placement data and insights',
              screen: const DashboardScreen(),
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              context,
              icon: Icons.analytics,
              title: 'Model Predictor',
              description: 'Predict your placement chance using AI model',
              screen: PredictionScreen(userId: userId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    return Row(
      children: [
        if (isLoggedIn && isFormFilled)
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFF8BB2B2),
              child: Icon(Icons.person, color: Colors.white),
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        // const CircleAvatar(
        //   radius: 30,
        //   backgroundColor: Color(0xFF8BB2B2),
        //   child: Icon(Icons.person, size: 30, color: Colors.white),
        // ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLoggedIn ? 'Welcome, $userName!' : 'Welcome Guest!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              isLoggedIn
                  ? 'Explore your placement journey'
                  : 'Login to unlock full features',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        Spacer(),
        if (!isLoggedIn)
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      required Widget screen}) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.isLoggedIn();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          if (!isLoggedIn) {
            _showLoginRequiredDialog(context);
          } else {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => screen));
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: const Color(0xFF50C2C9)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
            'Please login or create an account to access this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


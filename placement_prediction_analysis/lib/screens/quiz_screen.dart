import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:placement_prediction_analysis/screens/question_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> companies = [];
  bool isLoading = true;

  final Map<String, String> companyImages = {
    'Google': 'assets/google.png',
    'Accenture': 'assets/accenture.png',
    'Infosys': 'assets/infosys.png',
    'Wipro': 'assets/wipro.png',
    'LTIMindtree': 'assets/ltimindtree.png',
    'Tech Mahindra': 'assets/techmahindra.png',
    'Cognizant': 'assets/cognizant.png'
  };

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    try {
      final snapshot = await _firestore.collection('companies').get();
      setState(() {
        companies = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching companies: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load companies. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Select a Company',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : isMediumScreen ? 40 : 80,
                vertical: isSmallScreen ? 16 : 30,
              ),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isSmallScreen ? 2 : 3,
                  crossAxisSpacing: isSmallScreen ? 12 : 20,
                  mainAxisSpacing: isSmallScreen ? 12 : 20,
                  childAspectRatio: isSmallScreen ? 0.9 : 1.5,
                ),
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  final companyName = company['name'];
                  final imagePath = companyImages[companyName] ?? 'assets/default_company.png';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AptitudeTestScreen(
                            companyId: company['id'],
                            companyName: companyName,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: isSmallScreen ? 80 : 180,
                              width: isSmallScreen ? 80 : 180,
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              companyName,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
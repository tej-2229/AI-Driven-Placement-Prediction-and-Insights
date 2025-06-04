// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class MLService {
//   static const String apiUrl = 'http://127.0.0.1:5000/predict'; 

//   Future<Map<String, dynamic>> predictPlacement(Map<String, dynamic> inputData) async {
//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(inputData),
//       );

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         throw Exception('Failed to get prediction: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Prediction error: $e');
//     }
//   }
// }



import 'dart:convert';

import 'package:http/http.dart' as http;

class MLService {
  static const String apiUrl = 'http://127.0.0.1:5000/predict';  // Update with your server IP

  Future<Map<String, dynamic>> predictPlacement(Map<String, dynamic> inputData) async {
    try {
      print("Sending to ML API: $inputData");
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(inputData),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print("Received from ML API: $result");
        return result;
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Prediction error: $e');
    }
  }
}
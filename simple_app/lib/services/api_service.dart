import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class ApiService {
  // Using localhost. If testing on Android emulator, this should be 10.0.2.2.
  static const String baseUrl = 'http://localhost:8000';

  Future<List<Transaction>> uploadStatement(File file, String person, String bank) async {
    var request = http.MultipartRequest('POST', Uri.parse('\$baseUrl/upload'));
    
    request.fields['person'] = person;
    request.fields['bank'] = bank;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> txs = data['transactions'];
      return txs.map((j) => Transaction.fromJson(j)).toList();
    } else {
      throw Exception('Failed to upload statement: \${response.body}');
    }
  }
}

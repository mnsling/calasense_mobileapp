import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


class PredictService {
  final String baseUrl; // e.g., http://10.0.2.2:5000
  PredictService(this.baseUrl);


  Future<Map<String, dynamic>> predictFromAsset(String assetPath) async {
    // Load asset bytes
    final bd = await rootBundle.load(assetPath);
    final bytes = bd.buffer.asUint8List();


    // Build multipart request to /predict
    final uri = Uri.parse('$baseUrl/predict?image=false');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',                      // Flask expects "image"
          bytes,
          filename: 'test_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      )
      ..headers['Accept'] = 'application/json';


    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);


    if (resp.statusCode != 200) {
      throw Exception('Predict failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}






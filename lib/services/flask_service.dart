import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';

class FlaskService {
  Future<Map<String, dynamic>> detectDisease(File imageFile) async {
    var uri = Uri.parse('$FLASK_BASE_URL/detect');
    var request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);

      return {
        "detections": jsonData["detections"],
        "annotatedUrl": "$FLASK_BASE_URL${jsonData["annotated_url"]}"
      };
    } else {
      throw Exception(
          'Failed to detect disease. Status: ${response.statusCode}');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
class Api {
  static String _baseUrl = ''; 
  static String get api {
    if (_baseUrl.isEmpty) {
      return 'http://panel.lexzymarket.my.id:2208';
    }
    return _baseUrl;
  }
  static Future<void> loadGh() async {
    try {
      final url = 'https://raw.githubusercontent.com/Ryverzoffc/Axora-Api/main/server.json';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer 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',
          'Accept': 'application/vnd.github.v3+json'
        },
      );     
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['x'] != null) {
          _baseUrl = data['x'];
        }
      }
    } catch (e) {
      print('$e');
    }
  }
}

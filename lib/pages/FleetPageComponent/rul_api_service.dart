import 'dart:convert';
import 'package:http/http.dart' as http;

class RulApiService {
  final String baseUrl;

  RulApiService({
    required this.baseUrl,
  });

  Future<Map<String, dynamic>> predictRul(
    List<Map<String, dynamic>> observations,
  ) async {
    final url = Uri.parse('$baseUrl/predict');

    print("MENGIRIM REQUEST KE: $url");
    print("JUMLAH OBSERVASI: ${observations.length}");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'observations': observations,
      }),
    );

    print("STATUS CODE API: ${response.statusCode}");
    print("RESPONSE API: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Gagal melakukan prediksi RUL');
    }
  }
}
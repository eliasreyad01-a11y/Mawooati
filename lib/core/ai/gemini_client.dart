import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:mawoonati/core/errors/app_exception.dart';

/// عميل Gemini (مفتاح مجاني يضعه المستخدم في الإعدادات). لا شيء يُرسل بدون مفتاح.
class GeminiClient {
  GeminiClient(this.key, this.model);
  final String key;
  final String model;

  Future<String> generate(String prompt, {Uint8List? image, String mime = 'image/jpeg'}) async {
    if (key.isEmpty) {
      throw const AppException('أضف مفتاح Gemini من الإعدادات أولاً.');
    }
    final uri = Uri.https(
        'generativelanguage.googleapis.com', '/v1beta/models/$model:generateContent', {'key': key});
    final parts = <Map<String, dynamic>>[
      {'text': prompt},
      if (image != null) {'inline_data': {'mime_type': mime, 'data': base64Encode(image)}},
    ];
    try {
      final res = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'contents': [{'parts': parts}]}))
          .timeout(const Duration(seconds: 90));
      if (res.statusCode == 400 || res.statusCode == 403) {
        throw const AppException('مفتاح Gemini غير صالح. تحقق منه في الإعدادات.');
      }
      if (res.statusCode == 429) {
        throw const AppException('تجاوزت الحد المجاني مؤقتاً. حاول بعد قليل.');
      }
      if (res.statusCode != 200) {
        throw AppException('تعذّر الحصول على رد (${res.statusCode}). تحقق من اسم النموذج في الإعدادات.');
      }
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final text = (((j['candidates'] as List).first as Map)['content'] as Map)['parts'] as List;
      return text.map((p) => (p as Map)['text'] ?? '').join();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('تعذّر الاتصال بالخدمة. تحقق من الإنترنت وحاول مجدداً.');
    }
  }

  /// يستخرج أول كائن JSON من رد قد يحتوي على علامات ```.
  static Map<String, dynamic>? extractJson(String text) {
    final a = text.indexOf('{');
    final b = text.lastIndexOf('}');
    if (a < 0 || b <= a) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(text.substring(a, b + 1)) as Map);
    } catch (_) {
      return null;
    }
  }
}

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageUploader {
  static Future<http.Response> uploadToEndpoint(File image, String url) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(
      await http.MultipartFile.fromPath(
        'image', // field name must match backend's 'image'
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    try {
      // Guard against indefinitely hanging uploads by applying a timeout.
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      return await http.Response.fromStream(
        streamedResponse,
      ).timeout(const Duration(seconds: 30));
    } on Exception catch (e) {
      // Re-throw so callers can surface the error to the user.
      throw Exception('Upload to endpoint failed: $e');
    }
  }

  /// Uploads to imgbb and returns the public URL.
  static Future<String> uploadToImgbb(
    File imageFile, {
    required String apiKey,
  }) async {
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final request = http.MultipartRequest('POST', url);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    final streamed = await request.send();
    // Apply timeouts to avoid long hangs when uploading to external service.
    final body = await streamed.stream.bytesToString().timeout(
      const Duration(seconds: 30),
    );
    if (streamed.statusCode != 200) {
      throw Exception('imgbb upload failed: ${streamed.statusCode} - $body');
    }
    final jsonData = json.decode(body) as Map<String, dynamic>;
    final imageUrl = jsonData['data']?['url'] as String?;
    if (imageUrl == null) throw Exception('imgbb response missing URL');
    return imageUrl;
  }

  /// Uploads to imgbb and stores URL in Firestore `images` collection.
  static Future<String> uploadToImgbbAndSaveToFirestore(
    File imageFile, {
    required String apiKey,
  }) async {
    final imageUrl = await uploadToImgbb(imageFile, apiKey: apiKey);
    try {
      await FirebaseFirestore.instance.collection('images').add({
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed saving to Firestore: $e');
    }
    return imageUrl;
  }
}

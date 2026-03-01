import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageKitUploadResult {
  final String url;
  final String? fileId;
  const ImageKitUploadResult({required this.url, this.fileId});
}

Future<Map<String, dynamic>> _fetchImageKitAuth(String authEndpoint) async {
  final resp = await http.get(Uri.parse(authEndpoint));
  if (resp.statusCode != 200) {
    throw Exception('Auth endpoint failed: ${resp.statusCode} ${resp.body}');
  }
  return jsonDecode(resp.body) as Map<String, dynamic>;
}

Future<ImageKitUploadResult> uploadToImageKit({
  required File file,
  required String fileName,
  required String folder,
  required String publicKey,
  required String authEndpoint, // Netlify function URL
}) async {
  final auth = await _fetchImageKitAuth(authEndpoint);

  final uri = Uri.parse('https://upload.imagekit.io/api/v1/files/upload');
  final req = http.MultipartRequest('POST', uri);

  req.fields['publicKey'] = publicKey;
  req.fields['fileName'] = fileName;
  req.fields['folder'] = folder;

  // Required auth params:
  req.fields['token'] = auth['token'].toString();
  req.fields['expire'] = auth['expire'].toString();
  req.fields['signature'] = auth['signature'].toString();

  // Windows-safe: send bytes (not fromPath)
  final bytes = await file.readAsBytes();
  req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

  final streamed = await req.send();
  final body = await streamed.stream.bytesToString();

  if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
    throw Exception('ImageKit upload failed: ${streamed.statusCode} $body');
  }

  final json = jsonDecode(body) as Map<String, dynamic>;
  final url = (json['url'] ?? '').toString();
  final fileId = json['fileId']?.toString();

  if (url.isEmpty) {
    throw Exception('Upload succeeded but URL missing: $body');
  }

  return ImageKitUploadResult(url: url, fileId: fileId);
}
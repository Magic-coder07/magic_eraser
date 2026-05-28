import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';
import '../services/backend_config.dart';

class ObjectRemover extends StatefulWidget {
  final File? initialImage;
  const ObjectRemover({Key? key, this.initialImage}) : super(key: key);

  @override
  State<ObjectRemover> createState() => _ObjectRemoverState();
}

class _ObjectRemoverState extends State<ObjectRemover> {
  File? _image;
  bool _processing = false;
  Uint8List? _resultBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.gallery);
      if (x != null) setState(() => _image = File(x.path));
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _process() async {
    if (_image == null) return;
    setState(() => _processing = true);
    try {
      final endpoint = '${BackendConfig.baseUrl}/remove_object';
      final resp = await ImageUploader.uploadToEndpoint(_image!, endpoint);
      if (resp.statusCode == 200) {
        final contentType = resp.headers['content-type'] ?? '';
        if (contentType.startsWith('image/')) {
          if (!mounted) return;
          setState(() => _resultBytes = resp.bodyBytes);
        } else {
          final jsonBody = json.decode(resp.body);
          final url = jsonBody['result_url'] ?? jsonBody['url'];
          if (url != null) {
            try {
              final networkResp = await http
                  .get(Uri.parse(url))
                  .timeout(const Duration(seconds: 30));
              if (networkResp.statusCode == 200) {
                if (!mounted) return;
                setState(() => _resultBytes = networkResp.bodyBytes);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Result download failed: ${networkResp.statusCode}',
                    ),
                  ),
                );
              }
            } on Exception catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to download result: $e')),
              );
            }
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No result URL returned by backend'),
              ),
            );
          }
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing failed: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Remover')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _resultBytes != null
                    ? Image.memory(_resultBytes!)
                    : _image != null
                    ? Image.file(_image!)
                    : const Text('No image selected'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Select Image'),
                    onPressed: _pickImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _processing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: const Text('Remove Object'),
                    onPressed: _processing ? null : _process,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

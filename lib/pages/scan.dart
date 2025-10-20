// lib/pages/scan.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../config.dart'; // <-- Flask URL here

const _brand = Color(0xFF2F7D32);

class ScanPage extends StatefulWidget {
  final String? collectionId;
  const ScanPage({super.key, this.collectionId});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _picker = ImagePicker();
  XFile? _picked;
  bool _uploading = false;
  String? _predictionLabel;
  double? _confidence;
  String? _annotatedUrl; // <-- for bounding-box image

  SupabaseClient get _sb => Supabase.instance.client;

  Future<void> _pick(ImageSource src) async {
    if (src == ImageSource.camera) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        _toast('Camera permission denied');
        return;
      }
    }

    final pmState = await PhotoManager.requestPermissionExtend();
    if (!pmState.isAuth && !pmState.hasAccess) {
      _toast('Photos permission denied. Please allow in Settings.');
      await PhotoManager.openSetting();
      return;
    }

    final x = await _picker.pickImage(source: src, imageQuality: 90);
    if (!mounted || x == null) return;

    setState(() {
      _picked = x;
      _predictionLabel = null;
      _confidence = null;
      _annotatedUrl = null;
    });

    // Save camera captures to Gallery
    if (src == ImageSource.camera) {
      try {
        final bytes = await File(x.path).readAsBytes();
        final filename =
            'CalaSense_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await PhotoManager.editor.saveImage(
          Uint8List.fromList(bytes),
          filename: filename,
          title: filename,
          relativePath: Platform.isAndroid ? 'Pictures/CalaSense' : null,
        );
        _toast('Saved to Gallery');
      } catch (e) {
        _toast('Save failed: $e');
      }
    }
  }

  Future<void> _detectWithFlask() async {
    if (_picked == null) {
      _toast('Pick an image first.');
      return;
    }

    setState(() {
      _uploading = true;
      _annotatedUrl = null;
    });

    try {
      final url = Uri.parse('$FLASK_BASE_URL/detect');
      final request = http.MultipartRequest('POST', url);
      request.files
          .add(await http.MultipartFile.fromPath('image', _picked!.path));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(respStr);

        // Handle YOLOv5 detection result
        if (data['detections'] != null && data['detections'].isNotEmpty) {
          final best = (data['detections'] as List)
              .reduce((a, b) => a['confidence'] > b['confidence'] ? a : b);

          setState(() {
            _predictionLabel = best['name'] ?? 'Unknown';
            _confidence = (best['confidence'] as num?)?.toDouble() ?? 0.0;
            _annotatedUrl = '$FLASK_BASE_URL${data["annotated_url"]}';
          });

          _toast(
            'Detected: $_predictionLabel (${(_confidence! * 100).toStringAsFixed(1)}%)',
          );
        } else {
          _toast('No objects detected.');
        }
      } else {
        _toast('Detection failed: ${response.statusCode}');
      }
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _upload() async {
    if (_picked == null) {
      _toast('Pick an image first.');
      return;
    }

    // First, run detection before upload
    await _detectWithFlask();

    // Only continue if detection succeeded
    if (_predictionLabel == null || _confidence == null) {
      _toast('No detection result found — skipping upload.');
      return;
    }

    setState(() => _uploading = true);
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = _picked!.path.split('.').last;
      final object = 'public/$ts.$ext';

      // Upload to Supabase Storage
      await _sb.storage.from('scans').upload(
            object,
            File(_picked!.path),
            fileOptions: const FileOptions(upsert: false),
          );

      final publicUrl = _sb.storage.from('scans').getPublicUrl(object);

      // Insert record in Supabase table
      await _sb.from('scans').insert({
        'image_url': publicUrl,
        'predicted_class': _predictionLabel,
        'confidence': _confidence,
        'collection_id': widget.collectionId,
      });

      if (!mounted) return;
      _toast('Uploaded to Supabase successfully!');
      Navigator.pop(context, publicUrl);
    } catch (e) {
      _toast('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final showImage = _annotatedUrl != null
        ? Image.network(_annotatedUrl!, fit: BoxFit.contain)
        : _picked != null
            ? Image.file(File(_picked!.path), fit: BoxFit.contain)
            : const Icon(Icons.image, size: 80, color: Colors.black38);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.expand(
                  child: showImage,
                ),
              ),
            ),
            if (_predictionLabel != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(
                      'Prediction: $_predictionLabel',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_confidence != null)
                      Text(
                          'Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _uploading ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _uploading ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_picked == null || _uploading)
                        ? null
                        : _detectWithFlask,
                    icon: const Icon(Icons.science_outlined),
                    label: Text(
                      _uploading ? 'Detecting...' : 'Detect Disease',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_picked == null || _uploading) ? null : _upload,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      _uploading ? 'Uploading...' : 'Upload',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
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

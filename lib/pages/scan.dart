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
import '../components/top_snackbar.dart';

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
        showTopSnackBar(context, 'Camera permission denied');
        return;
      }
    }

    final pmState = await PhotoManager.requestPermissionExtend();
    if (!pmState.isAuth && !pmState.hasAccess) {
      showTopSnackBar(
          context, 'Photos permission denied. Please allow in Settings.');
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
      } catch (e) {
        showTopSnackBar(context, 'Save failed: $e');
      }
    }
  }

  List<Map<String, dynamic>> _detections = [];

  Future<void> _detectWithFlask() async {
    if (_picked == null) {
      showTopSnackBar(context, 'Pick an image first.');
      return;
    }

    setState(() {
      _uploading = true;
      _annotatedUrl = null;
      _detections = [];
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

        if (data['detections'] != null && data['detections'].isNotEmpty) {
          final List detections = data['detections'];

          setState(() {
            // Convert detections to a simpler form
            final all = detections.map<Map<String, dynamic>>((det) {
              return {
                'name': (det['name'] ?? 'Unknown').toString(),
                'confidence': (det['confidence'] as num?)?.toDouble() ?? 0.0,
              };
            }).toList();

            // --- Group detections by name and average their confidence ---
            final Map<String, List<double>> grouped = {};
            for (var det in all) {
              grouped
                  .putIfAbsent(det['name']!, () => [])
                  .add(det['confidence']!);
            }

            _detections = grouped.entries.map<Map<String, dynamic>>((entry) {
              final avg =
                  entry.value.reduce((a, b) => a + b) / entry.value.length;
              return {'name': entry.key, 'confidence': avg};
            }).toList();

            // --- Pick top disease (highest average confidence) for summary ---
            final best = _detections
                .reduce((a, b) => a['confidence'] > b['confidence'] ? a : b);
            _predictionLabel = best['name'];
            _confidence = best['confidence'];

            // --- Annotated bounding-box image ---
            _annotatedUrl = '$FLASK_BASE_URL${data["annotated_url"]}';
          });

          showTopSnackBar(context,
              'Detected ${_detections.length} objects. Top: $_predictionLabel (${(_confidence! * 100).toStringAsFixed(1)}%)');
        } else {
          showTopSnackBar(context, 'No objects detected.');
        }
      } else {
        showTopSnackBar(context, 'Detection failed: ${response.statusCode}');
      }
    } catch (e) {
      showTopSnackBar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _upload() async {
    if (_picked == null) {
      showTopSnackBar(context, 'Pick an image first.');
      return;
    }

    if (_predictionLabel == null ||
        _confidence == null ||
        _annotatedUrl == null) {
      showTopSnackBar(context, 'Please detect a disease before uploading.');
      return;
    }

    setState(() => _uploading = true);
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = _picked!.path.split('.').last;
      final originalObject = 'public/original_$ts.$ext';

      await _sb.storage.from('scans').upload(
            originalObject,
            File(_picked!.path),
            fileOptions: const FileOptions(upsert: false),
          );

      final originalPublicUrl =
          _sb.storage.from('scans').getPublicUrl(originalObject);

      final annotatedResponse = await http.get(Uri.parse(_annotatedUrl!));
      if (annotatedResponse.statusCode != 200) {
        throw Exception('Failed to download annotated image.');
      }

      final annotatedObject = 'public/annotated_$ts.jpg';
      await _sb.storage.from('scans').uploadBinary(
            annotatedObject,
            annotatedResponse.bodyBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final annotatedPublicUrl =
          _sb.storage.from('scans').getPublicUrl(annotatedObject);

      await _sb.from('scans').insert({
        'image_url': originalPublicUrl,
        'annotated_url': annotatedPublicUrl,
        'predicted_class': _predictionLabel,
        'confidence': _confidence,
        'collection_id': widget.collectionId,
      });

      if (!mounted) return;

      // ✅ Clear any previous snackbars (e.g., “Image uploaded to scans”)
      ScaffoldMessenger.of(context).clearSnackBars();

      // ✅ Show only your custom message
      showTopSnackBar(context, 'Uploaded to collections successfully!');

      Navigator.pop(context, annotatedPublicUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      showTopSnackBar(context, 'Upload failed: $e');
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
            if (_detections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Diseases:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ..._detections.map((det) => Text(
                          '- ${det['name']} '
                          '(${(det['confidence'] * 100).toStringAsFixed(1)}%)',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
                        )),
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
                    onPressed: (_picked == null ||
                            _uploading ||
                            _predictionLabel == null)
                        ? null
                        : _upload,
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

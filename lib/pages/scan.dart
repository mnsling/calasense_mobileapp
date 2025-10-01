// lib/pages/scan.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _brand = Color(0xFF2F7D32);

class ScanPage extends StatefulWidget {
  /// Optional: if provided, new uploads are linked to this folder/collection.
  final String? collectionId;

  const ScanPage({super.key, this.collectionId});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _picker = ImagePicker();
  XFile? _picked;
  bool _uploading = false;

  SupabaseClient get _sb => Supabase.instance.client;

  Future<void> _pick(ImageSource src) async {
    // Camera permission if needed
    if (src == ImageSource.camera) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        _toast('Camera permission denied');
        return;
      }
    }

    // Photos/Media permission (for picking & saving)
    final pmState = await PhotoManager.requestPermissionExtend();
    if (!pmState.isAuth && !pmState.hasAccess) {
      _toast('Photos permission denied. Please allow in Settings.');
      await PhotoManager.openSetting();
      return;
    }

    final x = await _picker.pickImage(source: src, imageQuality: 90);
    if (!mounted || x == null) return;

    setState(() => _picked = x);

    // Save camera captures to Gallery (optional)
    if (src == ImageSource.camera) {
      try {
        final bytes = await File(x.path).readAsBytes();
        final filename = 'CalaSense_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final saved = await PhotoManager.editor.saveImage(
          Uint8List.fromList(bytes),
          filename: filename,
          title: filename,
          relativePath: Platform.isAndroid ? 'Pictures/CalaSense' : null,
        );

        _toast(saved != null ? 'Saved to Gallery' : 'Could not save to Gallery');
      } catch (e) {
        _toast('Save failed: $e');
      }
    }
  }

  Future<void> _upload() async {
    if (_picked == null) {
      _toast('Pick an image first.');
      return;
    }

    setState(() => _uploading = true);
    try {
      // 1) Upload to Storage bucket "scans" under public/
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = _picked!.path.split('.').last;
      final object = 'public/$ts.$ext';

      await _sb.storage.from('scans').upload(
        object,
        File(_picked!.path),
        fileOptions: const FileOptions(upsert: false),
      );

      final publicUrl = _sb.storage.from('scans').getPublicUrl(object);

      // 2) Insert DB row (link to collection if provided)
      await _sb.from('scans').insert({
        'image_url': publicUrl,
        'predicted_class': null,
        'confidence': null,
        'collection_id': widget.collectionId, // <-- new
        // created_at defaults in DB
      });

      _toast('Image uploaded!');
      if (!mounted) return;
      Navigator.pop(context, publicUrl); // return URL to caller (ScansPage)
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
              child: Center(
                child: _picked == null
                    ? Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Icon(Icons.image, size: 80, color: Colors.black38),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_picked!.path), fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_picked == null || _uploading) ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _uploading ? 'Uploading...' : 'Upload',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

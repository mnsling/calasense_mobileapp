import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scan_info_page.dart';

class ScansPage extends StatefulWidget {
  /// Use dynamic so it works for uuid String (recommended) or int.
  final dynamic collectionId;
  final String collectionName;

  const ScansPage({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  State<ScansPage> createState() => _ScansPageState();
}

class _ScansPageState extends State<ScansPage> {
  final _sb = Supabase.instance.client;

  bool _loading = false;
  bool _dirty = false; // set true on rename/delete etc
  late String _title;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _title = widget.collectionName;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _sb
          .from('scans')
          .select(
              'id,image_url,annotated_url,predicted_class,confidence,created_at')
          .eq('collection_id', widget.collectionId) // collection_id is uuid
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() => _items = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      _toast('Load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Folder actions ----------

  void _openFolderMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Rename folder'),
                onTap: () {
                  Navigator.pop(ctx);
                  _renameFolder();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: const Text('Delete folder'),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteFolder();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _renameFolder() async {
    final controller = TextEditingController(text: _title);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );

    final trimmed = newName?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == _title) return;

    try {
      // collections PK is id_uuid (UUID)
      final res = await _sb
          .from('collections')
          .update({'name': trimmed})
          .eq('id_uuid', widget.collectionId)
          .select();

      if ((res as List).isEmpty) {
        _toast('Rename did not match any rows. Check RLS or id.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _title = trimmed;
        _dirty = true;
      });
      _toast('Folder renamed');
    } catch (e) {
      _toast('Rename failed: $e');
    }
  }

  Future<void> _deleteFolder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder'),
        content: const Text(
            'This will remove the folder. Scans linked to it may also be removed depending on your DB rules.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await _sb
          .from('collections')
          .delete()
          .eq('id_uuid', widget.collectionId)
          .select();
      if ((res as List).isEmpty) {
        _toast('Delete did not match any rows. Check RLS or id.');
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true); // refresh parent
    } catch (e) {
      _toast('Delete failed: $e');
    }
  }

  Future<void> _deleteScan(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete scan'),
        content: const Text('Remove this scan from the collection?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _sb.from('scans').delete().eq('id', id); // scans PK is id
      _items.removeWhere((r) => r['id'] == id);
      if (!mounted) return;
      setState(() => _dirty = true);
      _toast('Deleted');
    } catch (e) {
      _toast('Delete failed: $e');
    }
  }

  // ---------- UI ----------

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _handleBack() {
    Navigator.pop(context, _dirty);
  }

  @override
  Widget build(BuildContext context) {
    final pinCount = _items.length;

    return WillPopScope(
      onWillPop: () async {
        _handleBack();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF3F9F1), Color(0xFFEAF7E2), Color(0xFFDAF0C9)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Material(
                            color: Colors.white10,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _handleBack,
                              child: const SizedBox(
                                height: 44,
                                width: 44,
                                child: Icon(Icons.arrow_back,
                                    color: Colors.black, size: 30),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.white10,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _openFolderMenu,
                              child: const SizedBox(
                                height: 44,
                                width: 44,
                                child: Icon(Icons.more_horiz_rounded,
                                    color: Colors.black, size: 30),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _title,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: const Color(0xFF2F7D32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pinCount ${pinCount == 1 ? 'Pin' : 'Pins'}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.black54, height: 1.25),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _items.isEmpty
                            ? const Center(
                                child: Text('No scans yet.',
                                    style: TextStyle(color: Colors.black54)))
                            : GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: .9,
                                ),
                                itemCount: _items.length,
                                itemBuilder: (_, i) => _ScanCard(
                                  row: _items[i],
                                  onDelete: () => _deleteScan(_items[i]['id']),
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback? onDelete;

  const _ScanCard({required this.row, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final url = (row['image_url'] ?? '').toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          // Navigate to ScanInfoPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanInfoPage(scan: row),
            ),
          );
        },
        onLongPress: onDelete,
        child: url.isEmpty
            ? Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.black26, size: 40),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.black26, size: 40),
                  ),
                ),
              ),
      ),
    );
  }
}

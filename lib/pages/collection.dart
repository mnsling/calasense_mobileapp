import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'folder.dart';
import 'scan_info_page.dart';
import '../components/top_snackbar.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final _sb = Supabase.instance.client;

  final _search = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _orphanScans = []; // scans with no folder

  // Multi-select state for orphan pins
  bool _selecting = false;
  final Set<dynamic> _selectedPinIds = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ---------------- Data ----------------

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      // IMPORTANT: select id_uuid since that’s the PK
      final rows = await _sb
          .from('collections')
          .select('id_uuid,name,created_at') // <- include id_uuid
          .order('created_at', ascending: false);
      _collections = List<Map<String, dynamic>>.from(rows);

      // Orphan pins (no folder)
      final pins = await _sb
          .from('scans')
          .select(
            'id, image_url, predicted_class, confidence, created_at, annotated_url',
          )
          .isFilter('collection_id', null)
          .order('created_at', ascending: false)
          .limit(200);

      _orphanScans = List<Map<String, dynamic>>.from(pins);
    } catch (e) {
      showTopSnackBar(context, 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredFolders {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _collections;
    return _collections.where((r) {
      final name = (r['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  // Build PostgREST in.(...) value: quote strings (e.g., if ids are text)
  String _inClause(List<dynamic> ids) {
    final joined = ids.map((v) => v is String ? '"$v"' : v).join(',');
    return '($joined)';
  }

  // ---------------- Folder CRUD ----------------

  Future<void> _createFolder() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NewFolderSheet(),
    );

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;

    try {
      await _sb.from('collections').insert({'name': trimmed});
      await _loadAll();
      showTopSnackBar(context, 'Folder "$trimmed" created successfully!');
    } catch (e) {
      showTopSnackBar(context, 'Create failed: $e');
    }
  }

  Future<void> _renameFolder(String idUuid, String currentName) async {
    final controller = TextEditingController(text: currentName);
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
    if (trimmed.isEmpty || trimmed == currentName) return;

    try {
      final res = await _sb
          .from('collections')
          .update({'name': trimmed})
          .eq('id_uuid', idUuid)
          .select();

      if ((res as List).isEmpty) {
        showTopSnackBar(
            context, 'Rename did not match any rows. Check RLS or id.');
        return;
      }

      await _loadAll();
    } catch (e) {
      showTopSnackBar(context, 'Rename failed: $e');
    }
  }

  Future<void> _deleteFolder(String idUuid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "$name"?'),
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
    if (confirm != true) return;

    try {
      final res =
          await _sb.from('collections').delete().eq('id_uuid', idUuid).select();
      if ((res as List).isEmpty) {
        showTopSnackBar(
            context, 'Delete did not match any rows. Check RLS or id.');
        return;
      }

      await _loadAll();
      showTopSnackBar(context, 'Folder "$name" deleted successfully.');
    } catch (e) {
      showTopSnackBar(context, 'Delete failed: $e');
    }
  }

  void _openItemMenu(String idUuid, String name) {
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
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(ctx);
                  _renameFolder(idUuid, name);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteFolder(idUuid, name);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Select & More (Pins) ----------------

  void _toggleSelectionMode([bool? on]) {
    setState(() {
      _selecting = on ?? !_selecting;
      if (!_selecting) _selectedPinIds.clear();
    });
  }

  void _togglePick(dynamic id) {
    setState(() {
      if (_selectedPinIds.contains(id)) {
        _selectedPinIds.remove(id);
      } else {
        _selectedPinIds.add(id);
      }
    });
  }

  void _openMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                leading: const Icon(Icons.drive_file_move_rounded),
                title: const Text('Move selected to folder'),
                enabled: _selectedPinIds.isNotEmpty,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFolderAndMove();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: const Text('Delete selected'),
                enabled: _selectedPinIds.isNotEmpty,
                onTap: () {
                  Navigator.pop(ctx);
                  _deletePins(_selectedPinIds.toList());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFolderAndMove() async {
    if (_selectedPinIds.isEmpty) return;

    // 📂 Open bottom sheet to pick folder (return both id and name)
    final chosen = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FolderPickerSheet(collections: _collections),
    );

    if (chosen == null) return; // user canceled

    final chosenId = chosen['id'];
    final chosenName = chosen['name'];

    final ids = _selectedPinIds.toList();
    final inValue = '(${ids.map((e) => e is String ? '"$e"' : e).join(',')})';

    try {
      await _sb
          .from('scans')
          .update({'collection_id': chosenId}).filter('id', 'in', inValue);

      _orphanScans.removeWhere((r) => ids.contains(r['id']));
      _selectedPinIds.clear();
      _toggleSelectionMode(false);
      if (mounted) setState(() {});

      // ✅ Show folder name in snackbar
      showTopSnackBar(context,
          '${ids.length} pin${ids.length == 1 ? '' : 's'} moved to folder "$chosenName".');
    } catch (e) {
      showTopSnackBar(context, 'Move failed: $e');
    }
  }

  Future<void> _deletePins(List<dynamic> ids) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete ${ids.length} pin${ids.length == 1 ? '' : 's'}?'),
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

    final inValue = _inClause(ids);

    try {
      await _sb.from('scans').delete().filter('id', 'in', inValue);

      _orphanScans.removeWhere((r) => ids.contains(r['id']));
      _selectedPinIds.clear();
      _toggleSelectionMode(false);
      if (mounted) setState(() {});
      showTopSnackBar(
          context, '${ids.length} pin${ids.length == 1 ? '' : 's'} deleted.');
    } catch (e) {
      showTopSnackBar(context, 'Delete failed: $e');
    }
  }

  // ---------------- UI ----------------

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final t = GoogleFonts.poppinsTextTheme();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFDFF2D3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const _CollectionsHeader(),

              // Search + Add
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.search_rounded),
                            hintText: 'Search folders',
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: const Color(0xFF2F7D32),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _createFolder,
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          height: 48,
                          width: 48,
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Select & More
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    _ActionChip(
                      label: _selecting ? 'Cancel' : 'Select',
                      icon: _selecting
                          ? Icons.close_rounded
                          : Icons.check_circle_outline_rounded,
                      onTap: () => _toggleSelectionMode(),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _openMoreSheet,
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.more_horiz_rounded,
                              size: 22, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Folders
                            if (_filteredFolders.isNotEmpty) ...[
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 8),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: .95,
                                ),
                                itemCount: _filteredFolders.length,
                                itemBuilder: (_, i) {
                                  final folder = _filteredFolders[i];
                                  final idUuid =
                                      folder['id_uuid'] as String; // UUID
                                  final name =
                                      (folder['name'] ?? '').toString();
                                  final createdAt =
                                      folder['created_at']?.toString();

                                  return _FolderCard(
                                    name: name,
                                    createdAt: createdAt,
                                    onTap: () async {
                                      final changed =
                                          await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ScansPage(
                                            collectionId: idUuid,
                                            collectionName: name,
                                          ),
                                        ),
                                      );
                                      if (changed == true) _loadAll();
                                    },
                                    onMenu: () => _openItemMenu(idUuid, name),
                                    onLongPress: () =>
                                        _openItemMenu(idUuid, name),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Orphan pins
                            if (_orphanScans.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                                child: Text(
                                  'Pins',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2F7D32),
                                  ),
                                ),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                                itemCount: _orphanScans.length,
                                itemBuilder: (_, i) {
                                  final row = _orphanScans[i];
                                  final id = row['id'];
                                  final url =
                                      (row['image_url'] ?? '').toString();
                                  final picked = _selectedPinIds.contains(id);

                                  return GestureDetector(
                                    onTap: _selecting
                                        ? () => _togglePick(id)
                                        : () {
                                            print(row);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ScanInfoPage(scan: row),
                                              ),
                                            );
                                          },
                                    onLongPress: () =>
                                        _toggleSelectionMode(true),
                                    child: Stack(
                                      children: [
                                        _PinCard(url: url),
                                        if (_selecting)
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: _SelectDot(checked: picked),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (_filteredFolders.isEmpty &&
                                _orphanScans.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 120),
                                child: Center(
                                  child: Text(
                                    'No folders or pins yet.\nTap + to create a folder.',
                                    textAlign: TextAlign.center,
                                    style: t.titleMedium
                                        ?.copyWith(color: Colors.black54),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Small widgets ----------------

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Collections!",
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: const Color(0xFF2F7D32),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Organize your scanned calamansi leaves\ninto folders for easier review.",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.black87, height: 1.35),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 54,
            height: 54,
            child: ClipOval(
                child: Image.asset('assets/logo.png', fit: BoxFit.cover)),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectDot extends StatelessWidget {
  final bool checked;
  const _SelectDot({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        color: checked ? const Color(0xFF2F7D32) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 6)
        ],
      ),
      child: Icon(checked ? Icons.check : Icons.circle_outlined,
          size: 16, color: checked ? Colors.white : Colors.black45),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final String? createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenu;

  const _FolderCard({
    required this.name,
    this.createdAt,
    this.onTap,
    this.onLongPress,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? dt;
    if (createdAt != null) dt = DateTime.tryParse(createdAt!)?.toLocal();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_rounded,
                        size: 56, color: Color(0xFF2F7D32)),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (dt != null) ...[
                      const SizedBox(height: 6),
                      Text('${dt.month}/${dt.day}/${dt.year}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ],
                  ],
                ),
              ),
            ),
            if (onMenu != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onMenu,
                    child: const SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(Icons.more_vert_rounded, size: 20)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  final String url;
  const _PinCard({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: Colors.white,
        child: url.isEmpty
            ? const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.black26, size: 40))
            : Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.black26, size: 40),
                ),
              ),
      ),
    );
  }
}

class _NewFolderSheet extends StatefulWidget {
  @override
  State<_NewFolderSheet> createState() => _NewFolderSheetState();
}

class _NewFolderSheetState extends State<_NewFolderSheet> {
  final _controller = TextEditingController();
  bool _creating = false;

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() => _creating = true);
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),
            Text('New Folder',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Folder name',
                filled: true,
                fillColor: const Color(0xFFF6F7F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.create_new_folder_outlined),
                label: Text(_creating ? 'Creating...' : 'Create'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2F7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submit,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FolderPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> collections;

  const _FolderPickerSheet({required this.collections});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Move to Folder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...collections.map((c) => ListTile(
                leading: const Icon(Icons.folder),
                title: Text(c['name']),
                onTap: () {
                  Navigator.pop(context, {
                    'id': c['id_uuid'] ?? c['id'], // depends on your schema
                    'name': c['name'],
                  });
                },
              )),
        ],
      ),
    );
  }
}

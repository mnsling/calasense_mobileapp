import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color brand = Color(0xFF2F7D32);

  // Simple state (UI-only)
  String name = 'User Name';
  String email = 'email@example.com';
  String location = 'City, Country';

  int selectedTab = 0; // 0 = Uploads, 1 = History

  // Picked avatar image
  XFile? _avatar;

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (!mounted) return;
    if (picked != null) setState(() => _avatar = picked);
  }

  void _openAvatarPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 12,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAvatar(ImageSource.camera);
                },
              ),
              if (_avatar != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _avatar = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              Text('Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: brand,
                  )),
              const SizedBox(height: 16),

              // --- Avatar with camera badge ---
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                    _avatar != null ? FileImage(File(_avatar!.path)) : null,
                    child: _avatar == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                  InkWell(
                    onTap: _openAvatarPickerSheet,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.photo_camera_rounded,
                          size: 20, color: Color(0xFF2F7D32)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(name,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(email, style: GoogleFonts.poppins(fontSize: 14)),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(location, style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),

              // Edit + Logout
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final result = await showModalBottomSheet<_EditResult>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (ctx) => EditProfileSheet(
                          initialName: name,
                          initialEmail: email,
                          initialLocation: location,
                          onChangeAvatar: _openAvatarPickerSheet, // <— add
                          avatar: _avatar,
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          name = result.name;
                          email = result.email;
                          location = result.location;
                        });
                      }
                    },
                    child: Text('Edit Profile',
                        style: GoogleFonts.poppins(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand.withOpacity(0.2),
                      foregroundColor: brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
                    child: const Icon(Icons.logout, size: 18),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TabChip(
                    label: 'Uploads',
                    selected: selectedTab == 0,
                    onTap: () => setState(() => selectedTab = 0),
                  ),
                  const SizedBox(width: 40),
                  _TabChip(
                    label: 'History',
                    selected: selectedTab == 1,
                    onTap: () => setState(() => selectedTab = 1),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Content
              if (selectedTab == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: _PlaceholderCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _PlaceholderCard()),
                    ],
                  ),
                )
              else
                Column(
                  children: const [
                    _HistoryPlaceholderTile(),
                    _HistoryPlaceholderTile(),
                  ],
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet widget for editing profile
class EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialLocation;
  final VoidCallback onChangeAvatar; // tap to change avatar (uses parent flow)
  final XFile? avatar;

  const EditProfileSheet({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialLocation,
    required this.onChangeAvatar,
    required this.avatar,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  static const Color brand = Color(0xFF2F7D32);

  late final TextEditingController _name =
  TextEditingController(text: widget.initialName);
  late final TextEditingController _email =
  TextEditingController(text: widget.initialEmail);
  late final TextEditingController _location =
  TextEditingController(text: widget.initialLocation);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _location.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(),
    filled: true,
    fillColor: const Color(0xFFF5F7F6),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottom + 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Avatar preview + change
          Center(
            child: GestureDetector(
              onTap: widget.onChangeAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: widget.avatar != null
                        ? FileImage(File(widget.avatar!.path))
                        : null,
                    child: widget.avatar == null
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: brand),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Edit Profile',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 14),

          TextField(controller: _name, decoration: _deco('Name')),
          const SizedBox(height: 12),
          TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _deco('Email')),
          const SizedBox(height: 12),
          TextField(controller: _location, decoration: _deco('Location')),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _EditResult(
                        name: _name.text.trim(),
                        email: _email.text.trim(),
                        location: _location.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Save',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- small helpers / placeholders (unchanged) ---

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color brand = Color(0xFF2F7D32);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: selected ? brand : Colors.grey,
              )),
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 60,
            color: selected ? brand : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image, size: 40, color: Colors.white),
    );
  }
}

class _HistoryPlaceholderTile extends StatelessWidget {
  const _HistoryPlaceholderTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DISEASE NAME',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
              Text('XX%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                  )),
              Text('August 00, 2025',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditResult {
  final String name;
  final String email;
  final String location;
  _EditResult({required this.name, required this.email, required this.location});
}

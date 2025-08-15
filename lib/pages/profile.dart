import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false, elevation: 0),
      body: Center(child: Text('Profile', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600))),
    );
  }
}

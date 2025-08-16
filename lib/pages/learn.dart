import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text('Learn', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600))),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // no bottom nav here; the shell provides it
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false, // no back arrow
        elevation: 0,
      ),
      body: Center(
        child: Text('Home', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

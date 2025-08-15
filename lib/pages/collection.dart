import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Collection'), automaticallyImplyLeading: false, elevation: 0),
      body: Center(child: Text('Collection', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600))),
    );
  }
}

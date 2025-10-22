import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanInfoPage extends StatelessWidget {
  final Map<String, dynamic> scan;

  const ScanInfoPage({super.key, required this.scan});

  void _handleBack(BuildContext context) => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    // Extract data from Supabase
    final String predictedClass = scan['predicted_class'] ?? 'Unknown Disease';
    final double? confidenceValue = scan['confidence'] is num
        ? scan['confidence'].toDouble()
        : double.tryParse(scan['confidence']?.toString() ?? '');
    final String confidence = confidenceValue != null
        ? '${(confidenceValue * 100).toStringAsFixed(2)}%'
        : 'N/A';

    final String imageUrl = scan['image_url'] ?? '';

    // Format date properly (MM/DD/YYYY)
    String formattedDate = 'N/A';
    if (scan['created_at'] != null) {
      try {
        final dt = DateTime.tryParse(scan['created_at'].toString())?.toLocal();
        if (dt != null) {
          formattedDate = '${dt.month}/${dt.day}/${dt.year}';
        }
      } catch (_) {}
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F9F1), Color(0xFFEAF7E2), Color(0xFFDAF0C9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // === Back Button ===
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Material(
                          color: Colors.white10,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _handleBack(context),
                            child: const SizedBox(
                              height: 44,
                              width: 44,
                              child: Icon(Icons.arrow_back,
                                  color: Colors.black, size: 30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // === Logo & Header ===
                  Column(
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Scan Result',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2F7D32),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        predictedClass,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2F7D32),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Last Scanned: $formattedDate\nConfidence Level: $confidence',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // === Image ===
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Align(
                        alignment: Alignment.topCenter, // gives a bounded width
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.fitWidth,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    height: 200,
                                    child: const Icon(Icons.broken_image,
                                        size: 40, color: Colors.grey),
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/sample_leaf.jpg',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // === Info Cards ===
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: const [
                        _InfoCard(
                          title: 'General Information',
                          body:
                              'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry’s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',
                        ),
                        SizedBox(height: 14),
                        _InfoCard(
                          title: 'Symptoms',
                          body:
                              'Yellow patches on leaves, misshapen fruits, and premature fruit drop.',
                        ),
                        SizedBox(height: 14),
                        _InfoCard(
                          title: 'Care Tips',
                          body:
                              'Prune affected branches and apply recommended treatments from agricultural experts.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// === Info Card Widget ===
class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              )),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

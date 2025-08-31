import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard.dart'; // 👈 so we can reuse DashboardHeader

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final TextEditingController _search = TextEditingController();
  String _dateFilter = 'Date Scanned';
  RangeValues _confRange = const RangeValues(0.4, 0.9);

  @override
  Widget build(BuildContext context) {
    final t = GoogleFonts.poppinsTextTheme();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFDFF2D3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// --- Reused header from Dashboard ---
              const SizedBox(height: 30),
              const CollectionsHeader(),
              const SizedBox(height: 14),

              // ------- Search + Add -------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.search_rounded),
                            hintText: 'Search',
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: const Color(0xFF2F7D32), borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          // TODO: add new item flow
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          height: 48, width: 48,
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ------- Filter chips -------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    _ChipButton(
                      label: _dateFilter,
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateFilter =
                            '${picked.start.month}/${picked.start.day}/${picked.start.year} - '
                                '${picked.end.month}/${picked.end.day}/${picked.end.year}';
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    _ChipButton(
                      label: 'Confidence Range',
                      onTap: () async {
                        await showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => _ConfidenceSheet(
                            values: _confRange,
                            onChanged: (r) => setState(() => _confRange = r),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ------- Placeholder grid -------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .9,
                    ),
                    itemCount: 4, // just 4 placeholders for now
                    itemBuilder: (_, i) => const _PhotoPlaceholderCard(),
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

/// Header only
class CollectionsHeader extends StatelessWidget {
  const CollectionsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left texts
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
                    color: const Color(0xFF2F7D32), // brand green
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "A gallery of your scanned calamansi leaves, \nready for review and insights.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // Right logo in circle
          SizedBox(
            width: 54,
            height: 54,
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------- Small widgets -----------------

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholderCard extends StatelessWidget {
  const _PhotoPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Icon(Icons.image_outlined, size: 50, color: Colors.black26),
      ),
    );
  }
}

/// Bottom sheet for confidence range
class _ConfidenceSheet extends StatefulWidget {
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  const _ConfidenceSheet({required this.values, required this.onChanged});

  @override
  State<_ConfidenceSheet> createState() => _ConfidenceSheetState();
}

class _ConfidenceSheetState extends State<_ConfidenceSheet> {
  late RangeValues _values = widget.values;

  @override
  Widget build(BuildContext context) {
    final t = GoogleFonts.poppinsTextTheme();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Text('Confidence Range', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('${(_values.start * 100).toStringAsFixed(0)}%  –  ${(_values.end * 100).toStringAsFixed(0)}%',
              style: t.bodyMedium?.copyWith(color: Colors.black54)),
          RangeSlider(
            values: _values, min: 0, max: 1, divisions: 20,
            activeColor: const Color(0xFF2F7D32),
            onChanged: (v) => setState(() => _values = v),
          ),
          const SizedBox(height: 6),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2F7D32)),
            onPressed: () { widget.onChanged(_values); Navigator.pop(context); },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

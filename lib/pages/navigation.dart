import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard.dart'; // Home
import 'collection.dart'; // Collection
import 'scan.dart'; // Scan

class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  static const Color brand = Color(0xFF2F7D32);
  static const Color barBg = Colors.white;

  int current = 0;

  final _pages = const [
    DashboardPage(), // Home
    CollectionPage(), // Collection
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: current,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const _ScanFab(),
      bottomNavigationBar: BottomAppBar(
        color: barBg,
        elevation: 4,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: SizedBox(
          height: 78,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home on far left
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: current == 0,
                onTap: () => setState(() => current = 0),
              ),

              const SizedBox(width: 60), // space for Scan button

              // Collection on far right
              _NavItem(
                icon: Icons.eco_rounded,
                label: 'Collection',
                selected: current == 1,
                onTap: () => setState(() => current = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- widgets ----------

class _ScanFab extends StatelessWidget {
  static const Color brand = Color(0xFF2F7D32);
  const _ScanFab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 58,
          height: 58,
          child: FloatingActionButton(
            heroTag: 'scanFab',
            elevation: 0,
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: () async {
              final url = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanPage()),
              );
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2F7D32),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(14),
              child: const Icon(
                Icons.center_focus_strong_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color brand = Color(0xFF2F7D32);
    final Color iconColor = selected ? brand : Colors.black.withOpacity(.7);
    final TextStyle textStyle = GoogleFonts.poppins(
      fontSize: 12,
      color: selected ? brand : Colors.black.withOpacity(.7),
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 150, // keep width consistent
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 4),
            Text(label, style: textStyle, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

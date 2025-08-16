import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// import your tab pages
import 'dashboard.dart';   // Home
import 'collection.dart';  // Collection
import 'learn.dart';       // Learn
import 'profile.dart';     // Profile

class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  static const Color brand = Color(0xFF2F7D32);   // deep green icons
  static const Color barBg = Colors.white;   // mint bar background

  int current = 0; // selected tab

  // Keep pages alive while switching
  final _pages = const [
    DashboardPage(),   // Home
    CollectionPage(),  // Collection
    LearnPage(),       // Learn
    ProfilePage(),     // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Show tabs without losing their state
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: current == 0,
                onTap: () => setState(() => current = 0),
              ),
              _NavItem(
                icon: Icons.eco_rounded,
                label: 'Collection',
                selected: current == 1,
                onTap: () => setState(() => current = 1),
              ),
              const SizedBox(width: 60), // gap for the center FAB
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'Learn',
                selected: current == 2,
                onTap: () => setState(() => current = 2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: current == 3,
                onTap: () => setState(() => current = 3),
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
        // white ring + shadow (the halo)
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
        // green FAB
        SizedBox(
          width: 58,
          height: 58,
          child: FloatingActionButton(
            heroTag: 'scanFab',
            elevation: 0,
            backgroundColor: Colors.white, // FAB background (white)
            shape: const CircleBorder(), // Ensures FAB is circular
            onPressed: () {
              // TODO: navigate to scan/camera page
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2F7D32), // Your green brand color
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(14), // Space inside green circle
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
        width: 72,
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

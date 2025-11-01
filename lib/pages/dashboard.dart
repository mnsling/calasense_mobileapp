import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scan.dart';

/// Shortcuts
final _sb = Supabase.instance.client;

/// Get the current user's profile row once (used elsewhere if needed)
Future<Map<String, dynamic>?> fetchProfile() async {
  final user = _sb.auth.currentUser;
  if (user == null) return null;

  final res = await _sb
      .from('profiles')
      .select('username, email')
      .eq('id', user.id)
      .maybeSingle();

  return res;
}

/// Live stream of the current user's profile (for auto-updating header)
Stream<Map<String, dynamic>?> profileStream() {
  final user = _sb.auth.currentUser;
  if (user == null) {
    // emit a single null
    return Stream.value(null);
  }
  return _sb
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((rows) => rows.isEmpty ? null : rows.first);
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFDFF2D3)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔽 reduced from 30 → 10
                const SizedBox(height: 10),
                const DashboardHeader(),
                const SizedBox(height: 30),

                DetectButton(
                  onTap: () async {
                    final url = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanPage()),
                    );
                  },
                ),

                const SizedBox(height: 70),
                const SizedBox(height: 70),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header that greets the current user by their **latest** username.
/// Uses a Supabase Realtime stream so edits reflect instantly.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left texts
          Expanded(
            child: StreamBuilder<Map<String, dynamic>?>(
              stream: profileStream(),
              builder: (context, snap) {
                final user = _sb.auth.currentUser;

                // While loading/connecting, show a subtle placeholder
                if (snap.connectionState == ConnectionState.waiting) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 180,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 260,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  );
                }

                final data = snap.data;
                final username = (data?['username'] as String?)?.trim();
                final email = (data?['email'] as String?) ?? user?.email;

                final greetingName = (username != null && username.isNotEmpty)
                    ? username
                    : (email ?? 'User');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello $greetingName!",
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: const Color(0xFF2F7D32),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Welcome to CalaSense, Detect, Learn \nand Defend Your Calamansi Plants",
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Right logo in circle
          SizedBox(
            width: 54,
            height: 54,
            child: ClipOval(
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detect button card
class DetectButton extends StatelessWidget {
  final VoidCallback onTap;
  const DetectButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = GoogleFonts.poppinsTextTheme();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0x80AEEA00),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detect your plant now!',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'See results and learn more.',
                      style: t.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.black87,
                  size: 50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

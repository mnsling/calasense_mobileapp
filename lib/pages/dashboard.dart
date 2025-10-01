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
                const SizedBox(height: 30),
                const DashboardHeader(),
                const SizedBox(height: 30),

                // 👇 Scan button now opens ScanPage and awaits result
                DetectButton(
                  onTap: () async {
                    final url = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanPage()),
                    );
                    if (url != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image uploaded to scans')),
                      );
                    }
                  },
                ),

                const SizedBox(height: 70),
                const RecentScansCarousel(),
                const SizedBox(height: 70),
                const SuggestedReadsCarousel(),
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

                final greetingName =
                (username != null && username.isNotEmpty)
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

/// Recent Scans carousel (placeholder cards)
class RecentScansCarousel extends StatefulWidget {
  const RecentScansCarousel({super.key});

  @override
  State<RecentScansCarousel> createState() => _RecentScansCarouselState();
}

class _RecentScansCarouselState extends State<RecentScansCarousel> {
  final _pc = PageController(viewportFraction: 0.95);
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GoogleFonts.poppinsTextTheme();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Row(
            children: [
              Text(
                "Recent Scans",
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                "See More",
                style: t.bodyMedium?.copyWith(
                  color: const Color(0xFF2F7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Carousel (still placeholder UI)
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pc,
            itemCount: 5,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(left: 22, right: 12),
              child: _ScanPlaceholderCard(index: i),
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF2F7D32) : Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ScanPlaceholderCard extends StatelessWidget {
  final int index;
  const _ScanPlaceholderCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final t = GoogleFonts.poppinsTextTheme();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Title",
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              )),
          const SizedBox(height: 6),
          Text("Confidence Score: --%",
              style: t.bodyMedium?.copyWith(color: Colors.black87)),
          const SizedBox(height: 2),
          Text("Date Scanned: --/--/----",
              style: t.bodySmall?.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }
}

class SuggestedReadsCarousel extends StatefulWidget {
  const SuggestedReadsCarousel({super.key});

  @override
  State<SuggestedReadsCarousel> createState() => _SuggestedReadsCarouselState();
}

class _SuggestedReadsCarouselState extends State<SuggestedReadsCarousel> {
  final _pc = PageController(viewportFraction: 0.95);
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GoogleFonts.poppinsTextTheme();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title + subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suggested Reads',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                    color: Colors.black87,
                  )),
              const SizedBox(height: 6),
              Text(
                'Expand your knowledge on citrus health and disease prevention.',
                style: t.bodyMedium?.copyWith(
                    color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Carousel
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pc,
            itemCount: 3,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 30 : 14,
                right: i == 2 ? 30 : 14,
              ),
              child: const _ReadPlaceholderCard(),
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF2F7D32) : Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ReadPlaceholderCard extends StatelessWidget {
  const _ReadPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    final t = GoogleFonts.poppinsTextTheme();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, right: 12),
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Color(0xFF2F7D32),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Author',
                    style: t.bodySmall?.copyWith(color: Colors.black87)),
                Text(
                  'Title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                      'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: Colors.black12),
                const SizedBox(height: 8),
                Text(
                  'Read Full Article',
                  style: t.bodySmall?.copyWith(
                    color: Color(0xFF2F7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

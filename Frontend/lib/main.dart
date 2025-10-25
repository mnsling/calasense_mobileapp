import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Only keep the nav you still use
import 'pages/navigation.dart'; // Main bottom nav (Dashboard / Collection / Scan)

// TODO: for production, move these to a secure config (.env or build-time vars)
const String kSupabaseUrl = 'https://ltmdxtnwsymsimcwqvjm.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0bWR4dG53c3ltc2ltY3dxdmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNjUyODMsImV4cCI6MjA3Mjc0MTI4M30.lS0TPXeykceVVGl-MlazzyliibCV7wvH0Vm4MuCt2FA';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase once (okay even if you’re not using Auth).
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  runApp(const CalaSenseApp());
}

class CalaSenseApp extends StatelessWidget {
  const CalaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalaSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEFFAF2),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // 👉 Start on the animated landing page
      home: const WelcomePage(),
      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/main': (_) => const MainNavPage(),
      },
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// ANIMATED LANDING PAGE (WelcomePage)
/// ─────────────────────────────────────────────────────────────
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  // Phase 1 (entrance)
  late final AnimationController _c;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  // Phase 2 flags
  Alignment _brandAlignment = Alignment.center;
  bool _isCorner = false;
  bool _showTagline = false;
  bool _showImage = false;
  bool _showButton = false;

  // Background (bouncy) & Button (fade) anims
  late final AnimationController _bgCtrl;
  late final Animation<Offset> _bgSlide;
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();

    // Entrance animations
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade  = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6));
    _scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    _c.forward();

    // BG & Button controllers
    _bgCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _bgSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.elasticOut));

    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn);

    // Phase timeline
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _brandAlignment = const Alignment(-0.92, -0.92); // move to top-left
        _isCorner = true;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _showTagline = true);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          setState(() => _showImage = true);
          _bgCtrl.forward();

          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            setState(() => _showButton = true);
            _btnCtrl.forward();
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _bgCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crossAxis = _isCorner ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final nameAlign = _isCorner ? TextAlign.left : TextAlign.center;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            if (_showImage)
              SlideTransition(
                position: _bgSlide,
                child: Transform.translate(
                  offset: const Offset(0, 220),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: double.infinity,
                    child: Image.asset('assets/landingbg.png', fit: BoxFit.cover),
                  ),
                ),
              ),

            AnimatedAlign(
              alignment: _brandAlignment,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Padding(
                      padding: EdgeInsets.only(left: _isCorner ? 16 : 0, top: _isCorner ? 12 : 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: crossAxis,
                        children: [
                          Image.asset('assets/logo.png', width: 96, height: 96),
                          Text(
                            'CalaSense.',
                            textAlign: nameAlign,
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.5,
                            ),
                          ),
                          AnimatedSlide(
                            offset: _showTagline ? Offset.zero : const Offset(0, 0.15),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            child: AnimatedOpacity(
                              opacity: _showTagline ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Scan. Spot. Save Your Crop.',
                                  textAlign: TextAlign.left,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.72),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_showButton)
              Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: _btnFade,
                  child: SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // 👉 Go straight to your app (no auth)
                        Navigator.of(context).pushReplacementNamed('/main');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'GET STARTED',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

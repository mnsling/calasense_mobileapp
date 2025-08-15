import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const CalaSenseApp());

class CalaSenseApp extends StatelessWidget {
  const CalaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CalaSense',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFEFFAF2),
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
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

  // Background & Button anims
  late final AnimationController _bgCtrl;
  late final Animation<Offset> _bgSlide; // bouncy slide
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnFade; // fade-in

  @override
  void initState() {
    super.initState();

    // Entrance
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade  = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6));
    _scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    _c.forward();

    // Background (bouncy) & Button (fade)
    _bgCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _bgSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.elasticOut));

    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn);

    // Phase timing chain
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _brandAlignment = const Alignment(-0.92, -0.92); // top-left
        _isCorner = true;
      });

      // Tagline after travel
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _showTagline = true);

        // Background after 1.5s
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          setState(() => _showImage = true);
          _bgCtrl.forward(); // start bounce

          // Button after 2s
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            setState(() => _showButton = true);
            _btnCtrl.forward(); // start fade
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
    final crossAxis =
    _isCorner ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final nameAlign = _isCorner ? TextAlign.left : TextAlign.center;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background image: bouncy slide-in, shifted down a bit
            if (_showImage)
              SlideTransition(
                position: _bgSlide,
                child: Transform.translate(
                  offset: const Offset(0, 220), // tweak vertical placement
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/landingbg.png', // make sure it's declared in pubspec.yaml
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            // Brand content: entrance center -> glide to corner
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
                      padding: EdgeInsets.only(
                        left: _isCorner ? 16 : 0,
                        top: _isCorner ? 12 : 0,
                      ),
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
                          // Tagline fade/slide (phase 2)
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

            // Button: fades in after bg appears
            if (_showButton)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FadeTransition(
                    opacity: _btnFade,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
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

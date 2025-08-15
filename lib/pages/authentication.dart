import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  bool isLogin = true; // Toggle between Login and Sign Up UI
  bool rememberMe = false; // Checkbox state for "Remember Me"

  // Brand color scheme
  static const Color brand = Color(0xFF2F7D32); // Primary green
  static const Color lightBg = Color(0xFFEFFAF2); // Light background
  static const Color inputBg = Color(0xFFDDEFD9); // Input field background

  // Reusable text field decoration
  InputDecoration _deco(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffix, // Optional suffix (e.g., visibility icon)
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final textTheme = GoogleFonts.poppinsTextTheme(t.textTheme);

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Center( // Centers everything vertically & horizontally
          child: SingleChildScrollView( // Makes content scrollable if needed
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 16),

                // Page Title (changes depending on isLogin)
                Text(
                  isLogin ? 'Welcome to CalaSense' : 'Register',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  isLogin ? 'Login to your account' : 'Create your new account',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // --- FORM FIELDS ---
                TextField(
                  keyboardType: TextInputType.text,
                  decoration: _deco('Enter Username'),
                ),
                const SizedBox(height: 12),

                // Email field (only in Sign Up mode)
                if (!isLogin) ...[
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: _deco('Enter Email'),
                  ),
                  const SizedBox(height: 12),
                ],

                // Password field
                TextField(
                  obscureText: true,
                  decoration: _deco(
                    'Enter Password',
                    suffix: const Icon(Icons.visibility_off),
                  ),
                ),

                // Confirm Password (only in Sign Up mode)
                if (!isLogin) ...[
                  const SizedBox(height: 12),
                  TextField(
                    obscureText: true,
                    decoration: _deco(
                      'Confirm Password',
                      suffix: const Icon(Icons.visibility_off),
                    ),
                  ),
                ],

                // Remember Me + Forgot Password (only in Login mode)
                if (isLogin) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        activeColor: brand,
                        onChanged: (v) =>
                            setState(() => rememberMe = v ?? false),
                      ),
                      Text('Remember Me',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                          )),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot Password',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Primary button (Login / Sign Up)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: Text(
                      isLogin ? 'LOGIN' : 'SIGN UP',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Social login section
                Text(
                  'Or continue with',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _SocialCircle(icon: Icons.apple),
                    SizedBox(width: 14),
                    _SocialCircle(icon: Icons.g_mobiledata), // Google placeholder
                    SizedBox(width: 14),
                    _SocialCircle(icon: Icons.facebook),
                  ],
                ),

                const SizedBox(height: 20),

                // Switch between Login & Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLogin
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin ? 'Sign Up' : 'Login',
                        style: textTheme.bodyMedium?.copyWith(
                          color: brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Social button UI helper ---
class _SocialCircle extends StatelessWidget {
  final IconData icon;
  const _SocialCircle({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: Colors.black87),
    );
  }
}

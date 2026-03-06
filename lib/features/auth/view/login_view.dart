import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../provider/auth_provider.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14), // Deeper Dark
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D1FF).withOpacity(0.05),
                )
              ).animate().fadeOut(duration: 3.seconds, curve: Curves.easeInOut).then().fadeIn(),
          ),
          
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 450,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // New WEZU Logo with Animation
                    Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                    )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .shimmer(duration: 3.seconds, color: Colors.cyanAccent.withOpacity(0.2))
                    .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut)
                    .animate()
                    .scale(begin: const Offset(0.8, 0.8), duration: 800.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 600.ms),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'ADMIN PORTAL',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00D1FF),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    
                    const SizedBox(height: 48),
                    
                    _buildTextField(
                      controller: _emailController,
                      label: 'Administrator Email',
                      hint: 'admin@wezu.com',
                      icon: Icons.alternate_email_rounded,
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.05),
                    
                    const SizedBox(height: 24),
                    
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Security Access Key',
                      hint: '••••••••',
                      icon: Icons.vpn_key_outlined,
                      obscureText: true,
                    ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.05),
                    
                    const SizedBox(height: 12),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot Key?',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                    
                    const SizedBox(height: 32),
                    
                    if (authState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ).animate().shake(),

                    // Advanced Login Button
                    _buildLoginButton(authState),
                  ],
                ),
              ).animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.95, 0.95)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(AuthState authState) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF00D1FF), Color(0xFFADFF2F)], // Cyan to Lime
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D1FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: authState.isLoading
            ? null
            : () {
                ref.read(authProvider.notifier).login(
                      _emailController.text,
                      _passwordController.text,
                    );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: authState.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'AUTHENTICATE ACCESS',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: const Color(0xFF070B14),
                ),
              ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(delay: 2.seconds, duration: 2.seconds, color: Colors.white.withOpacity(0.3))
     .animate()
     .fadeIn(delay: 900.ms).slideY(begin: 0.1);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            color: Colors.white60,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
            prefixIcon: Icon(icon, color: const Color(0xFF00D1FF).withOpacity(0.5), size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF00D1FF), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

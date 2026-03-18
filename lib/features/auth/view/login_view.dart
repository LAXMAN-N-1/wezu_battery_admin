import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../provider/auth_provider.dart';
import '../../../core/widgets/admin_ui_components.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
<<<<<<< HEAD
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D1FF).withValues(alpha: 0.05),
                )
              ).animate().fadeOut(duration: 3.seconds, curve: Curves.easeInOut).then().fadeIn(),
          ),
          
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 450,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
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
                    .shimmer(duration: 3.seconds, color: Colors.cyanAccent.withValues(alpha: 0.2))
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
=======
          // Left Side (60% width) - Branding & Stats
          if (!isMobile)
            Expanded(
              flex: 6,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A0E1A), Color(0xFF1A1F35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Grid Pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: CustomPaint(
                          painter: GridPainter(),
                        ),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const WezuLogo(size: 100),
                          const SizedBox(height: 32),
                          Text(
                            "Powering the Future\nof Mobility",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1),
                          const SizedBox(height: 24),
                          Text(
                            "Energy solutions refined for the next generation of infrastructure.",
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            ),
                          ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideX(begin: -0.1),
                          
                          const SizedBox(height: 64),
                          
                          // Floating Stat Cards
                          const Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: [
                              StatCard(
                                label: "batteries deployed",
                                value: "2,400+",
                                icon: Icons.battery_charging_full_rounded,
                                delay: Duration(milliseconds: 400),
                              ),
                              StatCard(
                                label: "uptime guaranteed",
                                value: "98.2%",
                                icon: Icons.verified_rounded,
                                delay: Duration(milliseconds: 600),
                              ),
                              StatCard(
                                label: "charging stations",
                                value: "150+",
                                icon: Icons.ev_station_rounded,
                                delay: Duration(milliseconds: 800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // Right Side (40% width) - Login Form
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF111827),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMobile) ...[
                          const Center(child: WezuLogo(size: 80, showText: false)),
                          const SizedBox(height: 32),
                        ],
                        
                        Text(
                          "Welcome Back",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          "WEZU Admin Portal",
>>>>>>> origin/main
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 16,
                          ),
<<<<<<< HEAD
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                    
                    const SizedBox(height: 32),
                    
                    if (authState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
=======
                        ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 48),
                        
                        AdminTextField(
                          controller: _emailController,
                          label: "Work Email",
                          hint: "admin@wezu.com",
                          icon: Icons.email_outlined,
                        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 24),
                        
                        AdminTextField(
                          controller: _passwordController,
                          label: "Password",
                          hint: "Enter your password",
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                        ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 16),
                        
                        Row(
>>>>>>> origin/main
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              activeColor: const Color(0xFF3B82F6),
                              side: const BorderSide(color: Colors.white24),
                            ),
                            Text(
                              "Remember me",
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                "Forgot password?",
                                style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontSize: 13),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                        
                        const SizedBox(height: 32),
                        
                        if (authState.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      authState.error!,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().shake(),
                          ),
                        
                        AdminButton(
                          label: "Sign In",
                          isLoading: authState.isLoading,
                          onPressed: () {
                            ref.read(authProvider.notifier).login(
                              _emailController.text,
                              _passwordController.text,
                            );
                          },
                        ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                        
                        const SizedBox(height: 32),
                        
                        Center(
                          child: Text(
                            "© 2024 WEZU Energy Solutions",
                            style: GoogleFonts.inter(color: Colors.white12, fontSize: 11),
                          ),
                        ),
<<<<<<< HEAD
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
            color: const Color(0xFF00D1FF).withValues(alpha: 0.3),
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
=======
                      ],
                    ),
                  ),
>>>>>>> origin/main
                ),
              ),
            ),
          ),
        ],
      ),
<<<<<<< HEAD
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(delay: 2.seconds, duration: 2.seconds, color: Colors.white.withValues(alpha: 0.3))
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
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
            prefixIcon: Icon(icon, color: const Color(0xFF00D1FF).withValues(alpha: 0.5), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF00D1FF), width: 1.5),
            ),
          ),
        ),
      ],
=======
>>>>>>> origin/main
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const double spacing = 40;
    
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

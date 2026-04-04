import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../provider/auth_provider.dart';
import '../../../core/widgets/admin_ui_components.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  static const _rememberCredentialKey = 'remembered_admin_credential';
  static const _rememberToggleKey = 'remember_admin_credential_enabled';
  static const _credentialFieldKey = ValueKey('admin-login-credential-field');
  static const _passwordFieldKey = ValueKey('admin-login-password-field');

  final _formKey = GlobalKey<FormState>();
  final _credentialController = TextEditingController();
  final _passwordController = TextEditingController();
  final _credentialFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _hasSubmitted = false;
  bool _capsLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _hydrateRememberedCredential();
    _refreshCapsLockIndicator();
  }

  @override
  void dispose() {
    _credentialFocusNode.dispose();
    _passwordFocusNode.dispose();
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _credentialValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter your login credential.';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter your password.';
    }
    return null;
  }

  Future<void> _hydrateRememberedCredential() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberToggleKey) ?? false;
    final savedCredential = (prefs.getString(_rememberCredentialKey) ?? '')
        .trim();

    if (!mounted) {
      return;
    }

    setState(() {
      _rememberMe = rememberMe;
      if (rememberMe && savedCredential.isNotEmpty) {
        _credentialController.text = savedCredential;
      }
    });
  }

  Future<void> _syncRememberedCredential(String credential) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_rememberToggleKey, true);
      await prefs.setString(_rememberCredentialKey, credential);
      return;
    }

    await prefs.setBool(_rememberToggleKey, false);
    await prefs.remove(_rememberCredentialKey);
  }

  void _refreshCapsLockIndicator() {
    final nextState = HardwareKeyboard.instance.lockModesEnabled.contains(
      KeyboardLockMode.capsLock,
    );
    if (nextState == _capsLockEnabled || !mounted) {
      return;
    }
    setState(() => _capsLockEnabled = nextState);
  }

  Future<void> _submit(AuthState authState) async {
    if (authState.isLoading) {
      return;
    }

    setState(() => _hasSubmitted = true);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    final credential = _credentialController.text.trim();
    final password = _passwordController.text;

    await ref.read(authProvider.notifier).login(credential, password);
    if (!mounted) {
      return;
    }

    final latestAuthState = ref.read(authProvider);
    if (latestAuthState.isAuthenticated) {
      await _syncRememberedCredential(credential);
      TextInput.finishAutofillContext(shouldSave: true);
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  void _onFieldChanged(String _) {
    if (ref.read(authProvider).error != null) {
      ref.read(authProvider.notifier).clearError();
    }
    _refreshCapsLockIndicator();
    if (_hasSubmitted) {
      _formKey.currentState?.validate();
    }
    setState(() {});
  }

  void _showForgotPasswordHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: Text(
            'Reset Password',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Contact your super admin to reset your password for admin access.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.inter(color: const Color(0xFF3B82F6)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;
    final canSubmit =
        !authState.isLoading &&
        _credentialController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Row(
          children: [
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
                          child: CustomPaint(painter: GridPainter()),
                        ),
                      ),

                      // Content
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 64,
                            vertical: 32,
                          ),
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
                                  )
                                  .animate()
                                  .fadeIn(duration: 800.ms)
                                  .slideX(begin: -0.1),
                              const SizedBox(height: 24),
                              Text(
                                    "Energy solutions refined for the next generation of infrastructure.",
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 800.ms, delay: 200.ms)
                                  .slideX(begin: -0.1),

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 64,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMobile) ...[
                            const Center(
                              child: WezuLogo(size: 80, showText: false),
                            ),
                            const SizedBox(height: 32),
                          ],

                          Text(
                                "Welcome Back",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.1),

                          const SizedBox(height: 8),

                          Text(
                                "WEZU Admin Portal",
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 100.ms)
                              .slideY(begin: 0.1),

                          const SizedBox(height: 48),

                          AutofillGroup(
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _hasSubmitted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              child: Column(
                                children: [
                                  AdminTextField(
                                        textFieldKey: _credentialFieldKey,
                                        controller: _credentialController,
                                        focusNode: _credentialFocusNode,
                                        label: "Login Credential",
                                        hint: "Email / phone / username",
                                        icon: Icons.person_outline,
                                        keyboardType: TextInputType.text,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.username,
                                          AutofillHints.email,
                                        ],
                                        validator: _credentialValidator,
                                        autocorrect: false,
                                        enableSuggestions: true,
                                        textCapitalization:
                                            TextCapitalization.none,
                                        onChanged: _onFieldChanged,
                                        onFieldSubmitted: (_) {
                                          _passwordFocusNode.requestFocus();
                                        },
                                      )
                                      .animate()
                                      .fadeIn(duration: 600.ms, delay: 200.ms)
                                      .slideY(begin: 0.1),

                                  const SizedBox(height: 24),

                                  Focus(
                                        onKeyEvent: (_, __) {
                                          _refreshCapsLockIndicator();
                                          return KeyEventResult.ignored;
                                        },
                                        child: AdminTextField(
                                          textFieldKey: _passwordFieldKey,
                                          controller: _passwordController,
                                          focusNode: _passwordFocusNode,
                                          label: "Password",
                                          hint: "Enter your password",
                                          icon: Icons.lock_outline,
                                          obscureText: _obscurePassword,
                                          keyboardType:
                                              TextInputType.visiblePassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          validator: _passwordValidator,
                                          autocorrect: false,
                                          enableSuggestions: true,
                                          textCapitalization:
                                              TextCapitalization.none,
                                          onChanged: _onFieldChanged,
                                          onFieldSubmitted: (_) =>
                                              _submit(authState),
                                          onToggleObscure: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(duration: 600.ms, delay: 300.ms)
                                      .slideY(begin: 0.1),

                                  if (_capsLockEnabled)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color: Colors.amberAccent,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Caps Lock appears to be on.',
                                              style: GoogleFonts.inter(
                                                color: Colors.amberAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) {
                                          setState(
                                            () => _rememberMe = v ?? false,
                                          );
                                          _syncRememberedCredential(
                                            _credentialController.text.trim(),
                                          );
                                        },
                                        activeColor: const Color(0xFF3B82F6),
                                        side: const BorderSide(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      Text(
                                        "Remember me",
                                        style: GoogleFonts.inter(
                                          color: Colors.white54,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _showForgotPasswordHelp,
                                        child: Text(
                                          "Forgot password?",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF3B82F6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(
                                    duration: 600.ms,
                                    delay: 400.ms,
                                  ),

                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Use your admin credential to continue.',
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          if (authState.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        authState.error!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().shake(),
                            ),

                          AdminButton(
                            label: "Sign In",
                            isLoading: authState.isLoading,
                            onPressed: canSubmit
                                ? () => _submit(authState)
                                : null,
                          ).animate().fadeIn(duration: 600.ms, delay: 500.ms),

                          const SizedBox(height: 32),

                          Center(
                            child: Text(
                              "© 2024 WEZU Energy Solutions",
                              style: GoogleFonts.inter(
                                color: Colors.white12,
                                fontSize: 11,
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
          ],
        ),
      ),
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

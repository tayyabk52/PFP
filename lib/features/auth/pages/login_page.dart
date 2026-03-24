import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.redirect});
  final String? redirect;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  final _repo = AuthRepository();

  bool _loading = false;
  bool _showPassword = false;
  String? _errorMessage;

  /// Reset flow: null = login, 'email' = enter email, 'otp' = enter OTP,
  /// 'newpw' = set new password
  String? _resetStep;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await _repo.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      // Navigate explicitly — the route guards will still enforce
      // role/setup checks and redirect if needed.
      if (mounted) context.go(widget.redirect ?? '/dashboard');
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Forgot password flow ──────────────────────────────────────────────────
  Future<void> _sendResetOtp() async {
    final emailError = AuthRepository.validateEmail(_emailCtrl.text);
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await _repo.sendPasswordResetOtp(email: _emailCtrl.text);
      setState(() => _resetStep = 'otp');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to send reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyResetOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the code from your email.');
      return;
    }
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await _repo.verifyPasswordResetOtp(
        email: _emailCtrl.text,
        token: otp,
      );
      // Session is now established — move to new password step
      setState(() => _resetStep = 'newpw');
    } catch (e) {
      setState(() => _errorMessage = 'Invalid or expired code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitNewPassword() async {
    final newPw = _newPwCtrl.text;
    final confirmPw = _confirmPwCtrl.text;
    final pwError = AuthRepository.validateNewPassword(newPw);
    if (pwError != null) {
      setState(() => _errorMessage = pwError);
      return;
    }
    if (newPw != confirmPw) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await _repo.updatePassword(newPassword: newPw);
      // Password updated + user is now logged in — router will redirect
      setState(() => _resetStep = null);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update password. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _cancelReset() {
    setState(() {
      _resetStep = null;
      _errorMessage = null;
      _otpCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
    });
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Please confirm your email first.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) return _buildDesktopLayout();
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  // ─── Mobile layout ────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero + rounded-top panel overlap using Stack
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _buildHero(height: 360),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 32,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
            child: _buildFormContent(),
          ),
        ],
      ),
    );
  }

  // ─── Desktop layout ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: full-height hero panel
        Expanded(
          flex: 55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.primary),
              Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuARD-Cg2g7YkTJ95FeZa_pfa89XZX1P9J6g1PYj7avWInO8REGERFpLLDymS8yCjm8Ee6prtYgblkC-THzMeXAq5yNYqxb2SgYTulJpgWAS494x0xle_UYbb9riIPfimHSmwxFBTrOVPMZQ2dadnFmPj5ue1v8gqup8XFl75SioWgdIcKFXBnJqgqXL9tTvLCmB33lkuWCySTwYVkXg2OyZ8eMQ3MAmKemkOFdMvHMc1WfoM1ZltYbkIwf-mGKLQW63gRcjJQ4ZnnHv',
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.3),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              // Bottom gradient darkening for text legibility
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x99000000)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 64,
                left: 48,
                right: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTABLISHED 1924',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.0,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The Olfactory\nArchive',
                      style: GoogleFonts.notoSerif(
                        fontSize: 44,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pakistan Fragrance Community',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.55),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Right: form panel
        Expanded(
          flex: 45,
          child: Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 72),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildFormContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Hero (mobile) ────────────────────────────────────────────────────────

  Widget _buildHero({required double height}) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.primary),
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuARD-Cg2g7YkTJ95FeZa_pfa89XZX1P9J6g1PYj7avWInO8REGERFpLLDymS8yCjm8Ee6prtYgblkC-THzMeXAq5yNYqxb2SgYTulJpgWAS494x0xle_UYbb9riIPfimHSmwxFBTrOVPMZQ2dadnFmPj5ue1v8gqup8XFl75SioWgdIcKFXBnJqgqXL9tTvLCmB33lkuWCySTwYVkXg2OyZ8eMQ3MAmKemkOFdMvHMc1WfoM1ZltYbkIwf-mGKLQW63gRcjJQ4ZnnHv',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.3),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Gradient: transparent → surface (for smooth form overlap)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFFF9F9FC)],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          // Branding
          Positioned(
            bottom: 48,
            left: 28,
            right: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTABLISHED 1924',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                    color: const Color(0xFF002117).withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The Olfactory Archive',
                  style: GoogleFonts.notoSerif(
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF002117),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared form content ──────────────────────────────────────────────────

  Widget _buildFormContent() {
    // Show forgot-password flow if active
    if (_resetStep != null) return _buildResetFlow();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.notoSerif(
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: AppColors.onBackground,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your credentials to access your personal fragrance vault.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 40),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: 'Email Address',
                hint: 'curator@olfactory.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: AuthRepository.validateEmail,
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                validator: AuthRepository.validatePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _resetStep = 'email';
                      _errorMessage = null;
                    }),
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.error,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              _AuthCTAButton(
                label: 'Sign In',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'New to the archive?',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: Text(
                'Create Account',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(height: 1, color: AppColors.surfaceContainerLow),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => context.go('/register/seller-apply'),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seller Application',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'List your collection for the community',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.storefront_outlined,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 56),
        Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user,
                    size: 14, color: AppColors.goldAccent),
                const SizedBox(width: 6),
                Text(
                  'SECURE END-TO-END ENCRYPTION',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'By signing in, you agree to our Terms of Curation and Privacy Policy.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.7,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Forgot password flow UI ─────────────────────────────────────────────

  Widget _buildResetFlow() {
    final String title;
    final String subtitle;
    final List<Widget> fields;
    final String buttonLabel;
    final VoidCallback onSubmit;

    switch (_resetStep) {
      case 'email':
        title = 'Reset Password';
        subtitle = 'Enter your email and we\'ll send you a verification code.';
        fields = [
          AuthTextField(
            label: 'Email Address',
            hint: 'curator@olfactory.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: AuthRepository.validateEmail,
          ),
        ];
        buttonLabel = 'Send Code';
        onSubmit = _sendResetOtp;
      case 'otp':
        title = 'Enter Code';
        subtitle =
            'A 6-digit code has been sent to ${_emailCtrl.text.trim()}.';
        fields = [
          AuthTextField(
            label: 'Verification Code',
            hint: '123456',
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
        ];
        buttonLabel = 'Verify Code';
        onSubmit = _verifyResetOtp;
      case 'newpw':
        title = 'New Password';
        subtitle = 'Set your new password.';
        fields = [
          AuthTextField(
            label: 'New Password',
            hint: '••••••••',
            controller: _newPwCtrl,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: AuthRepository.validateNewPassword,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            label: 'Confirm Password',
            hint: '••••••••',
            controller: _confirmPwCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),
        ];
        buttonLabel = 'Update Password';
        onSubmit = _submitNewPassword;
      default:
        return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSerif(
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: AppColors.onBackground,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 40),
        ...fields,
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.error,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 32),
        _AuthCTAButton(
          label: buttonLabel,
          loading: _loading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _cancelReset,
            child: Text(
              'Back to Sign In',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared CTA button ────────────────────────────────────────────────────────

class _AuthCTAButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _AuthCTAButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }
}

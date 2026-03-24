import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pakistan_city_field.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/auth_repository.dart';
import '../providers/profile_provider.dart';
import 'widgets/auth_text_field.dart';

enum _RegisterStep { form, otp, role }

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  _RegisterStep _step = _RegisterStep.form;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _selectedCity;
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;

  final _otpCtrl = TextEditingController();

  final _repo = AuthRepository();
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // If the user is already authenticated (e.g. redirected here because
    // profile_setup_complete = false), skip straight to role selection.
    if (supabase.auth.currentUser != null) {
      _step = _RegisterStep.role;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // Step 1: Sign Up
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await _repo.signUp(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        displayName: _nameCtrl.text,
      );
      setState(() => _step = _RegisterStep.otp);
    } catch (e) {
      setState(() => _errorMessage = _friendlySignUpError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlySignUpError(String raw) {
    if (raw.contains('already registered') || raw.contains('already exists')) {
      return 'This email is already registered. Try logging in.';
    }
    if (raw.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment.';
    }
    return 'Could not create account. Please try again.';
  }

  // Step 2: Verify OTP
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Enter the verification code from your email.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // OTP verification — fail hard on error (wrong/expired code)
    try {
      await _repo.verifySignUpOtp(
        email: _emailCtrl.text,
        token: otp,
      );
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _errorMessage = _friendlyOtpError(e.toString());
      });
      return;
    }

    // Profile update — best-effort; trigger already created the row
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        await _repo.upsertProfile(
          userId: user.id,
          displayName: _nameCtrl.text,
          email: _emailCtrl.text,
          phone: AuthRepository.normalizePhone(_phoneCtrl.text),
          city: _selectedCity,
        );
      } catch (_) {
        // Profile fields can be filled in later; don't block role selection
      }
    }

    if (mounted) setState(() {
      _loading = false;
      _step = _RegisterStep.role;
    });
  }

  String _friendlyOtpError(String raw) {
    if (raw.contains('Token has expired') || raw.contains('expired')) {
      return 'Code has expired. Please go back and try again.';
    }
    if (raw.contains('invalid') || raw.contains('Invalid')) {
      return 'Incorrect code. Please check your email and try again.';
    }
    return 'Verification failed. Please try again.';
  }

  Future<void> _resendOtp() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await _repo.resendSignUpOtp(email: _emailCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'New code sent to your email.',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.primaryGradientEnd,
          ),
        );
      }
    } catch (_) {
      setState(
          () => _errorMessage = 'Could not resend code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Step 3: Role selection
  Future<void> _selectRole(bool isSeller) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Session lost');
      if (isSeller) {
        if (mounted) context.go('/register/seller-apply');
      } else {
        await _repo.completeProfileSetup(user.id);
        // Invalidate the cached provider so the router sees the updated value
        // before we navigate — otherwise the redirect guard sends us back here.
        ref.invalidate(profileSetupCompleteProvider);
        await ref.read(profileSetupCompleteProvider.future);
        if (mounted) context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // If on OTP or role step, go back one step
        if (_step == _RegisterStep.otp) {
          setState(() => _step = _RegisterStep.form);
        } else if (_step == _RegisterStep.form) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
        // Role step: user is authenticated, don't go back to form
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
          // Hero + glass panel overlap: Positioned white panel sits at hero bottom
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _buildHero(height: 400),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 96,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 48),
            child: _buildStepContent(),
          ),
        ],
      ),
    );
  }

  // ─── Desktop layout ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: full-height hero
        Expanded(
          flex: 55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.primary),
              Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuC7mlvHeRf_wUAUtgetW9mePUjGeNbls6MM0vRriVGPn3P5JTfYxCvFmGkkenMgARSJgvzSTL0B1j0V_z_a4MEACtXwAAr7zIeNfZBFmxfK9znQxbThhuXxe-jkKiUpXrEihGyV1fxe_zJWRRWJ_srkuQIgdB-xcmksJUKBozbJAHnAzmcQVX1KFaPkNMbp5hqxLsI7PI6ac-Ppd5s2rX4crjg-OwQW2JOz-pgsE5NdU4vdoNUxwxjeUBS_N22IC9CMmyLSelmdRX_9',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.55),
                      AppColors.primary.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              // Branding centered
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PFC',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4.0,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The Olfactory Archive',
                        style: GoogleFonts.notoSerif(
                          fontSize: 40,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 40,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Join our curated guild of\nfragrance historians and enthusiasts.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.7,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
                child: _buildStepContent(),
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
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC7mlvHeRf_wUAUtgetW9mePUjGeNbls6MM0vRriVGPn3P5JTfYxCvFmGkkenMgARSJgvzSTL0B1j0V_z_a4MEACtXwAAr7zIeNfZBFmxfK9znQxbThhuXxe-jkKiUpXrEihGyV1fxe_zJWRRWJ_srkuQIgdB-xcmksJUKBozbJAHnAzmcQVX1KFaPkNMbp5hqxLsI7PI6ac-Ppd5s2rX4crjg-OwQW2JOz-pgsE5NdU4vdoNUxwxjeUBS_N22IC9CMmyLSelmdRX_9',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Gradient: emerald-tinted top → light surface bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.4),
                  const Color(0xFFF9F9FC),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          // Branding at top-center
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'PFC',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The Olfactory Archive',
                  style: GoogleFonts.notoSerif(
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step routing ─────────────────────────────────────────────────────────

  Widget _buildStepContent() {
    return switch (_step) {
      _RegisterStep.form => _buildFormStep(),
      _RegisterStep.otp => _buildOtpStep(),
      _RegisterStep.role => _buildRoleStep(),
    };
  }

  // ─── Step 1: Registration form ────────────────────────────────────────────

  Widget _buildFormStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create Your Entry',
          style: GoogleFonts.notoSerif(
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: AppColors.onBackground,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join our curated guild of fragrance historians and enthusiasts.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 36),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: 'Display Name',
                hint: 'e.g. Julian S.',
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                validator: AuthRepository.validateDisplayName,
              ),
              const SizedBox(height: 28),
              PakistanCityField(
                label: 'CITY OF RESIDENCE',
                initialValue: null,
                onChanged: (v) => setState(() => _selectedCity = v),
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Phone Number',
                hint: '03001234567',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixWidget: Text(
                  '+92 ',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                validator: (v) => AuthRepository.validatePhone(
                    AuthRepository.normalizePhone(v)),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                ],
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Email Address',
                hint: 'archivist@pfc.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: AuthRepository.validateEmail,
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Password',
                hint: 'Minimum 8 characters',
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Confirm Password',
                hint: '••••••••',
                controller: _confirmCtrl,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
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
              const SizedBox(height: 36),
              _RegCTAButton(
                label: 'Join the Archive',
                loading: _loading,
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Heritage Authenticated badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 14, color: AppColors.goldAccent),
                const SizedBox(width: 6),
                Text(
                  'HERITAGE AUTHENTICATED',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: const Color(0xFF5d4201),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already a member? ',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text(
                'Sign in',
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
        const SizedBox(height: 28),
        Text(
          'By entering the archive, you agree to the preservation of olfactory data and the ethical documentation of fragrance heritage.',
          style: GoogleFonts.notoSerif(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: AppColors.textMuted,
            height: 1.7,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Step 2: OTP Verification ─────────────────────────────────────────────

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Check Your Email',
          style: GoogleFonts.notoSerif(
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: AppColors.onBackground,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary, height: 1.65),
            children: [
              const TextSpan(text: 'A verification code was sent to '),
              TextSpan(
                text: _emailCtrl.text,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        AuthTextField(
          label: 'Verification Code',
          hint: '000000',
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 8,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.error, height: 1.5),
          ),
        ],
        const SizedBox(height: 36),
        _RegCTAButton(
          label: 'Verify Code',
          loading: _loading,
          onPressed: _verifyOtp,
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive a code? ",
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: _loading ? null : _resendOtp,
              child: Text(
                'Resend',
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
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => setState(() {
            _step = _RegisterStep.form;
            _errorMessage = null;
          }),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text(
            'Back',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ─── Step 3: Role selection ───────────────────────────────────────────────

  Widget _buildRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome to the Archive',
          style: GoogleFonts.notoSerif(
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: AppColors.onBackground,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How will you engage with the community?',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary, height: 1.65),
        ),
        const SizedBox(height: 40),
        _RoleCard(
          title: 'Member',
          description:
              'Browse listings, submit reviews, message sellers, and report scams.',
          icon: Icons.person_outline_rounded,
          onTap: _loading ? null : () => _selectRole(false),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          title: 'Seller',
          description:
              'Everything a member can do, plus list fragrances for sale. Requires ID verification.',
          icon: Icons.storefront_outlined,
          onTap: _loading ? null : () => _selectRole(true),
          accent: true,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.error, height: 1.5),
          ),
        ],
        if (_loading) ...[
          const SizedBox(height: 24),
          const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ],
    );
  }
}

// ─── Role card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final bool accent;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.surfaceContainerLow,
          border: accent
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSerif(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                size: 13, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Register CTA button ──────────────────────────────────────────────────────

class _RegCTAButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _RegCTAButton({
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
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_text_field.dart';

enum _RegisterStep { form, otp, role }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  _RegisterStep _step = _RegisterStep.form;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
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
    setState(() { _loading = true; _errorMessage = null; });
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
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code from your email.');
      return;
    }
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await _repo.verifySignUpOtp(
        email: _emailCtrl.text,
        token: otp,
      );
      final user = supabase.auth.currentUser;
      if (user != null) {
        final normalizedPhone = AuthRepository.normalizePhone(_phoneCtrl.text);
        await _repo.upsertProfile(
          userId: user.id,
          displayName: _nameCtrl.text,
          email: _emailCtrl.text,
          phone: normalizedPhone,
        );
      }
      setState(() => _step = _RegisterStep.role);
    } catch (e) {
      setState(() => _errorMessage = _friendlyOtpError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await _repo.resendSignUpOtp(email: _emailCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New code sent to your email.')),
        );
      }
    } catch (_) {
      setState(() => _errorMessage = 'Could not resend code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Step 3: Role selection
  Future<void> _selectRole(bool isSeller) async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Session lost');
      if (isSeller) {
        if (mounted) context.go('/register/seller-apply');
      } else {
        await _repo.completeProfileSetup(user.id);
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
    return switch (_step) {
      _RegisterStep.form => _buildFormStep(),
      _RegisterStep.otp => _buildOtpStep(),
      _RegisterStep.role => _buildRoleStep(),
    };
  }

  Widget _buildFormStep() {
    return AuthCard(
      title: 'Create account',
      subtitle: 'Join Pakistan Fragrance Community',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'Display Name',
              hint: 'Your name as shown on PFC',
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              validator: AuthRepository.validateDisplayName,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Email',
              hint: 'you@example.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: AuthRepository.validateEmail,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Phone (Optional)',
              hint: '+923001234567',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) => AuthRepository.validatePhone(
                  AuthRepository.normalizePhone(v)),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Confirm Password',
              hint: '••••••••',
              controller: _confirmCtrl,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.error),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            _RegPrimaryButton(
              label: 'Continue',
              loading: _loading,
              onPressed: _submitForm,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text('Sign in',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpStep() {
    return AuthCard(
      title: 'Check your email',
      subtitle: 'Enter the 6-digit code sent to ${_emailCtrl.text}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            label: 'Verification Code',
            hint: '000000',
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          _RegPrimaryButton(
            label: 'Verify',
            loading: _loading,
            onPressed: _verifyOtp,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Didn't receive a code? ",
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textSecondary)),
              GestureDetector(
                onTap: _loading ? null : _resendOtp,
                child: Text('Resend',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                setState(() { _step = _RegisterStep.form; _errorMessage = null; }),
            child: Text('← Back',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleStep() {
    return AuthCard(
      title: 'How will you use PFC?',
      subtitle: 'You can change this later from your profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoleOption(
            title: 'Member',
            description:
                'Browse listings, submit reviews, message sellers, and report scams.',
            icon: Icons.person_outline,
            onTap: _loading ? null : () => _selectRole(false),
          ),
          const SizedBox(height: 12),
          _RoleOption(
            title: 'Seller',
            description:
                'Everything a member can do, plus list fragrances for sale. Requires ID verification.',
            icon: Icons.storefront_outlined,
            onTap: _loading ? null : () => _selectRole(true),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                textAlign: TextAlign.center),
          ],
          if (_loading) ...[
            const SizedBox(height: 16),
            const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ],
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  const _RoleOption({
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMd),
                  const SizedBox(height: 4),
                  Text(description,
                      style: AppTextStyles.bodySm, maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _RegPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _RegPrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pakistan_city_field.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nonceController = TextEditingController();

  String? _selectedCity;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isChangingPassword = false;
  bool _showPasswordSection = false;
  bool _needsReauth = false;

  String? _avatarUrl;

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nonceController.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic>? profile) {
    if (profile == null) return;
    _displayNameController.text = profile['display_name'] as String? ?? '';
    _phoneController.text = profile['phone_number'] as String? ?? '';
    _selectedCity = profile['city'] as String?;
    _avatarUrl = profile['avatar_url'] as String?;
  }

  // ── Avatar pick + upload ──────────────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
    );
    if (file == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await AuthRepository().uploadAvatar(
        userId: user.id,
        bytes: bytes,
      );
      setState(() => _avatarUrl = url);
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar updated', style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: AppColors.primaryGradientEnd,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar: $e',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ── Save profile ─────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final normalizedPhone =
          AuthRepository.normalizePhone(_phoneController.text);

      await AuthRepository().upsertProfile(
        userId: user.id,
        displayName: _displayNameController.text,
        email: user.email ?? '',
        phone: normalizedPhone,
        city: _selectedCity ?? '',
      );

      ref.invalidate(currentProfileProvider);
      ref.invalidate(userRoleProvider);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Profile saved', style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: AppColors.primaryGradientEnd,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Change password ───────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    final validationError = AuthRepository.validateNewPassword(newPw);
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    if (newPw != confirmPw) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      if (_needsReauth) {
        // Second attempt — use the nonce/OTP from email
        final nonce = _nonceController.text.trim();
        if (nonce.isEmpty) {
          _showError('Please enter the verification code from your email');
          return;
        }
        await AuthRepository().updatePasswordWithNonce(
          newPassword: newPw,
          nonce: nonce,
        );
      } else {
        await AuthRepository().updatePassword(newPassword: newPw);
      }

      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _nonceController.clear();
      if (mounted) {
        setState(() {
          _showPasswordSection = false;
          _needsReauth = false;
        });
        _showSuccess('Password updated');
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('reauthentication') || msg.contains('reauth')) {
        // "Secure password change" is enabled and session is old.
        // Send a reauthentication OTP and ask user to enter it.
        try {
          await AuthRepository().reauthenticate();
          if (mounted) {
            setState(() => _needsReauth = true);
            _showSuccess(
                'Verification code sent to your email. Enter it below.');
          }
        } catch (reAuthErr) {
          if (mounted) _showError('Failed to send verification: $reAuthErr');
        }
      } else {
        if (mounted) {
          _showError(_friendlyPasswordError(e.toString()));
        }
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  String _friendlyPasswordError(String raw) {
    if (raw.contains('same_password')) {
      return 'New password must be different from your current password.';
    }
    if (raw.contains('weak_password') || raw.contains('WeakPassword')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    return 'Failed to update password. Please try again.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: AppColors.primaryGradientEnd,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, __) => Center(
              child: Text('Error loading profile',
                  style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
            data: (profile) {
              // Populate controllers once when data arrives (not while editing)
              if (!_isEditing && !_isSaving) {
                _populateFields(profile);
              }
              return _buildContent(context, profile);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic>? profile) {
    final displayName = profile?['display_name'] as String? ?? 'User';
    final email = profile?['email_address'] as String? ?? '';
    final role = profile?['role'] as String? ?? 'member';
    final pfcCode = profile?['pfc_seller_code'] as String?;
    final isSeller = role == 'seller';
    final avatarUrl = _avatarUrl ?? profile?['avatar_url'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Avatar + name header ────────────────────────────────────
                Row(
                  children: [
                    _buildAvatar(displayName, avatarUrl),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.notoSerif(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                color: isSeller
                                    ? AppColors.primary
                                    : AppColors.surfaceContainerLow,
                                child: Text(
                                  role.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: isSeller
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (pfcCode != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  color: AppColors.primary,
                                  child: Text(
                                    pfcCode,
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Email (read-only) ───────────────────────────────────────
                _sectionLabel('EMAIL'),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: AppColors.surfaceContainerLow,
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Icon(Icons.lock_outline,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Transactions (read-only, sellers/admins only) ────────────
                if (role == 'seller' || role == 'admin') ...[
                  _sectionLabel('TRANSACTIONS'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    color: AppColors.surfaceContainerLow,
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz_outlined,
                            size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 12),
                        Text(
                          '${profile?['transaction_count'] ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Edit / View toggle ──────────────────────────────────────
                if (!_isEditing) ...[
                  // Read-only info rows
                  _readOnlyRow('Display Name', displayName, Icons.person_outlined),
                  if (_phoneController.text.isNotEmpty)
                    _readOnlyRow('Phone', _phoneController.text, Icons.phone_outlined),
                  if ((_selectedCity ?? '').isNotEmpty)
                    _readOnlyRow('City', _selectedCity!, Icons.location_on_outlined),

                  const SizedBox(height: 16),

                  // Edit profile button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.surfaceContainerLow,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Profile',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // ── Editable fields ─────────────────────────────────────
                  _sectionLabel('DISPLAY NAME'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _displayNameController,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.onBackground),
                    validator: AuthRepository.validateDisplayName,
                    decoration: _fieldDecoration('Your display name'),
                  ),

                  const SizedBox(height: 16),

                  _sectionLabel('PHONE NUMBER'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.onBackground),
                    keyboardType: TextInputType.phone,
                    validator: AuthRepository.validatePhone,
                    decoration:
                        _fieldDecoration('+923001234567 or 03001234567'),
                  ),

                  const SizedBox(height: 16),

                  PakistanCityField(
                    initialValue: _selectedCity,
                    onChanged: (v) => setState(() => _selectedCity = v),
                  ),

                  const SizedBox(height: 24),

                  // Save / Cancel buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    _populateFields(ref
                                        .read(currentProfileProvider)
                                        .valueOrNull);
                                    setState(() => _isEditing = false);
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // ── Change Password section ─────────────────────────────────
                GestureDetector(
                  onTap: () =>
                      setState(() => _showPasswordSection = !_showPasswordSection),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surfaceContainerLow,
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Change Password',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Update your account password',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _showPasswordSection
                              ? Icons.expand_less
                              : Icons.chevron_right,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showPasswordSection) ...[
                  const SizedBox(height: 16),
                  _sectionLabel('NEW PASSWORD'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.onBackground),
                    decoration: _fieldDecoration('Min 8 characters'),
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel('CONFIRM PASSWORD'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.onBackground),
                    decoration: _fieldDecoration('Re-enter new password'),
                  ),
                  if (_needsReauth) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: AppColors.goldAccent.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A verification code was sent to your email.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionLabel('VERIFICATION CODE'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nonceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.onBackground),
                      decoration: _fieldDecoration('Enter code from email'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isChangingPassword ? null : _changePassword,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      ),
                      child: _isChangingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _needsReauth
                                  ? 'Verify & Update Password'
                                  : 'Update Password',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Refresh profile ─────────────────────────────────────────
                _actionTile(
                  'Refresh Profile',
                  'Reload your profile data',
                  Icons.refresh_rounded,
                  () {
                    ref.invalidate(currentProfileProvider);
                    ref.invalidate(userRoleProvider);
                    ref.invalidate(sellerApplicationProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Profile refreshed',
                            style: GoogleFonts.inter(fontSize: 13)),
                        backgroundColor: AppColors.primaryGradientEnd,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ── Sign out ────────────────────────────────────────────────
                _actionTile(
                  'Sign Out',
                  'Leave the Archive',
                  Icons.logout_rounded,
                  () async {
                    await AuthRepository().signOut();
                    // Clear all cached provider state so the router sees
                    // unauthenticated immediately.
                    ref.invalidate(currentProfileProvider);
                    ref.invalidate(userRoleProvider);
                    ref.invalidate(sellerApplicationProvider);
                    if (mounted) context.go('/');
                  },
                  isDestructive: true,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ──────────────────────────────────────────────────────────

  Widget _buildAvatar(String displayName, String? avatarUrl) {
    return GestureDetector(
      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(36),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    width: 72,
                    height: 72,
                    placeholder: (_, __) => Center(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.notoSerif(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.notoSerif(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.notoSerif(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(13),
              ),
              child: _isUploadingAvatar
                  ? const Padding(
                      padding: EdgeInsets.all(5),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.camera_alt,
                      size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.surfaceContainerLow,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
      );

  Widget _actionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isDestructive
            ? AppColors.error.withValues(alpha: 0.04)
            : AppColors.surfaceContainerLow,
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isDestructive ? AppColors.error : AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? AppColors.error
                          : AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 16,
                color:
                    isDestructive ? AppColors.error : AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

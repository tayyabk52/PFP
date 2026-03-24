import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/profile_provider.dart';
import '../data/seller_apply_repository.dart';
import '../../auth/pages/widgets/auth_text_field.dart';
import '../../../core/widgets/pakistan_city_field.dart';

const _sellerTypeOptions = ['Decants', 'Full Bottles', 'Vintages', 'Samples'];

class SellerApplyPage extends ConsumerStatefulWidget {
  const SellerApplyPage({super.key});

  @override
  ConsumerState<SellerApplyPage> createState() => _SellerApplyPageState();
}

class _SellerApplyPageState extends ConsumerState<SellerApplyPage> {
  final _formKey = GlobalKey<FormState>();

  // Identity
  final _legalNameCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedCity;

  // Facebook
  final _fbIdCtrl = TextEditingController();
  final _fbUrlCtrl = TextEditingController();

  // State
  final Set<String> _selectedTypes = {};
  bool _isExistingFbSeller = false;
  Uint8List? _cnicFrontBytes;
  Uint8List? _cnicBackBytes;
  String? _cnicFrontName;
  String? _cnicBackName;

  bool _loading = false;
  String? _errorMessage;

  final _repo = SellerApplyRepository();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  void _prefillFromProfile() {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;

    final name = profile['display_name'] as String?;
    final phone = profile['phone_number'] as String?;
    final city = profile['city'] as String?;

    if (name != null && name.isNotEmpty) _legalNameCtrl.text = name;
    if (phone != null && phone.isNotEmpty) {
      // Strip +92 prefix if present for the form field
      final cleaned = phone.replaceFirst(RegExp(r'^\+?92'), '');
      _phoneCtrl.text = cleaned;
    }
    if (city != null && city.isNotEmpty) _selectedCity = city;
  }

  @override
  void dispose() {
    _legalNameCtrl.dispose();
    _cnicCtrl.dispose();
    _phoneCtrl.dispose();
    _fbIdCtrl.dispose();
    _fbUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        if (isFront) {
          _cnicFrontBytes = bytes;
          _cnicFrontName = picked.name;
        } else {
          _cnicBackBytes = bytes;
          _cnicBackName = picked.name;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access gallery.')),
        );
      }
    }
  }

  String? _validateCnic(String? v) {
    if (v == null || v.trim().isEmpty) return 'CNIC is required';
    final clean = v.replaceAll('-', '');
    if (clean.length != 13 || !RegExp(r'^\d{13}$').hasMatch(clean)) {
      return 'Enter CNIC as XXXXX-XXXXXXX-X';
    }
    return null;
  }

  Future<void> _submit() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Validate seller types
    if (_selectedTypes.isEmpty) {
      setState(
          () => _errorMessage = 'Please select at least one seller category.');
      return;
    }

    // Validate CNIC images
    if (_cnicFrontBytes == null) {
      setState(() => _errorMessage = 'Please upload the front of your CNIC.');
      return;
    }
    if (_cnicBackBytes == null) {
      setState(() => _errorMessage = 'Please upload the back of your CNIC.');
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _errorMessage = 'Session expired. Please sign in again.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Upload CNIC images
      final frontPath = await _repo.uploadCnicImage(
        userId: user.id,
        imageBytes: _cnicFrontBytes!,
        side: 'front',
      );
      final backPath = await _repo.uploadCnicImage(
        userId: user.id,
        imageBytes: _cnicBackBytes!,
        side: 'back',
      );

      // Normalize phone
      final phone = AuthRepository.normalizePhone(_phoneCtrl.text) ??
          _phoneCtrl.text.trim();

      await _repo.submitApplication(
        applicantId: user.id,
        fullLegalName: _legalNameCtrl.text,
        cnicNumber: _cnicCtrl.text,
        cnicFrontUrl: frontPath,
        cnicBackUrl: backPath,
        phoneNumber: phone,
        city: _selectedCity ?? '',
        sellerTypes: _selectedTypes.toList(),
        isExistingFbSeller: _isExistingFbSeller,
        fbSellerId: _isExistingFbSeller ? _fbIdCtrl.text : null,
        fbProfileUrl: _isExistingFbSeller ? _fbUrlCtrl.text : null,
      );

      // Mark profile setup complete so the route guard allows /dashboard routes
      await AuthRepository().completeProfileSetup(user.id);

      // Invalidate stale provider caches so the router re-evaluates with
      // fresh values (profileSetupComplete=true, application exists).
      ref.invalidate(profileSetupCompleteProvider);
      ref.invalidate(sellerApplicationProvider);

      if (mounted) context.go('/dashboard/verification');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('duplicate')
            ? 'You already have a pending application.'
            : 'Submission failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      final profile = ref.read(currentProfileProvider).valueOrNull;
      final setupDone = profile?['profile_setup_complete'] == true;
      if (!setupDone) {
        context.go('/register');
      } else if (ref.read(hasSellerApplicationProvider)) {
        context.go('/dashboard/verification');
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigateBack();
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: _navigateBack,
        ),
        title: Text(
          'THE OLFACTORY ARCHIVE',
          style: GoogleFonts.notoSerif(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 48),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIdentitySection(),
                        const SizedBox(height: 40),
                        _buildPortfolioSection(),
                        const SizedBox(height: 40),
                        _buildVisualProofSection(),
                        const SizedBox(height: 40),
                        _buildFacebookSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      color: AppColors.errorContainer,
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATOR ACCESSION',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final titleSize = constraints.maxWidth > 600 ? 48.0 : 32.0;
            return Text(
              'Seller Application',
              style: GoogleFonts.notoSerif(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.1,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Join our esteemed circle of verified fragrance custodians. Our application process ensures that every decant and bottle within the Archive maintains the highest standards of authenticity and provenance.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  // ─── Section 1: Identity ──────────────────────────────────────────────────

  Widget _buildIdentitySection() {
    return _SectionCard(
      title: 'Identity & Contact',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoCol = constraints.maxWidth > 560;
          final fields = [
            AuthTextField(
              label: 'Full Legal Name',
              hint: 'As per Identity Document',
              controller: _legalNameCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 3) return 'Enter full legal name';
                return null;
              },
            ),
            AuthTextField(
              label: 'CNIC Number',
              hint: '00000-0000000-0',
              controller: _cnicCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: _validateCnic,
              inputFormatters: [_CnicFormatter()],
            ),
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
                    color: AppColors.textSecondary),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
              ],
              validator: (v) => AuthRepository.validatePhone(
                  AuthRepository.normalizePhone(v)),
            ),
          ];

          final cityField = PakistanCityField(
            initialValue: _selectedCity,
            onChanged: (v) => setState(() => _selectedCity = v),
            required: true,
          );

          if (twoCol) {
            return Column(
              children: [
                _twoColRow(fields[0], fields[1]),   // Full Legal Name + CNIC Number
                const SizedBox(height: 28),
                fields[2],                           // Phone Number — full-width
                const SizedBox(height: 28),
                cityField,                           // always full-width
              ],
            );
          }
          return Column(
            children: [
              ...fields.expand((f) => [f, const SizedBox(height: 28)]),
              cityField,
            ],
          );
        },
      ),
    );
  }

  Widget _twoColRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 24),
        Expanded(child: right),
      ],
    );
  }

  // ─── Section 2: Portfolio ─────────────────────────────────────────────────

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Portfolio Selection'),
        const SizedBox(height: 8),
        Text(
          'Select the categories you intend to list within the Archive.',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 480 ? 4 : 2;
            const spacing = 12.0;
            final itemWidth =
                (constraints.maxWidth - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: _sellerTypeOptions.map((type) {
                final selected = _selectedTypes.contains(type);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedTypes.remove(type);
                    } else {
                      _selectedTypes.add(type);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: itemWidth,
                    height: 88,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconForType(type),
                          size: 24,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'Decants' => Icons.science_outlined,
      'Full Bottles' => Icons.local_bar_outlined,
      'Vintages' => Icons.history_edu_outlined,
      'Samples' => Icons.auto_awesome_outlined,
      _ => Icons.inventory_2_outlined,
    };
  }

  // ─── Section 3: Visual Proof ──────────────────────────────────────────────

  Widget _buildVisualProofSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      color: AppColors.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Visual Proof'),
          const SizedBox(height: 4),
          Text(
            'Authenticated documents are required for vault access.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth > 480;
              final front = _CnicUploadTile(
                label: 'CNIC Front',
                icon: Icons.badge_outlined,
                imageBytes: _cnicFrontBytes,
                fileName: _cnicFrontName,
                onTap: () => _pickImage(true),
              );
              final back = _CnicUploadTile(
                label: 'CNIC Back',
                icon: Icons.flip_outlined,
                imageBytes: _cnicBackBytes,
                fileName: _cnicBackName,
                onTap: () => _pickImage(false),
              );
              if (twoCol) {
                return Row(
                  children: [
                    Expanded(child: front),
                    const SizedBox(width: 16),
                    Expanded(child: back),
                  ],
                );
              }
              return Column(
                children: [
                  front,
                  const SizedBox(height: 16),
                  back,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF5a4000).withValues(alpha: 0.06),
              border: Border.all(
                  color: const Color(0xFF5a4000).withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.security,
                    size: 16, color: Color(0xFF5d4201)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF5d4201),
                          height: 1.6),
                      children: const [
                        TextSpan(
                          text: 'SECURITY DISCLAIMER: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              'Your CNIC data is handled with extreme confidentiality and is purged from our active records immediately after verification is completed.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 4: Facebook Presence ────────────────────────────────────────

  Widget _buildFacebookSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionLabel('Facebook Presence')),
              Text(
                'EXISTING SELLER',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: _isExistingFbSeller,
                activeThumbColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _isExistingFbSeller = v),
              ),
            ],
          ),
          if (_isExistingFbSeller) ...[
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth > 480;
                final fbId = AuthTextField(
                  label: 'FB Seller ID',
                  hint: 'Unique Identifier',
                  controller: _fbIdCtrl,
                  textInputAction: TextInputAction.next,
                );
                final fbUrl = AuthTextField(
                  label: 'FB Profile URL',
                  hint: 'facebook.com/username',
                  controller: _fbUrlCtrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                );
                if (twoCol) {
                  return _twoColRow(fbId, fbUrl);
                }
                return Column(
                  children: [
                    fbId,
                    const SizedBox(height: 28),
                    fbUrl,
                  ],
                );
              },
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Toggle on if you are currently an established seller on Facebook Groups.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.verified_user_outlined, size: 18),
            label: Text(
              'SUBMIT FOR VERIFICATION',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'TYPICAL REVIEW TIME: 48–72 HOURS',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── CNIC Upload Tile ─────────────────────────────────────────────────────────

class _CnicUploadTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Uint8List? imageBytes;
  final String? fileName;
  final VoidCallback onTap;

  const _CnicUploadTile({
    required this.label,
    required this.icon,
    required this.imageBytes,
    required this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(
              color: imageBytes != null
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.ghostBorderBase.withValues(alpha: 0.35),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: imageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(imageBytes!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: AppColors.primary.withValues(alpha: 0.75),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                fileName ?? label,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 32, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to upload',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Section helpers ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(title),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSerif(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      ),
    );
  }
}

// ─── CNIC auto-formatter ──────────────────────────────────────────────────────

class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 13) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

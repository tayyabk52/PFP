import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/pages/widgets/auth_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/iso_model.dart';
import '../providers/iso_provider.dart';

class IsoCreatePage extends ConsumerStatefulWidget {
  const IsoCreatePage({super.key, this.existingIsoId});

  final String? existingIsoId;

  @override
  ConsumerState<IsoCreatePage> createState() => _IsoCreatePageState();
}

class _IsoCreatePageState extends ConsumerState<IsoCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _fragranceCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _sizeMlCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  late final bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.existingIsoId != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user == null) {
        context.go('/login?redirect=/iso/create');
        return;
      }
      if (_isEditMode) {
        _loadExisting();
      }
    });
  }

  Future<void> _loadExisting() async {
    final iso =
        await ref.read(isoRepositoryProvider).getIso(widget.existingIsoId!);
    if (iso != null && mounted) {
      _populateFromIso(iso);
    }
  }

  void _populateFromIso(IsoPost iso) {
    _fragranceCtrl.text = iso.fragranceName;
    _brandCtrl.text = iso.brand;
    final sizeStr = iso.sizeMl == iso.sizeMl.roundToDouble()
        ? iso.sizeMl.toInt().toString()
        : iso.sizeMl.toString();
    _sizeMlCtrl.text = sizeStr;
    if (iso.budgetPkr > 0) {
      _budgetCtrl.text = iso.budgetPkr.toString();
    }
    _notesCtrl.text = iso.notes ?? '';
    setState(() {});
  }

  @override
  void dispose() {
    _fragranceCtrl.dispose();
    _brandCtrl.dispose();
    _sizeMlCtrl.dispose();
    _budgetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/login?redirect=/iso/create');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final writeRepo = ref.read(isoWriteRepositoryProvider);

      if (_isEditMode) {
        await writeRepo.updateIso(widget.existingIsoId!, {
          'fragrance_name': _fragranceCtrl.text.trim(),
          'brand': _brandCtrl.text.trim(),
          'size_ml': double.tryParse(_sizeMlCtrl.text.trim()) ?? 0,
          'price_pkr': int.tryParse(_budgetCtrl.text.trim()) ?? 0,
          'condition_notes': _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        });
        ref.invalidate(isoDetailProvider(widget.existingIsoId!));
        if (mounted) context.go('/iso/${widget.existingIsoId}');
      } else {
        final isoId = await writeRepo.createIso(
          userId: user.id,
          fragranceName: _fragranceCtrl.text.trim(),
          brand: _brandCtrl.text.trim(),
          sizeMl: double.tryParse(_sizeMlCtrl.text.trim()) ?? 0,
          budgetPkr: int.tryParse(_budgetCtrl.text.trim()) ?? 0,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
        if (publish) {
          await writeRepo.publishIso(isoId);
          if (mounted) context.go('/iso/$isoId');
        } else {
          if (mounted) context.go('/dashboard/iso');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/iso'),
        ),
        title: Text(
          'THE OLFACTORY ARCHIVE',
          style: GoogleFonts.notoSerif(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
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
                  // ── Header ───────────────────────────────────────────────
                  Text(
                    _isEditMode ? 'EDIT ISO POST' : 'NEW ISO REQUEST',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditMode ? 'Update your request' : 'What are you looking for?',
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                  ),
                  if (!_isEditMode) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Post your ISO and let verified sellers in the community know what you\'re searching for.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.7,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // ── Form ─────────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthTextField(
                          label: 'FRAGRANCE NAME',
                          hint: 'e.g. Aventus',
                          controller: _fragranceCtrl,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Fragrance name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        AuthTextField(
                          label: 'BRAND / HOUSE',
                          hint: 'e.g. Creed',
                          controller: _brandCtrl,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Brand is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        AuthTextField(
                          label: 'SIZE (ML)',
                          hint: 'e.g. 50',
                          controller: _sizeMlCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Size is required';
                            }
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid size in ml';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        AuthTextField(
                          label: 'MAX BUDGET (PKR)',
                          hint: 'Leave blank if flexible',
                          controller: _budgetCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 28),
                        AuthTextField(
                          label: 'ADDITIONAL NOTES',
                          hint: 'Condition preference, specific batch, etc.',
                          controller: _notesCtrl,
                          textInputAction: TextInputAction.newline,
                        ),
                      ],
                    ),
                  ),

                  // ── Error banner ─────────────────────────────────────────
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      color: AppColors.errorContainer,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // ── Action buttons ───────────────────────────────────────
                  if (_isEditMode)
                    _buildPrimaryButton(
                      label: 'SAVE CHANGES',
                      onPressed: _loading ? null : () => _submit(publish: true),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.ghostBorderBase,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                foregroundColor: AppColors.primary,
                              ),
                              onPressed:
                                  _loading ? null : () => _submit(publish: false),
                              child: Text(
                                'SAVE DRAFT',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPrimaryButton(
                            label: 'POST ISO',
                            onPressed:
                                _loading ? null : () => _submit(publish: true),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        onPressed: onPressed,
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
      ),
    );
  }
}

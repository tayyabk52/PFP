import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/profile_provider.dart';
import '../providers/my_listings_provider.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  final String? existingListingId;
  final String? initialType;
  const CreateListingPage({super.key, this.existingListingId, this.initialType});

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  // ── Photos ─────────────────────────────────────────────────────────────────
  final List<Uint8List?> _photoBytes = List.filled(5, null);
  final List<String?> _existingPhotoUrls = List.filled(5, null);
  final List<String?> _existingPhotoIds = List.filled(5, null);
  final List<String?> _existingStoragePaths = List.filled(5, null);

  // ── Form ───────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  late String _listingType;
  final _fragranceNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeMlController = TextEditingController();
  final _pricePkrController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _deliveryController = TextEditingController();
  final _fragranceFamily = TextEditingController();
  final _fragranceNotesController = TextEditingController();
  final _vintageYearController = TextEditingController();
  final _conditionNotesController = TextEditingController();
  String? _condition;
  DateTime? _auctionEndAt;
  bool _impressionDeclaration = false;
  bool _declarationError = false;
  bool _isSubmitting = false;
  bool _isLoadingEdit = false;

  // Track photos that were present when edit mode loaded, so we can detect removals.
  final List<String?> _originalPhotoIds = List.filled(5, null);
  final List<String?> _originalPhotoUrls = List.filled(5, null);

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Members cannot create marketplace listings — redirect to ISO create
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = ref.read(currentProfileProvider).valueOrNull?['role'] as String?;
      final isMemberOnly = role != 'seller' && role != 'admin';
      if (isMemberOnly) context.go('/iso/create');
    });
    _listingType = widget.initialType ?? 'Full Bottle';
    if (widget.existingListingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingListing();
      });
    }
  }

  @override
  void dispose() {
    _fragranceNameController.dispose();
    _brandController.dispose();
    _sizeMlController.dispose();
    _pricePkrController.dispose();
    _quantityController.dispose();
    _deliveryController.dispose();
    _fragranceFamily.dispose();
    _fragranceNotesController.dispose();
    _vintageYearController.dispose();
    _conditionNotesController.dispose();
    super.dispose();
  }

  // ── Edit mode loader ───────────────────────────────────────────────────────
  Future<void> _loadExistingListing() async {
    setState(() => _isLoadingEdit = true);
    try {
      final repo = ref.read(listingWriteRepositoryProvider);
      final listing = await repo.getMyListing(widget.existingListingId!);
      if (listing == null || !mounted) return;
      _listingType = listing.listingType.value;
      _fragranceNameController.text = listing.fragranceName;
      _brandController.text = listing.brand;
      _sizeMlController.text = listing.sizeMl.toString();
      _pricePkrController.text = listing.pricePkr.toString();
      _condition = listing.condition?.value;
      if (listing.deliveryDetails != null) {
        _deliveryController.text = listing.deliveryDetails!;
      }
      if (listing.fragranceFamily != null) {
        _fragranceFamily.text = listing.fragranceFamily!;
      }
      if (listing.fragranceNotes != null) {
        _fragranceNotesController.text = listing.fragranceNotes!;
      }
      if (listing.vintageYear != null) {
        _vintageYearController.text = listing.vintageYear.toString();
      }
      if (listing.conditionNotes != null) {
        _conditionNotesController.text = listing.conditionNotes!;
      }
      if (listing.quantityAvailable != null) {
        _quantityController.text = listing.quantityAvailable.toString();
      }
      _auctionEndAt = listing.auctionEndAt;
      for (int i = 0; i < listing.photos.length && i < 5; i++) {
        _existingPhotoUrls[i] = listing.photos[i].fileUrl;
        _existingPhotoIds[i] = listing.photos[i].id;
        _originalPhotoIds[i] = listing.photos[i].id;
        _originalPhotoUrls[i] = listing.photos[i].fileUrl;
      }
      setState(() {});
    } finally {
      if (mounted) setState(() => _isLoadingEdit = false);
    }
  }

  // ── Photo helpers ──────────────────────────────────────────────────────────
  Future<void> _pickPhoto(int index) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photoBytes[index] = bytes);
  }

  bool _hasAnyPhoto() {
    for (int i = 0; i < 5; i++) {
      if (_photoBytes[i] != null || _existingPhotoUrls[i] != null) return true;
    }
    return false;
  }

  void _showPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Replace', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text('Remove', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _photoBytes[index] = null;
                  _existingPhotoUrls[index] = null;
                  _existingPhotoIds[index] = null;
                  _existingStoragePaths[index] = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit logic ───────────────────────────────────────────────────────────
  void _saveDraft() {
    final name = _fragranceNameController.text.trim();
    final brand = _brandController.text.trim();
    final sizeMlText = _sizeMlController.text.trim();
    final sizeMl = double.tryParse(sizeMlText) ?? 0;

    if (name.isEmpty || brand.isEmpty || sizeMl <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fragrance name, brand, and size (ml > 0) are required to save a draft.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    _submitListing(publish: false);
  }

  void _publish() {
    if (!_impressionDeclaration) {
      setState(() => _declarationError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please confirm the impression declaration',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_listingType == 'Auction' && _auctionEndAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auction end date is required', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_hasAnyPhoto()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one photo', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _submitListing(publish: true);
  }

  Future<void> _submitListing({required bool publish}) async {
    try {
      final repo = ref.read(listingWriteRepositoryProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session expired. Please sign in again.',
                  style: GoogleFonts.inter()),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final sizeMl = double.tryParse(_sizeMlController.text.trim()) ?? 0;
      final pricePkr = int.tryParse(_pricePkrController.text.trim()) ?? 0;
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      final vintageYear = int.tryParse(_vintageYearController.text.trim());

      String listingId;

      if (widget.existingListingId != null) {
        final updateMap = <String, dynamic>{
          'listing_type': _listingType,
          'fragrance_name': _fragranceNameController.text.trim(),
          'brand': _brandController.text.trim(),
          'size_ml': sizeMl,
          'price_pkr': pricePkr,
          if (_condition != null) 'condition': _condition,
          if (_deliveryController.text.trim().isNotEmpty)
            'delivery_details': _deliveryController.text.trim(),
          if (_fragranceFamily.text.trim().isNotEmpty)
            'fragrance_family': _fragranceFamily.text.trim(),
          if (_fragranceNotesController.text.trim().isNotEmpty)
            'fragrance_notes': _fragranceNotesController.text.trim(),
          if (vintageYear != null) 'vintage_year': vintageYear,
          if (_conditionNotesController.text.trim().isNotEmpty)
            'condition_notes': _conditionNotesController.text.trim(),
          if (_auctionEndAt != null)
            'auction_end_at': _auctionEndAt!.toIso8601String(),
          if (_listingType == 'Full Bottle' || _listingType == 'Decant/Split')
            'quantity_available': quantity,
        };
        await repo.updateListing(widget.existingListingId!, updateMap);
        listingId = widget.existingListingId!;
      } else {
        final result = await repo.createListing(
          sellerId: user.id,
          listingType: _listingType,
          fragranceName: _fragranceNameController.text.trim(),
          brand: _brandController.text.trim(),
          sizeMl: sizeMl,
          condition: _condition,
          pricePkr: pricePkr,
          deliveryDetails: _deliveryController.text.trim().isEmpty
              ? null
              : _deliveryController.text.trim(),
          quantityAvailable: quantity,
          auctionEndAt: _auctionEndAt,
          fragranceFamily: _fragranceFamily.text.trim().isEmpty
              ? null
              : _fragranceFamily.text.trim(),
          fragranceNotes: _fragranceNotesController.text.trim().isEmpty
              ? null
              : _fragranceNotesController.text.trim(),
          vintageYear: vintageYear,
          conditionNotes: _conditionNotesController.text.trim().isEmpty
              ? null
              : _conditionNotesController.text.trim(),
          impressionDeclarationAccepted: _impressionDeclaration,
        );
        listingId = result['id'] as String;
      }

      // Delete photos that were removed during editing
      if (widget.existingListingId != null) {
        for (int i = 0; i < 5; i++) {
          final originalId = _originalPhotoIds[i];
          final originalUrl = _originalPhotoUrls[i];
          if (originalId != null && _existingPhotoIds[i] == null) {
            // Photo was present at load time but has been removed
            final storagePath = _storagePathFromUrl(originalUrl!);
            await repo.deletePhoto(
              photoId: originalId,
              storagePath: storagePath,
            );
          }
        }
      }

      // Upload new photos
      for (int i = 0; i < 5; i++) {
        if (_photoBytes[i] != null) {
          await repo.uploadPhoto(
            listingId: listingId,
            bytes: _photoBytes[i]!,
            displayOrder: i + 1,
          );
        }
      }

      if (publish) {
        await repo.publishListing(listingId);
      }

      ref.invalidate(myListingsProvider);

      if (!mounted) return;
      if (publish) {
        context.go('/marketplace/$listingId');
      } else {
        context.go('/dashboard/my-listings');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Auction date picker ────────────────────────────────────────────────────
  Future<void> _pickAuctionEndAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _auctionEndAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_auctionEndAt ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _auctionEndAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  /// Extract the storage path from a Supabase public URL.
  /// Public URLs follow: .../storage/v1/object/public/listing-photos/<path>
  String _storagePathFromUrl(String url) {
    const marker = '/listing-photos/';
    final idx = url.indexOf(marker);
    if (idx == -1) return url;
    return url.substring(idx + marker.length);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionHeader(String number, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          number,
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontStyle: FontStyle.italic,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: GoogleFonts.notoSerif(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
            color: AppColors.textSecondary,
          ),
        ),
      );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
      );

  // ── Photo section ──────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero slot
        GestureDetector(
          onTap: () {
            final hasFilled =
                _photoBytes[0] != null || _existingPhotoUrls[0] != null;
            if (hasFilled) {
              _showPhotoOptions(0);
            } else {
              _pickPhoto(0);
            }
          },
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: _buildPhotoSlot(0, isHero: true),
          ),
        ),
        const SizedBox(height: 8),
        // Thumbnail row
        Row(
          children: List.generate(4, (thumbIndex) {
            final i = thumbIndex + 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: thumbIndex == 0 ? 0 : 4),
                child: GestureDetector(
                  onTap: () {
                    final hasFilled =
                        _photoBytes[i] != null || _existingPhotoUrls[i] != null;
                    if (hasFilled) {
                      _showPhotoOptions(i);
                    } else {
                      _pickPhoto(i);
                    }
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildPhotoSlot(i, isHero: false),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Authenticity note
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surfaceContainerLow,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Each listing is reviewed by PFC. Ensure photos are clear and authentic.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSlot(int index, {required bool isHero}) {
    final bytes = _photoBytes[index];
    final url = _existingPhotoUrls[index];

    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    if (url != null) {
      return Image.network(url, fit: BoxFit.cover);
    }

    // Placeholder
    return Container(
      color: AppColors.surfaceContainerLow,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: isHero ? 36 : 20,
            color: AppColors.textMuted,
          ),
          if (isHero) ...[
            const SizedBox(height: 8),
            Text(
              'Add Primary Photo',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Core details section ───────────────────────────────────────────────────
  Widget _buildCoreDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('01', 'Core Details'),
        const SizedBox(height: 24),

        // Listing type chips
        _fieldLabel('Listing Type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Full Bottle', 'Decant/Split', 'Swap', 'Auction']
                .map((type) => _buildTypeChip(type,
                    selected: _listingType == type, enabled: true))
                .toList(),
          ),

        const SizedBox(height: 20),

        // Fragrance Name
        _fieldLabel('Fragrance Name'),
        TextFormField(
          controller: _fragranceNameController,
          decoration: _fieldDecoration('e.g. Oud Minerale'),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),

        // Brand
        _fieldLabel('Brand / House'),
        TextFormField(
          controller: _brandController,
          decoration: _fieldDecoration('e.g. Tom Ford'),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),

        // Size (ml)
        _fieldLabel('Size (ml)'),
        TextFormField(
          controller: _sizeMlController,
          decoration: _fieldDecoration('e.g. 100'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
          validator: (v) {
            final val = double.tryParse(v?.trim() ?? '');
            if (val == null || val <= 0) return 'Must be greater than 0';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Quantity (only for Full Bottle or Decant/Split)
        if (_listingType == 'Full Bottle' || _listingType == 'Decant/Split') ...[
          _fieldLabel('Quantity Available'),
          TextFormField(
            controller: _quantityController,
            decoration: _fieldDecoration('1'),
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
            validator: (v) {
              final val = int.tryParse(v?.trim() ?? '');
              if (val == null || val < 1) return 'Must be at least 1';
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildTypeChip(String type, {required bool selected, required bool enabled}) {
    return GestureDetector(
      onTap: enabled
          ? () => setState(() {
                _listingType = type;
              })
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
        child: Text(
          type,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Olfactory profile section ──────────────────────────────────────────────
  Widget _buildOlfactoryProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('02', 'Olfactory Profile'),
        const SizedBox(height: 24),

        _fieldLabel('Fragrance Family'),
        TextFormField(
          controller: _fragranceFamily,
          decoration:
              _fieldDecoration('e.g. Oriental Woody, Chypre Floral'),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
        ),
        const SizedBox(height: 16),

        _fieldLabel('Fragrance Notes'),
        TextFormField(
          controller: _fragranceNotesController,
          decoration: _fieldDecoration('e.g. Oud, Bergamot, Rose'),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
        ),
        const SizedBox(height: 16),

        _fieldLabel('Vintage Year'),
        TextFormField(
          controller: _vintageYearController,
          decoration: _fieldDecoration('e.g. 2015'),
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
          validator: (v) {
            final text = v?.trim() ?? '';
            if (text.isEmpty) return null;
            final year = int.tryParse(text);
            if (year == null || year < 1900 || year > 2100) {
              return 'Enter a valid year between 1900 and 2100';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Condition & pricing section ────────────────────────────────────────────
  Widget _buildConditionPricing() {
    final isSwap = _listingType == 'Swap';
    final isAuction = _listingType == 'Auction';

    String priceLabel;
    if (isSwap) {
      priceLabel = 'Cash Component (0 if pure swap)';
    } else {
      priceLabel = 'Price (PKR)';
    }

    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('03', 'Condition & Pricing'),
          const SizedBox(height: 24),

          _fieldLabel('Condition'),
          DropdownButtonFormField<String>(
            value: _condition,
            decoration: _fieldDecoration('Select condition'),
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
            dropdownColor: AppColors.card,
            items: ['New', 'Like New', 'Excellent', 'Good', 'Fair']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _condition = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          // Condition Notes
          _fieldLabel('Condition Notes'),
          TextFormField(
            controller: _conditionNotesController,
            decoration: _fieldDecoration('Describe wear, box, batch code...'),
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),

          // Price
          _fieldLabel(priceLabel),
          TextFormField(
            controller: _pricePkrController,
            decoration: _fieldDecoration('0').copyWith(prefixText: 'Rs. '),
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
            validator: (v) {
              final val = int.tryParse(v?.trim() ?? '');
              if (isSwap) {
                if (val == null || val < 0) return 'Enter 0 or a positive amount';
              } else {
                if (val == null || val <= 0) return 'Must be greater than 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Auction end date — only for Auction type
          if (isAuction) ...[
            _fieldLabel('Auction End Date & Time'),
            GestureDetector(
              onTap: _pickAuctionEndAt,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: AppColors.card,
                child: Text(
                  _auctionEndAt != null
                      ? _formatDateTime(_auctionEndAt!)
                      : 'Tap to select end date & time',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _auctionEndAt != null
                        ? AppColors.onSurface
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $hour:$min';
  }

  // ── Delivery section ───────────────────────────────────────────────────────
  Widget _buildDelivery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('04', 'Delivery Details'),
        const SizedBox(height: 24),
        _fieldLabel('Delivery Details'),
        TextFormField(
          controller: _deliveryController,
          decoration: _fieldDecoration(
            'Describe shipping options, couriers, who pays delivery, local pickup options...',
          ),
          maxLines: 3,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
        ),
      ],
    );
  }

  // ── Impression declaration ─────────────────────────────────────────────────
  Widget _buildImpressionDeclaration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: AppColors.primary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _impressionDeclaration,
                onChanged: (v) => setState(() {
                  _impressionDeclaration = v ?? false;
                  if (_impressionDeclaration) _declarationError = false;
                }),
                checkColor: AppColors.primary,
                fillColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? Colors.white
                        : Colors.transparent),
                side: const BorderSide(color: Colors.white, width: 1.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _impressionDeclaration = !_impressionDeclaration;
                    if (_impressionDeclaration) _declarationError = false;
                  }),
                  child: Text(
                    'I confirm this listing is not an impression or expression. PFC has a zero-tolerance policy for clones and counterfeit goods.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_declarationError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'You must confirm this declaration before publishing.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
            ),
          ),
      ],
    );
  }

  // ── Actions bar ────────────────────────────────────────────────────────────
  Widget _buildActionsBar() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _saveDraft,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.ghostBorderBase),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: Text(
              'SAVE DRAFT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _publish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'PUBLISH',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingListingId != null;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 720;

    void navigateBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    }

    if (_isLoadingEdit) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) navigateBack();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: navigateBack,
            ),
            title: Text(
              isEditMode ? 'Edit Listing' : 'List a Fragrance',
              style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            elevation: 0,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    Widget photoSection = _buildPhotoSection();
    Widget formSection = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoreDetails(),
          const SizedBox(height: 32),
          _buildOlfactoryProfile(),
          const SizedBox(height: 32),
          _buildConditionPricing(),
          const SizedBox(height: 32),
          _buildDelivery(),
          const SizedBox(height: 32),
          _buildImpressionDeclaration(),
          const SizedBox(height: 32),
          _buildActionsBar(),
          const SizedBox(height: 40),
        ],
      ),
    );

    Widget content;
    if (isWide) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: photos (~40%)
          Flexible(
            flex: 4,
            child: photoSection,
          ),
          const SizedBox(width: 32),
          // Right: form (~60%)
          Flexible(
            flex: 6,
            child: formSection,
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          photoSection,
          const SizedBox(height: 32),
          formSection,
        ],
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigateBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: navigateBack,
          ),
          title: Text(
            isEditMode ? 'Edit Listing' : 'List a Fragrance',
            style: GoogleFonts.notoSerif(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

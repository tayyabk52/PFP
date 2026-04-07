import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

/// Data access for seller_applications table and CNIC Storage uploads.
///
/// Storage bucket: 'cnic-docs' (private, RLS-protected).
/// Policies: authenticated INSERT into own folder, authenticated SELECT own +
/// admin SELECT all, admin DELETE (for purge after verification).
class SellerApplyRepository {
  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------

  /// Uploads a CNIC image and returns its storage path (not a public URL).
  /// The path format: {userId}/cnic_{side}_{timestamp}.jpg
  Future<String> uploadCnicImage({
    required String userId,
    required Uint8List imageBytes,
    required String side, // 'front' | 'back'
  }) async {
    final path =
        '$userId/cnic_${side}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('cnic-docs').uploadBinary(
          path,
          imageBytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    // Return storage path — admin accesses via createSignedUrl
    return path;
  }

  // ---------------------------------------------------------------------------
  // Applications
  // ---------------------------------------------------------------------------

  Future<void> submitApplication({
    required String applicantId,
    required String fullLegalName,
    required String cnicNumber,
    required String cnicFrontUrl,
    required String cnicBackUrl,
    required String phoneNumber,
    required String city,
    required List<String> sellerTypes,
    required bool isExistingFbSeller,
    String? fbSellerId,
    String? fbProfileUrl,
  }) async {
    // Delete any rejected application so the user can reapply cleanly
    await supabase
        .from('seller_applications')
        .delete()
        .eq('applicant_id', applicantId)
        .eq('status', 'Rejected');

    await supabase.from('seller_applications').insert({
      'applicant_id': applicantId,
      'full_legal_name': fullLegalName.trim(),
      'cnic_number': cnicNumber.trim(),
      'cnic_front_url': cnicFrontUrl,
      'cnic_back_url': cnicBackUrl,
      'phone_number': phoneNumber.trim(),
      'city': city.trim(),
      'seller_types': sellerTypes,
      'is_existing_fb_seller': isExistingFbSeller,
      if (fbSellerId != null && fbSellerId.trim().isNotEmpty)
        'fb_seller_id': fbSellerId.trim(),
      if (fbProfileUrl != null && fbProfileUrl.trim().isNotEmpty)
        'fb_profile_url': fbProfileUrl.trim(),
    });
  }

  /// Returns the most relevant application for the authenticated user.
  /// Prefers the Approved application — the profile role is source of truth,
  /// but showing the correct application row gives meaningful context.
  Future<Map<String, dynamic>?> getMyApplication(String userId) async {
    // Prefer the Approved application — the profile role is source of truth,
    // but showing the correct application row gives meaningful context.
    final approved = await supabase
        .from('seller_applications')
        .select()
        .eq('applicant_id', userId)
        .eq('status', 'Approved')
        .maybeSingle();
    if (approved != null) return approved;
    // Fall back to most recent
    return await supabase
        .from('seller_applications')
        .select()
        .eq('applicant_id', userId)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }
}

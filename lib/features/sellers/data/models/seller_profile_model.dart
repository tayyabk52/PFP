import 'package:flutter/foundation.dart';

/// Full seller profile as displayed on the public seller page.
@immutable
class SellerProfile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? city;
  final String role;
  final int transactionCount;
  final double avgRating;
  final int ratingCount;
  final String? pfcSellerCode;
  final String? bio;
  final bool isLegacyFbSeller;
  final String? fbProfileUrl;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const SellerProfile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.city,
    required this.role,
    required this.transactionCount,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.pfcSellerCode,
    this.bio,
    this.isLegacyFbSeller = false,
    this.fbProfileUrl,
    this.verifiedAt,
    required this.createdAt,
  });

  bool get isVerifiedSeller => role == 'seller' || role == 'admin';

  String get displayNameOrFallback =>
      displayName?.isNotEmpty == true ? displayName! : 'PFC Member';

  factory SellerProfile.fromMap(Map<String, dynamic> m) => SellerProfile(
        id: m['id'] as String,
        displayName: m['display_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        city: m['city'] as String?,
        role: m['role'] as String? ?? 'member',
        transactionCount: m['transaction_count'] as int? ?? 0,
        avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: m['rating_count'] as int? ?? 0,
        pfcSellerCode: m['pfc_seller_code'] as String?,
        bio: m['bio'] as String?,
        isLegacyFbSeller: m['is_legacy_fb_seller'] as bool? ?? false,
        fbProfileUrl: m['fb_profile_url'] as String?,
        verifiedAt: m['verified_at'] != null
            ? DateTime.parse(m['verified_at'] as String)
            : null,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

/// A review left by a buyer for a seller.
@immutable
class SellerReview {
  final String id;
  final String listingId;
  final String reviewerId;
  final String sellerId;
  final int rating;
  final String comment;
  final DateTime submittedAt;
  final DateTime? lastEditedAt;

  // Joined fields
  final String? reviewerDisplayName;
  final String? reviewerAvatarUrl;
  final String? fragranceName;
  final String? brand;

  const SellerReview({
    required this.id,
    required this.listingId,
    required this.reviewerId,
    required this.sellerId,
    required this.rating,
    required this.comment,
    required this.submittedAt,
    this.lastEditedAt,
    this.reviewerDisplayName,
    this.reviewerAvatarUrl,
    this.fragranceName,
    this.brand,
  });

  String get reviewerNameOrFallback =>
      reviewerDisplayName?.isNotEmpty == true
          ? reviewerDisplayName!
          : 'PFC Member';

  factory SellerReview.fromMap(Map<String, dynamic> m) {
    final reviewer = m['reviewer'] as Map<String, dynamic>?;
    final listing = m['listings'] as Map<String, dynamic>?;

    return SellerReview(
      id: m['id'] as String,
      listingId: m['listing_id'] as String,
      reviewerId: m['reviewer_id'] as String,
      sellerId: m['seller_id'] as String,
      rating: m['rating'] as int,
      comment: m['comment'] as String? ?? '',
      submittedAt: DateTime.parse(m['submitted_at'] as String),
      lastEditedAt: m['last_edited_at'] != null
          ? DateTime.parse(m['last_edited_at'] as String)
          : null,
      reviewerDisplayName: reviewer?['display_name'] as String?,
      reviewerAvatarUrl: reviewer?['avatar_url'] as String?,
      fragranceName: listing?['fragrance_name'] as String?,
      brand: listing?['brand'] as String?,
    );
  }
}

/// Summary stats for a seller, computed from their data.
@immutable
class SellerStats {
  final int totalListings;
  final int totalSales;
  final double averageRating;
  final int reviewCount;

  const SellerStats({
    required this.totalListings,
    required this.totalSales,
    required this.averageRating,
    required this.reviewCount,
  });
}

/// Compact seller card for the sellers list page.
@immutable
class SellerSummary {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? city;
  final String role;
  final int transactionCount;
  final String? pfcSellerCode;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const SellerSummary({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.city,
    required this.role,
    required this.transactionCount,
    this.pfcSellerCode,
    this.verifiedAt,
    required this.createdAt,
  });

  bool get isVerifiedSeller => role == 'seller' || role == 'admin';

  String get displayNameOrFallback =>
      displayName?.isNotEmpty == true ? displayName! : 'PFC Member';

  factory SellerSummary.fromMap(Map<String, dynamic> m) => SellerSummary(
        id: m['id'] as String,
        displayName: m['display_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        city: m['city'] as String?,
        role: m['role'] as String? ?? 'member',
        transactionCount: m['transaction_count'] as int? ?? 0,
        pfcSellerCode: m['pfc_seller_code'] as String?,
        verifiedAt: m['verified_at'] != null
            ? DateTime.parse(m['verified_at'] as String)
            : null,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

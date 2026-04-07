import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/seller_repository.dart';
import '../data/models/seller_profile_model.dart';

final sellerRepositoryProvider = Provider<SellerRepository>(
  (_) => SellerRepository(),
);

/// Fetches a seller profile by code or id.
/// Tries by pfc_seller_code first, falls back to id.
final sellerProfileProvider =
    FutureProvider.autoDispose.family<SellerProfile?, String>(
  (ref, codeOrId) async {
    final repo = ref.read(sellerRepositoryProvider);
    // Try by code first
    final byCode = await repo.getSellerByCode(codeOrId);
    if (byCode != null) return byCode;
    // Fall back to id
    return repo.getSellerById(codeOrId);
  },
);

/// Fetches reviews for a seller.
final sellerReviewsProvider =
    FutureProvider.autoDispose.family<List<SellerReview>, String>(
  (ref, sellerId) async {
    final repo = ref.read(sellerRepositoryProvider);
    return repo.getSellerReviews(sellerId);
  },
);

/// Fetches published listings for a seller.
final sellerListingsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, sellerId) async {
    final repo = ref.read(sellerRepositoryProvider);
    return repo.getSellerListings(sellerId);
  },
);

/// Fetches stats for a seller.
final sellerStatsProvider =
    FutureProvider.autoDispose.family<SellerStats, String>(
  (ref, sellerId) async {
    final repo = ref.read(sellerRepositoryProvider);
    return repo.getSellerStats(sellerId);
  },
);

/// Fetches sellers list, optionally filtered by keyword.
final sellersListProvider =
    FutureProvider.autoDispose.family<List<SellerSummary>, String?>(
  (ref, keyword) async {
    final repo = ref.read(sellerRepositoryProvider);
    return repo.getSellers(keyword: keyword);
  },
);

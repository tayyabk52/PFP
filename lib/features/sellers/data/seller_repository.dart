import '../../../core/supabase/supabase_client.dart';
import 'models/seller_profile_model.dart';

class SellerRepository {
  /// Fetch a seller profile by their PFC seller code.
  Future<SellerProfile?> getSellerByCode(String pfcSellerCode) async {
    final data = await supabase
        .from('profiles')
        .select(
          'id, role, display_name, city, avatar_url, transaction_count, '
          'avg_rating, rating_count, '
          'pfc_seller_code, is_legacy_fb_seller, fb_profile_url, '
          'verified_at, created_at',
        )
        .eq('pfc_seller_code', pfcSellerCode)
        .maybeSingle();
    if (data == null) return null;
    return SellerProfile.fromMap(data);
  }

  /// Fetch a seller profile by their user id.
  Future<SellerProfile?> getSellerById(String id) async {
    final data = await supabase
        .from('profiles')
        .select(
          'id, role, display_name, city, avatar_url, transaction_count, '
          'avg_rating, rating_count, '
          'pfc_seller_code, is_legacy_fb_seller, fb_profile_url, '
          'verified_at, created_at',
        )
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return SellerProfile.fromMap(data);
  }

  /// Fetch reviews for a seller, joined with reviewer profile and listing info.
  Future<List<SellerReview>> getSellerReviews(String sellerId) async {
    final data = await supabase
        .from('reviews')
        .select(
          '*, reviewer:profiles!reviewer_id(display_name, avatar_url), '
          'listings!listing_id(fragrance_name, brand)',
        )
        .eq('seller_id', sellerId)
        .order('submitted_at', ascending: false);

    return (data as List)
        .map((m) => SellerReview.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Fetch published listings for a seller, with photos.
  Future<List<Map<String, dynamic>>> getSellerListings(String sellerId) async {
    final data = await supabase
        .from('listings')
        .select(
          'id, fragrance_name, brand, price_pkr, status, '
          'listing_photos(id, file_url, display_order)',
        )
        .eq('seller_id', sellerId)
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Compute summary stats for a seller.
  Future<SellerStats> getSellerStats(String sellerId) async {
    // Total listings
    final listingsData = await supabase
        .from('listings')
        .select('id, status')
        .eq('seller_id', sellerId);
    final allListings = List<Map<String, dynamic>>.from(listingsData as List);
    final totalListings = allListings.length;
    final totalSales =
        allListings.where((l) => l['status'] == 'sold').length;

    // Reviews
    final reviewsData = await supabase
        .from('reviews')
        .select('rating')
        .eq('seller_id', sellerId);
    final reviews = List<Map<String, dynamic>>.from(reviewsData as List);
    final reviewCount = reviews.length;
    double averageRating = 0;
    if (reviewCount > 0) {
      final sum = reviews.fold<int>(
          0, (acc, r) => acc + (r['rating'] as int? ?? 0));
      averageRating = sum / reviewCount;
    }

    return SellerStats(
      totalListings: totalListings,
      totalSales: totalSales,
      averageRating: averageRating,
      reviewCount: reviewCount,
    );
  }

  /// Submit a new review.
  Future<void> submitReview({
    required String listingId,
    required String sellerId,
    required int rating,
    required String comment,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('reviews').insert({
      'listing_id': listingId,
      'seller_id': sellerId,
      'reviewer_id': userId,
      'rating': rating,
      'comment': comment,
    });
  }

  /// Fetch all sellers (role='seller'), optionally filtered by display_name keyword.
  Future<List<SellerSummary>> getSellers({String? keyword}) async {
    var query = supabase
        .from('profiles')
        .select(
          'id, role, display_name, city, avatar_url, transaction_count, '
          'pfc_seller_code, verified_at, created_at',
        )
        .eq('role', 'seller');
    if (keyword != null && keyword.isNotEmpty) {
      query = query.ilike('display_name', '%$keyword%');
    }
    final data = await query.order('transaction_count', ascending: false);
    return (data as List)
        .map((m) => SellerSummary.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Check if the current user already reviewed a listing.
  Future<Map<String, dynamic>?> getMyReviewForListing(
    String listingId,
    String reviewerId,
  ) async {
    final data = await supabase
        .from('reviews')
        .select()
        .eq('listing_id', listingId)
        .eq('reviewer_id', reviewerId)
        .maybeSingle();
    return data;
  }
}

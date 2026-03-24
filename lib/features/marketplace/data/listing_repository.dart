import '../../../core/supabase/supabase_client.dart';
import 'models/listing_model.dart';

class ListingRepository {
  static const String _listingSelect = '''
    id,
    sale_post_number,
    seller_id,
    listing_type,
    fragrance_name,
    brand,
    size_ml,
    condition,
    price_pkr,
    delivery_details,
    status,
    created_at,
    published_at,
    auction_end_at,
    quantity_available,
    fragrance_family,
    fragrance_notes,
    vintage_year,
    condition_notes,
    listing_photos(id, file_url, display_order),
    profiles(id, display_name, avatar_url, city, role, transaction_count, pfc_seller_code)
  ''';

  Future<List<Listing>> getListings(ListingFilters filters) async {
    var query = supabase
        .from('listings')
        .select(_listingSelect)
        .eq('status', 'Published')
        .neq('listing_type', 'ISO');

    if (filters.type != null) {
      query = query.eq('listing_type', filters.type!.value);
    }
    if (filters.condition != null) {
      query = query.eq('condition', filters.condition!.value);
    }
    if (filters.minPricePkr != null) {
      query = query.gte('price_pkr', filters.minPricePkr!);
    }
    if (filters.maxPricePkr != null) {
      query = query.lte('price_pkr', filters.maxPricePkr!);
    }
    if (filters.keyword != null && filters.keyword!.isNotEmpty) {
      final kw = filters.keyword!;
      query = query.or('fragrance_name.ilike.%$kw%,brand.ilike.%$kw%');
    }

    final response = await query.order('created_at', ascending: false);

    var listings = (response as List<dynamic>)
        .map((m) => Listing.fromMap(m as Map<String, dynamic>))
        .toList();

    // Post-filter for verified seller (role-based, cannot be done in SQL easily with join)
    if (filters.verifiedOnly) {
      listings = listings
          .where((l) => l.seller?.isVerifiedSeller == true)
          .toList();
    }

    return listings;
  }

  Future<Listing?> getListing(String id) async {
    final response = await supabase
        .from('listings')
        .select(_listingSelect)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Listing.fromMap(response);
  }
}

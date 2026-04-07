import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import 'models/listing_model.dart';

class ListingWriteRepository {
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

  /// Create a new listing as Draft. Returns {id, sale_post_number}.
  Future<Map<String, dynamic>> createListing({
    required String sellerId,
    required String listingType,
    required String fragranceName,
    required String brand,
    required double sizeMl,
    String? condition,
    int pricePkr = 0,
    String? deliveryDetails,
    int quantityAvailable = 1,
    DateTime? auctionEndAt,
    String? fragranceFamily,
    String? fragranceNotes,
    int? vintageYear,
    String? conditionNotes,
    bool impressionDeclarationAccepted = false,
  }) async {
    final data = <String, dynamic>{
      'seller_id': sellerId,
      'listing_type': listingType,
      'fragrance_name': fragranceName,
      'brand': brand,
      'size_ml': sizeMl,
      'price_pkr': pricePkr,
      'quantity_available': quantityAvailable,
      'impression_declaration_accepted': impressionDeclarationAccepted,
      'status': 'Draft',
    };

    if (condition != null) data['condition'] = condition;
    if (deliveryDetails != null) data['delivery_details'] = deliveryDetails;
    if (auctionEndAt != null) data['auction_end_at'] = auctionEndAt.toIso8601String();
    if (fragranceFamily != null) data['fragrance_family'] = fragranceFamily;
    if (fragranceNotes != null) data['fragrance_notes'] = fragranceNotes;
    if (vintageYear != null) data['vintage_year'] = vintageYear;
    if (conditionNotes != null) data['condition_notes'] = conditionNotes;

    final response = await supabase
        .from('listings')
        .insert(data)
        .select('id, sale_post_number')
        .single();

    return response as Map<String, dynamic>;
  }

  /// Set status to 'Published' and mark impression_declaration_accepted=true.
  Future<void> publishListing(String listingId) async {
    await supabase.from('listings').update({
      'status': 'Published',
      'impression_declaration_accepted': true,
    }).eq('id', listingId);
  }

  /// Update editable fields on an existing listing.
  Future<void> updateListing(String listingId, Map<String, dynamic> fields) async {
    await supabase.from('listings').update(fields).eq('id', listingId);
  }

  /// Upload a photo to listing-photos bucket and insert a row in listing_photos.
  /// Returns {photoId, fileUrl, storagePath}.
  Future<Map<String, String>> uploadPhoto({
    required String listingId,
    required Uint8List bytes,
    required int displayOrder,
  }) async {
    final path = '$listingId/${displayOrder}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage.from('listing-photos').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );

    final fileUrl = supabase.storage.from('listing-photos').getPublicUrl(path);

    final insertResponse = await supabase
        .from('listing_photos')
        .insert({
          'listing_id': listingId,
          'file_url': fileUrl,
          'display_order': displayOrder,
        })
        .select('id')
        .single();

    final photoId = (insertResponse as Map<String, dynamic>)['id'] as String;

    return {
      'photoId': photoId,
      'fileUrl': fileUrl,
      'storagePath': path,
    };
  }

  /// Delete a photo row from listing_photos and remove from storage.
  Future<void> deletePhoto({
    required String photoId,
    required String storagePath,
  }) async {
    await supabase.from('listing_photos').delete().eq('id', photoId);
    await supabase.storage.from('listing-photos').remove([storagePath]);
  }

  /// Fetch seller's own listings with photos.
  /// statusFilter null = all (Draft, Published, Sold, Expired — Deleted excluded).
  /// Only returns non-Deleted listings.
  Future<List<Listing>> getMyListings({
    required String sellerId,
    String? statusFilter,
  }) async {
    var query = supabase
        .from('listings')
        .select(_listingSelect)
        .eq('seller_id', sellerId);

    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    } else {
      query = query.neq('status', 'Deleted');
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((m) => Listing.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single listing for edit pre-population (must belong to sellerId).
  Future<Listing?> getMyListing(String listingId) async {
    final response = await supabase
        .from('listings')
        .select(_listingSelect)
        .eq('id', listingId)
        .maybeSingle();

    if (response == null) return null;
    return Listing.fromMap(response as Map<String, dynamic>);
  }

  /// Mark listing as Sold (DB trigger handles transaction_count + sold_at).
  Future<void> markAsSold(String listingId) async {
    await supabase.from('listings').update({'status': 'Sold'}).eq('id', listingId);
  }

  /// Decrement quantity_available by 1.
  /// DB trigger auto-sets status='Sold' when quantity_available reaches 0.
  Future<void> decrementQuantity(String listingId) async {
    await supabase.rpc('decrement_listing_quantity', params: {'p_listing_id': listingId});
  }

  /// Soft-delete: set status = 'Deleted'.
  Future<void> deleteListing(String listingId) async {
    await supabase.from('listings').update({'status': 'Deleted'}).eq('id', listingId);
  }
}

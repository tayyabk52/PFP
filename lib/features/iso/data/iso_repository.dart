import 'package:supabase_flutter/supabase_flutter.dart' show CountOption;

import '../../../core/supabase/supabase_client.dart';
import 'iso_model.dart';

class IsoRepository {
  static const String _isoSelect = '''
    id,
    sale_post_number,
    seller_id,
    fragrance_name,
    brand,
    size_ml,
    price_pkr,
    condition_notes,
    status,
    created_at,
    published_at,
    profiles(id, display_name, avatar_url, city, role, transaction_count, pfc_seller_code)
  ''';

  static const String _offerSelect = '''
    id,
    iso_id,
    seller_id,
    message,
    offer_amount,
    status,
    created_at,
    profiles(id, display_name, avatar_url, city, role, transaction_count, pfc_seller_code)
  ''';

  Future<List<IsoPost>> getPublishedIsos({String? keyword}) async {
    var query = supabase
        .from('listings')
        .select(_isoSelect)
        .eq('listing_type', 'ISO')
        .eq('status', 'Published');
    if (keyword != null && keyword.isNotEmpty) {
      query = query.or('fragrance_name.ilike.%$keyword%,brand.ilike.%$keyword%');
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((m) => IsoPost.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<IsoPost>> getMyIsos(String userId) async {
    final response = await supabase
        .from('listings')
        .select(_isoSelect)
        .eq('listing_type', 'ISO')
        .eq('seller_id', userId)
        .neq('status', 'Deleted')
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((m) => IsoPost.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Fetches published ISO posts for any user (for their public profile).
  Future<List<IsoPost>> getPublishedIsosForUser(String userId) async {
    final response = await supabase
        .from('listings')
        .select(_isoSelect)
        .eq('seller_id', userId)
        .eq('listing_type', 'ISO')
        .eq('status', 'Published')
        .order('published_at', ascending: false);

    return (response as List<dynamic>)
        .map((m) => IsoPost.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<IsoPost?> getIso(String id) async {
    final response = await supabase
        .from('listings')
        .select(_isoSelect)
        .eq('id', id)
        .eq('listing_type', 'ISO')
        .maybeSingle();
    if (response == null) return null;
    return IsoPost.fromMap(response);
  }

  Future<List<IsoOffer>> getIsoOffers(String isoId) async {
    final response = await supabase
        .from('iso_offers')
        .select(_offerSelect)
        .eq('iso_id', isoId)
        .order('created_at', ascending: true);
    return (response as List<dynamic>)
        .map((m) => IsoOffer.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<IsoOffer?> getMyOffer(String isoId, String userId) async {
    final response = await supabase
        .from('iso_offers')
        .select(_offerSelect)
        .eq('iso_id', isoId)
        .eq('seller_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return IsoOffer.fromMap(response);
  }

  Future<int> getUnreadNotificationsCount(String userId) async {
    final count = await supabase
        .from('iso_notifications')
        .count(CountOption.exact)
        .eq('recipient_id', userId)
        .isFilter('read_at', null);
    return count;
  }
}

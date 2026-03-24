import '../../../core/supabase/supabase_client.dart';

class IsoWriteRepository {
  Future<String> createIso({
    required String userId,
    required String fragranceName,
    required String brand,
    required double sizeMl,
    int budgetPkr = 0,
    String? notes,
  }) async {
    final response = await supabase.from('listings').insert({
      'seller_id': userId,
      'listing_type': 'ISO',
      'fragrance_name': fragranceName,
      'brand': brand,
      'size_ml': sizeMl,
      'price_pkr': budgetPkr,
      'condition_notes': notes,
      'status': 'Draft',
    }).select('id').single();
    return response['id'] as String;
  }

  Future<void> publishIso(String isoId) async {
    await supabase.from('listings').update({
      'status': 'Published',
    }).eq('id', isoId);
  }

  Future<void> updateIso(String isoId, Map<String, dynamic> fields) async {
    await supabase.from('listings').update(fields).eq('id', isoId);
  }

  Future<void> deleteIso(String isoId) async {
    await supabase.from('listings').update({'status': 'Deleted'}).eq('id', isoId);
  }

  Future<void> submitOffer({
    required String isoId,
    required String sellerId,
    String? message,
    int? offerAmount,
  }) async {
    await supabase.from('iso_offers').insert({
      'iso_id': isoId,
      'seller_id': sellerId,
      'message': message,
      'offer_amount': offerAmount,
      'status': 'pending',
    });
  }

  Future<void> withdrawOffer(String offerId) async {
    await supabase
        .from('iso_offers')
        .update({'status': 'withdrawn'})
        .eq('id', offerId);
  }

  Future<void> acceptOffer(String offerId, String isoId) async {
    await supabase.rpc('accept_iso_offer', params: {
      'p_offer_id': offerId,
      'p_iso_id': isoId,
    });
  }

  Future<void> declineOffer(String offerId) async {
    await supabase
        .from('iso_offers')
        .update({'status': 'declined'})
        .eq('id', offerId);
  }

  Future<void> markNotificationsRead(String userId) async {
    await supabase
        .from('iso_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('recipient_id', userId)
        .isFilter('read_at', null);
  }
}

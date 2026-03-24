import '../../marketplace/data/models/listing_model.dart';

enum IsoOfferStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  withdrawn('withdrawn');

  const IsoOfferStatus(this.value);
  final String value;

  static IsoOfferStatus fromString(String s) =>
      IsoOfferStatus.values.firstWhere((e) => e.value == s,
          orElse: () => IsoOfferStatus.pending);
}

class IsoPost {
  final String id;
  final String sellerId;
  final String salePostNumber;
  final String fragranceName;
  final String brand;
  final double sizeMl;
  final int budgetPkr;
  final String? notes;
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final SellerInfo? poster;

  const IsoPost({
    required this.id,
    required this.sellerId,
    required this.salePostNumber,
    required this.fragranceName,
    required this.brand,
    required this.sizeMl,
    required this.budgetPkr,
    this.notes,
    required this.status,
    required this.createdAt,
    this.publishedAt,
    this.poster,
  });

  factory IsoPost.fromMap(Map<String, dynamic> map) {
    final profilesRaw = map['profiles'] as Map<String, dynamic>?;
    return IsoPost(
      id: map['id'] as String,
      sellerId: map['seller_id'] as String,
      salePostNumber: map['sale_post_number'] as String,
      fragranceName: map['fragrance_name'] as String,
      brand: map['brand'] as String,
      sizeMl: (map['size_ml'] as num).toDouble(),
      budgetPkr: map['price_pkr'] as int? ?? 0,
      notes: map['condition_notes'] as String?,
      status: ListingStatus.fromDb(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      publishedAt: map['published_at'] != null
          ? DateTime.parse(map['published_at'] as String)
          : null,
      poster: profilesRaw != null ? SellerInfo.fromMap(profilesRaw) : null,
    );
  }
}

class IsoOffer {
  final String id;
  final String isoId;
  final String sellerId;
  final String? message;
  final int? offerAmount;
  final IsoOfferStatus status;
  final DateTime createdAt;
  final SellerInfo? seller;

  const IsoOffer({
    required this.id,
    required this.isoId,
    required this.sellerId,
    this.message,
    this.offerAmount,
    required this.status,
    required this.createdAt,
    this.seller,
  });

  factory IsoOffer.fromMap(Map<String, dynamic> map) {
    final profilesRaw = map['profiles'] as Map<String, dynamic>?;
    return IsoOffer(
      id: map['id'] as String,
      isoId: map['iso_id'] as String,
      sellerId: map['seller_id'] as String,
      message: map['message'] as String?,
      offerAmount: map['offer_amount'] as int?,
      status: IsoOfferStatus.fromString(map['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(map['created_at'] as String),
      seller: profilesRaw != null ? SellerInfo.fromMap(profilesRaw) : null,
    );
  }
}

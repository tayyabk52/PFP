import 'package:flutter/foundation.dart';

enum ListingType {
  fullBottle('Full Bottle'),
  decantSplit('Decant/Split'),
  iso('ISO'),
  swap('Swap'),
  auction('Auction');

  final String value;
  const ListingType(this.value);

  static ListingType fromDb(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => fullBottle);
}

enum ListingCondition {
  newItem('New'),
  likeNew('Like New'),
  excellent('Excellent'),
  good('Good'),
  fair('Fair');

  final String value;
  const ListingCondition(this.value);

  static ListingCondition? fromDb(String? v) {
    if (v == null) return null;
    return values.firstWhere((e) => e.value == v, orElse: () => good);
  }
}

enum ListingStatus {
  draft('Draft'),
  published('Published'),
  sold('Sold'),
  expired('Expired'),
  deleted('Deleted'),
  removed('Removed');

  final String value;
  const ListingStatus(this.value);

  static ListingStatus fromDb(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => draft);
}

class ListingPhoto {
  final String id;
  final String fileUrl;
  final int displayOrder;

  const ListingPhoto({
    required this.id,
    required this.fileUrl,
    required this.displayOrder,
  });

  factory ListingPhoto.fromMap(Map<String, dynamic> m) => ListingPhoto(
        id: m['id'] as String,
        fileUrl: m['file_url'] as String,
        displayOrder: m['display_order'] as int,
      );
}

class SellerInfo {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? city;
  final String role;
  final int transactionCount;
  final String? pfcSellerCode;

  const SellerInfo({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.city,
    required this.role,
    required this.transactionCount,
    this.pfcSellerCode,
  });

  bool get isVerifiedSeller => role == 'seller' || role == 'admin';

  String get displayNameOrFallback => displayName?.isNotEmpty == true ? displayName! : 'PFC Member';

  factory SellerInfo.fromMap(Map<String, dynamic> m) => SellerInfo(
        id: m['id'] as String,
        displayName: m['display_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        city: m['city'] as String?,
        role: m['role'] as String? ?? 'member',
        transactionCount: m['transaction_count'] as int? ?? 0,
        pfcSellerCode: m['pfc_seller_code'] as String?,
      );
}

@immutable
class Listing {
  final String id;
  final String salePostNumber;
  final String sellerId;
  final ListingType listingType;
  final String fragranceName;
  final String brand;
  final double sizeMl;
  final ListingCondition? condition;
  final int pricePkr;
  final String? deliveryDetails;
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? auctionEndAt;
  final int? quantityAvailable;
  final String? fragranceFamily;
  final String? fragranceNotes;
  final int? vintageYear;
  final String? conditionNotes;
  final List<ListingPhoto> photos;
  final SellerInfo? seller;

  const Listing({
    required this.id,
    required this.salePostNumber,
    required this.sellerId,
    required this.listingType,
    required this.fragranceName,
    required this.brand,
    required this.sizeMl,
    this.condition,
    required this.pricePkr,
    this.deliveryDetails,
    required this.status,
    required this.createdAt,
    this.publishedAt,
    this.auctionEndAt,
    this.quantityAvailable,
    this.fragranceFamily,
    this.fragranceNotes,
    this.vintageYear,
    this.conditionNotes,
    this.photos = const [],
    this.seller,
  });

  String? get primaryPhotoUrl =>
      photos.isEmpty ? null : photos.first.fileUrl;

  bool get isAuction => listingType == ListingType.auction;

  bool get isAuctionActive =>
      isAuction && auctionEndAt != null && auctionEndAt!.isAfter(DateTime.now());

  factory Listing.fromMap(Map<String, dynamic> m) {
    final photosRaw = m['listing_photos'] as List<dynamic>? ?? [];
    final sellerRaw = m['profiles'] as Map<String, dynamic>?;
    final sortedPhotos = photosRaw
        .map((p) => ListingPhoto.fromMap(p as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Listing(
      id: m['id'] as String,
      salePostNumber: m['sale_post_number'] as String,
      sellerId: m['seller_id'] as String,
      listingType: ListingType.fromDb(m['listing_type'] as String),
      fragranceName: m['fragrance_name'] as String,
      brand: m['brand'] as String,
      sizeMl: (m['size_ml'] as num).toDouble(),
      condition: ListingCondition.fromDb(m['condition'] as String?),
      pricePkr: m['price_pkr'] as int? ?? 0,
      deliveryDetails: m['delivery_details'] as String?,
      status: ListingStatus.fromDb(m['status'] as String),
      createdAt: DateTime.parse(m['created_at'] as String),
      publishedAt: m['published_at'] != null
          ? DateTime.parse(m['published_at'] as String)
          : null,
      auctionEndAt: m['auction_end_at'] != null
          ? DateTime.parse(m['auction_end_at'] as String)
          : null,
      quantityAvailable: m['quantity_available'] as int?,
      fragranceFamily: m['fragrance_family'] as String?,
      fragranceNotes: m['fragrance_notes'] as String?,
      vintageYear: m['vintage_year'] as int?,
      conditionNotes: m['condition_notes'] as String?,
      photos: sortedPhotos,
      seller: sellerRaw != null ? SellerInfo.fromMap(sellerRaw) : null,
    );
  }
}

@immutable
class ListingFilters {
  final ListingType? type;
  final ListingCondition? condition;
  final int? minPricePkr;
  final int? maxPricePkr;
  final bool verifiedOnly;
  final String? keyword;

  const ListingFilters({
    this.type,
    this.condition,
    this.minPricePkr,
    this.maxPricePkr,
    this.verifiedOnly = false,
    this.keyword,
  });

  ListingFilters copyWith({
    ListingType? type,
    ListingCondition? condition,
    int? minPricePkr,
    int? maxPricePkr,
    bool? verifiedOnly,
    String? keyword,
    bool clearType = false,
    bool clearCondition = false,
    bool clearKeyword = false,
    bool clearPriceMin = false,
    bool clearPriceMax = false,
  }) =>
      ListingFilters(
        type: clearType ? null : (type ?? this.type),
        condition: clearCondition ? null : (condition ?? this.condition),
        minPricePkr: clearPriceMin ? null : (minPricePkr ?? this.minPricePkr),
        maxPricePkr: clearPriceMax ? null : (maxPricePkr ?? this.maxPricePkr),
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
        keyword: clearKeyword ? null : (keyword ?? this.keyword),
      );

  bool get isEmpty =>
      type == null &&
      condition == null &&
      minPricePkr == null &&
      maxPricePkr == null &&
      !verifiedOnly &&
      (keyword == null || keyword!.isEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingFilters &&
          type == other.type &&
          condition == other.condition &&
          minPricePkr == other.minPricePkr &&
          maxPricePkr == other.maxPricePkr &&
          verifiedOnly == other.verifiedOnly &&
          keyword == other.keyword;

  @override
  int get hashCode => Object.hash(
        type, condition, minPricePkr, maxPricePkr, verifiedOnly, keyword);
}

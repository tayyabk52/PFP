import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/listing_repository.dart';
import '../data/models/listing_model.dart';

final listingRepositoryProvider = Provider<ListingRepository>(
  (_) => ListingRepository(),
);

/// Holds the active filters for the marketplace browse page.
final listingFiltersProvider =
    StateProvider<ListingFilters>((_) => const ListingFilters());

/// Fetches listings matching the given [ListingFilters].
/// Use with ref.watch(listingsProvider(filters)).
final listingsProvider =
    FutureProvider.autoDispose.family<List<Listing>, ListingFilters>(
  (ref, filters) async {
    final repo = ref.read(listingRepositoryProvider);
    return repo.getListings(filters);
  },
);

/// Fetches a single listing by id.
final listingDetailProvider = FutureProvider.autoDispose.family<Listing?, String>(
  (ref, id) async {
    final repo = ref.read(listingRepositoryProvider);
    return repo.getListing(id);
  },
);

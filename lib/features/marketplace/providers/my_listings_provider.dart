import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/listing_write_repository.dart';
import '../data/models/listing_model.dart';

final listingWriteRepositoryProvider = Provider<ListingWriteRepository>(
  (_) => ListingWriteRepository(),
);

/// Active status filter for My Listings (null = All statuses except Deleted)
final myListingsStatusFilterProvider = StateProvider<String?>((ref) => null);

/// All listings belonging to the current authenticated seller
final myListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final filter = ref.watch(myListingsStatusFilterProvider);
  return ref.read(listingWriteRepositoryProvider).getMyListings(
    sellerId: user.id,
    statusFilter: filter,
  );
});

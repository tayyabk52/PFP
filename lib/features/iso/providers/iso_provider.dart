import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/iso_model.dart';
import '../data/iso_repository.dart';
import '../data/iso_write_repository.dart';

// ─── Repository providers ────────────────────────────────────────────────────

final isoRepositoryProvider = Provider<IsoRepository>((_) => IsoRepository());
final isoWriteRepositoryProvider = Provider<IsoWriteRepository>((_) => IsoWriteRepository());

// ─── ISO Board (public browse) ───────────────────────────────────────────────

/// Provides all published ISO posts, optionally filtered by keyword.
final isoBoardProvider =
    FutureProvider.autoDispose.family<List<IsoPost>, String?>(
  (ref, keyword) =>
      ref.read(isoRepositoryProvider).getPublishedIsos(keyword: keyword),
);

// ─── My ISO Posts ─────────────────────────────────────────────────────────────

/// Provides the current user's own ISO posts (all non-Deleted statuses).
final myIsoPostsProvider =
    FutureProvider.autoDispose<List<IsoPost>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(isoRepositoryProvider).getMyIsos(user.id);
});

// ─── ISO posts for a specific user (public profile) ──────────────────────────

/// Published ISO posts for any user — used on their public profile page.
final isoPostsForUserProvider =
    FutureProvider.autoDispose.family<List<IsoPost>, String>(
  (ref, userId) async {
    return ref.read(isoRepositoryProvider).getPublishedIsosForUser(userId);
  },
);

// ─── Single ISO detail ────────────────────────────────────────────────────────

/// Provides a single ISO post by its id.
final isoDetailProvider =
    FutureProvider.autoDispose.family<IsoPost?, String>(
  (ref, id) => ref.read(isoRepositoryProvider).getIso(id),
);

// ─── Offers on an ISO ─────────────────────────────────────────────────────────

/// Provides all offers on an ISO post (RLS-filtered by the database).
final isoOffersProvider =
    FutureProvider.autoDispose.family<List<IsoOffer>, String>(
  (ref, isoId) => ref.read(isoRepositoryProvider).getIsoOffers(isoId),
);

// ─── Current user's own offer on a specific ISO ──────────────────────────────

/// Provides the current user's own offer on a specific ISO post, or null.
final myIsoOfferProvider =
    FutureProvider.autoDispose.family<IsoOffer?, String>((ref, isoId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(isoRepositoryProvider).getMyOffer(isoId, user.id);
});

// ─── Unread ISO offer notification count ─────────────────────────────────────

/// Count of unread ISO offer notifications for the current user.
/// Non-autoDispose so the count persists across navigation (used in nav badge).
final isoUnreadNotificationsCountProvider =
    FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(isoRepositoryProvider).getUnreadNotificationsCount(user.id);
});

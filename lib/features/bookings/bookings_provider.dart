import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/push/push_service.dart';
import '../auth/auth_controller.dart';
import 'booking.dart';
import 'booking_api.dart';

final _tokenProvider = Provider<String>(
  (ref) =>
      ref.watch(authProvider.select((state) => state.user?.appToken ?? '')),
);

/// Open requests plus the dashboard counters. Refetches on login and
/// whenever a push comes in, so a new job shows up without a manual pull.
final bookingFeedProvider = FutureProvider.autoDispose<BookingFeed>((
  ref,
) async {
  final token = ref.watch(_tokenProvider);
  ref.watch(pushRefreshProvider);
  if (token.isEmpty) return BookingFeed.empty;
  return ref.watch(bookingApiProvider).getRequests(token);
});

/// Finished jobs, newest first.
final completedBookingsProvider = FutureProvider.autoDispose<List<Booking>>((
  ref,
) async {
  final token = ref.watch(_tokenProvider);
  if (token.isEmpty) return const [];
  return ref.watch(bookingApiProvider).getCompletedHistory(token);
});

/// Cancelled jobs. There is no dedicated endpoint for these yet, so this
/// filters whichever feed the API happens to place a cancelled row in.
final cancelledBookingsProvider = FutureProvider.autoDispose<List<Booking>>((
  ref,
) async {
  final feed = await ref.watch(bookingFeedProvider.future);
  final completed = await ref.watch(completedBookingsProvider.future);

  return [
    ...feed.bookings,
    ...completed,
  ].where((booking) => booking.status == BookingStatus.cancelled).toList();
});

/// Looks a booking up in whichever feed holds it, for the detail screen.
final bookingByIdProvider = FutureProvider.autoDispose.family<Booking?, int>((
  ref,
  id,
) async {
  final feed = await ref.watch(bookingFeedProvider.future);
  for (final booking in feed.bookings) {
    if (booking.id == id) return booking;
  }

  final completed = await ref.watch(completedBookingsProvider.future);
  for (final booking in completed) {
    if (booking.id == id) return booking;
  }
  return null;
});

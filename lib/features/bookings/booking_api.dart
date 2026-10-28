import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/json_parse.dart';
import 'booking.dart';

/// Wraps the booking feeds on `/api/ServiceProviderCategory/*`.
class BookingApi {
  const BookingApi(this._client);

  final ApiClient _client;

  /// Live requests, plus the `UpcomingJobs` / `CompletedJobs` counters the
  /// dashboard shows.
  Future<BookingFeed> getRequests(String appToken) async {
    final json = await _client.get(
      '/api/ServiceProviderCategory/requestbookingservicelist',
      query: {'appToken': appToken},
    );

    final counts = json['counts'];
    return BookingFeed(
      bookings: _bookings(json),
      upcomingCount: _count(counts, 'UpcomingJobs'),
      completedCount: _count(counts, 'CompletedJobs'),
    );
  }

  /// Finished jobs. This endpoint answers with `status: null` and no counts,
  /// so only the `data` array is trusted.
  Future<List<Booking>> getCompletedHistory(String appToken) async {
    final json = await _client.get(
      '/api/ServiceProviderCategory/requestCompletedHistory',
      query: {'appToken': appToken},
    );
    return _bookings(json);
  }

  /// Moves a request to a new `orderStatus`: "A" to accept, "C" to complete,
  /// "CANCEL" to cancel.
  Future<String> updateRequestStatus({
    required String appToken,
    required int serviceRequestId,
    required BookingStatus status,
    required int servicePartnerId,
  }) async {
    final json = await _client
        .post('/api/ServiceProviderCategory/updateServiceRequestStatus', {
          'appToken': appToken,
          'orderStatus': status.code,
          'SPID': servicePartnerId,
          'serviceRequestId': serviceRequestId,
        });

    final message = asString(json['message']);
    final outcome = asString(json['status']).toLowerCase();
    // Some endpoints here answer with a null status, so only an explicit
    // failure is treated as one.
    if (outcome.isNotEmpty && outcome != 'success') {
      throw ApiException(
        message.isEmpty ? 'Could not update this job.' : message,
      );
    }
    return message;
  }

  List<Booking> _bookings(Map<String, dynamic> json) {
    final data = json['data'];
    if (data == null) return const [];
    if (data is! List) {
      throw const ApiException('Unexpected response from the server.');
    }

    final bookings = [
      for (final row in data)
        if (row is Map<String, dynamic>) Booking.fromJson(row),
    ];

    // Newest first; rows with an unreadable date keep their server order.
    bookings.sort((a, b) {
      final left = a.createdOn;
      final right = b.createdOn;
      if (left == null || right == null) return 0;
      return right.compareTo(left);
    });

    // The API occasionally repeats a row (e.g. a job filed under more than
    // one category comes back once per category). Lists key widgets on
    // `booking.id`, so a repeat would crash them with a duplicate-key error.
    final seenIds = <int>{};
    return [
      for (final booking in bookings)
        if (seenIds.add(booking.id)) booking,
    ];
  }

  int _count(Object? counts, String key) =>
      counts is Map && counts[key] is num ? (counts[key] as num).toInt() : 0;
}

final bookingApiProvider = Provider<BookingApi>(
  (ref) => BookingApi(ref.watch(apiClientProvider)),
);

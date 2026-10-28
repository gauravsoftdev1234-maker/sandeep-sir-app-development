import 'package:flutter/foundation.dart';

import '../../core/network/json_parse.dart';

/// `orderStatus` on a booking row, as the API spells it.
enum BookingStatus {
  submitted('S', 'Submitted'),
  accepted('A', 'Accepted'),
  completed('C', 'Completed'),
  cancelled('CANCEL', 'Cancelled'),
  unknown('', 'Unknown');

  const BookingStatus(this.code, this.label);

  final String code;
  final String label;

  static BookingStatus fromCode(String code) {
    final normalised = code.trim().toUpperCase();
    for (final status in values) {
      if (status.code.isNotEmpty && status.code == normalised) return status;
    }
    return unknown;
  }
}

/// One row of `requestbookingservicelist` / `requestCompletedHistory`.
@immutable
class Booking {
  const Booking({
    required this.id,
    required this.userName,
    required this.mobileNumber,
    required this.categoryName,
    required this.subCategoryName,
    required this.cityName,
    required this.requirementDetail,
    required this.status,
    required this.createdOnRaw,
    this.createdOn,
    this.categoryId = 0,
    this.subCategoryId = 0,
    this.serviceProviderId = 0,
    this.customerId = 0,
  });

  final int id;
  final String userName;
  final String mobileNumber;
  final String categoryName;
  final String subCategoryName;
  final String cityName;
  final String requirementDetail;
  final BookingStatus status;

  /// Kept verbatim so an unparseable date still shows something.
  final String createdOnRaw;
  final DateTime? createdOn;

  final int categoryId;
  final int subCategoryId;
  final int serviceProviderId;
  final int customerId;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final createdOnRaw = asString(json['createdOn']).trim();
    return Booking(
      id: (json['bookingId'] as num?)?.toInt() ?? 0,
      userName: asString(json['userName']).trim(),
      mobileNumber: asString(json['mobileNumber']).trim(),
      categoryName: asString(json['categoryName']).trim(),
      subCategoryName: asString(json['subCategoryName']).trim(),
      cityName: asString(json['cityName']).trim(),
      requirementDetail: asString(json['requirementDetail']).trim(),
      status: BookingStatus.fromCode(asString(json['orderStatus'])),
      createdOnRaw: createdOnRaw,
      createdOn: parseApiDate(createdOnRaw),
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      subCategoryId: (json['subCategoryId'] as num?)?.toInt() ?? 0,
      serviceProviderId: (json['SPId'] as num?)?.toInt() ?? 0,
      customerId: (json['userId'] as num?)?.toInt() ?? 0,
    );
  }

  /// "15-09-2026 06:39" -> "15 Sep 2026, 6:39 AM".
  String get createdLabel {
    final date = createdOn;
    if (date == null) return createdOnRaw;
    final month = _months[date.month - 1];
    // 0 and 12 both read as 12 on a clock face.
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final meridiem = date.hour < 12 ? 'AM' : 'PM';
    return '${date.day} $month ${date.year}, $hour:$minute $meridiem';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

/// The API sends `dd-MM-yyyy HH:mm`, which `DateTime.parse` cannot read.
DateTime? parseApiDate(String raw) {
  final match = RegExp(
    r'^(\d{1,2})-(\d{1,2})-(\d{4})[ T](\d{1,2}):(\d{2})',
  ).firstMatch(raw.trim());
  if (match == null) return null;
  return DateTime(
    int.parse(match[3]!),
    int.parse(match[2]!),
    int.parse(match[1]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
  );
}

/// `requestbookingservicelist` also carries the dashboard counters.
@immutable
class BookingFeed {
  const BookingFeed({
    required this.bookings,
    required this.upcomingCount,
    required this.completedCount,
  });

  static const empty = BookingFeed(
    bookings: [],
    upcomingCount: 0,
    completedCount: 0,
  );

  final List<Booking> bookings;
  final int upcomingCount;
  final int completedCount;
}

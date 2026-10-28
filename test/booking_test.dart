import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/features/bookings/booking.dart';

Map<String, dynamic> _row(String status) => {
  'bookingId': 25,
  'SPId': 0,
  'userId': 3,
  'categoryId': 1,
  'subCategoryId': 52,
  'userName': 'Sandeep',
  'mobileNumber': '9507208908',
  'categoryName': 'Air Conditioner',
  'subCategoryName': 'AC Not Cooling Properly',
  'cityName': 'Sasaram',
  'createdOn': '15-09-2026 06:39',
  'orderStatus': status,
  'requirementDetail': 'not cooling',
};

void main() {
  test('maps every orderStatus the API sends', () {
    expect(BookingStatus.fromCode('S'), BookingStatus.submitted);
    expect(BookingStatus.fromCode('A'), BookingStatus.accepted);
    expect(BookingStatus.fromCode('C'), BookingStatus.completed);
    expect(BookingStatus.fromCode('CANCEL'), BookingStatus.cancelled);
    expect(BookingStatus.fromCode('cancel'), BookingStatus.cancelled);
    expect(BookingStatus.fromCode('Z'), BookingStatus.unknown);
  });

  test('reads a booking row', () {
    final booking = Booking.fromJson(_row('A'));

    expect(booking.id, 25);
    expect(booking.status, BookingStatus.accepted);
    expect(booking.status.label, 'Accepted');
    expect(booking.userName, 'Sandeep');
  });

  test('formats the dd-MM-yyyy HH:mm the API sends as a 12 hour clock', () {
    expect(Booking.fromJson(_row('S')).createdLabel, '15 Sep 2026, 6:39 AM');
  });

  test('reads afternoon and the two ends of the clock', () {
    String labelAt(String raw) =>
        Booking.fromJson(_row('S')..['createdOn'] = raw).createdLabel;

    expect(labelAt('21-09-2026 21:43'), '21 Sep 2026, 9:43 PM');
    // Midnight and noon are the cases a bare `% 12` gets wrong.
    expect(labelAt('21-09-2026 00:05'), '21 Sep 2026, 12:05 AM');
    expect(labelAt('21-09-2026 12:00'), '21 Sep 2026, 12:00 PM');
  });

  test('keeps an unreadable date verbatim', () {
    final row = _row('S')..['createdOn'] = 'not a date';

    expect(Booking.fromJson(row).createdOn, isNull);
    expect(Booking.fromJson(row).createdLabel, 'not a date');
  });
}

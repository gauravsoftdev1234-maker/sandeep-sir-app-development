import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/core/location/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unknown is the 0,0 the API treats as unset', () {
    expect(DeviceLocation.unknown.latitude, 0);
    expect(DeviceLocation.unknown.longitude, 0);
    expect(DeviceLocation.unknown.isKnown, isFalse);
  });

  test('a real fix reads as known', () {
    const patna = DeviceLocation(latitude: 25.5941, longitude: 85.1376);

    expect(patna.isKnown, isTrue);
  });

  test('falls back to unknown when the platform cannot answer', () async {
    // No plugin in a unit test, so this exercises the failure path.
    expect(await const LocationService().current(), DeviceLocation.unknown);
  });
}

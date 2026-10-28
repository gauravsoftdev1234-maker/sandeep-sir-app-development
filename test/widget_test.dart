import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/app.dart';
import 'package:partner_app/core/providers/shared_preferences_provider.dart';
import 'package:partner_app/core/location/location_service.dart';
import 'package:partner_app/core/theme/festival_theme.dart';
import 'package:partner_app/core/theme/header_skin.dart';
import 'package:partner_app/core/providers/splash_gate.dart';
import 'package:partner_app/features/auth/auth_api.dart';
import 'package:partner_app/features/auth/auth_models.dart';
import 'package:partner_app/features/auth/splash_screen.dart';
import 'package:partner_app/features/bookings/booking.dart';
import 'package:partner_app/features/bookings/booking_api.dart';
import 'package:partner_app/features/services/service_api.dart';
import 'package:partner_app/shared/widgets/celebration_dialog.dart';
import 'package:partner_app/features/services/service_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the real endpoints so tests never touch the network.
class FakeAuthApi implements AuthApi {
  FakeAuthApi({this.isServiceSelected = true, this.loginSucceeds = true});

  /// Mutable so a test can flip it the way the server does once onboarding
  /// is saved.
  bool isServiceSelected;
  final bool loginSucceeds;

  @override
  Future<ApiResult<AuthUser>> login({
    required String mobileNumber,
    required String password,
    String fcmToken = '',
  }) async {
    if (!loginSucceeds) {
      return const ApiResult(
        isSuccess: false,
        message: 'Invalid mobile number or password',
      );
    }
    return const ApiResult(
      isSuccess: true,
      message: 'Login Successful',
      data: AuthUser(id: 2, fullName: 'Test User', appToken: 'token-123'),
    );
  }

  @override
  Future<ApiResult<void>> register({
    required String userName,
    required String mobileNumber,
    required String emailId,
    required String password,
    required String confirmPassword,
    double latitude = 0,
    double longitude = 0,
  }) async => const ApiResult(isSuccess: true, message: 'Registered');

  @override
  Future<TokenStatus> validateToken(String appToken) async =>
      TokenStatus(isValid: true, isServiceSelected: isServiceSelected);
}

/// Stands in for `/api/ServiceProviderCategory/*`.
class FakeServiceApi implements ServiceApi {
  List<int>? saved;

  static Map<String, dynamic> _row(int id, String name, String type) => {
    'id': id,
    'categoryName': name,
    'subtitle': 'General Services',
    'categoryIcon': '',
    'serviceType': type,
    'description': null,
  };

  @override
  Future<List<ServiceCategory>> getCategories(String appToken) async => [
    ServiceCategory.fromJson(_row(1, 'Air Conditioner', 'H')),
    ServiceCategory.fromJson(_row(9, 'Laptop', 'T')),
  ];

  @override
  Future<String> addCategories({
    required String appToken,
    required List<int> categoryIds,
  }) async {
    saved = categoryIds;
    return 'Categories added successfully';
  }
}

/// Stands in for the booking feeds.
class FakeBookingApi implements BookingApi {
  FakeBookingApi({this.upcoming = 2, this.completed = 5});

  final int upcoming;
  final int completed;

  static Map<String, dynamic> _row(int id, String status, String sub) => {
    'bookingId': id,
    'SPId': 0,
    'userId': 3,
    'categoryId': 1,
    'subCategoryId': 52,
    'userName': 'Sandeep',
    'mobileNumber': '9507208908',
    'categoryName': 'Air Conditioner',
    'subCategoryName': sub,
    'cityName': 'Patna',
    'createdOn': '15-09-2026 06:39',
    'orderStatus': status,
    'requirementDetail': 'not cooling',
  };

  @override
  Future<BookingFeed> getRequests(String appToken) async => BookingFeed(
    bookings: [
      Booking.fromJson(_row(25, 'S', 'AC Not Cooling Properly')),
      Booking.fromJson(_row(23, 'S', 'AC Service')),
    ],
    upcomingCount: upcoming,
    completedCount: completed,
  );

  @override
  Future<List<Booking>> getCompletedHistory(String appToken) async => [
    Booking.fromJson(_row(24, 'C', 'Water Leakage from Indoor Unit')),
  ];

  /// Records the last status change so a test can assert on it.
  ({int id, String status, int spId})? statusUpdate;

  @override
  Future<String> updateRequestStatus({
    required String appToken,
    required int serviceRequestId,
    required BookingStatus status,
    required int servicePartnerId,
  }) async {
    statusUpdate = (
      id: serviceRequestId,
      status: status.code,
      spId: servicePartnerId,
    );
    return 'Updated';
  }
}

/// Stands in for the platform location plugin, which does not exist under
/// the test binding.
class FakeLocationService implements LocationService {
  const FakeLocationService({this.granted = true});

  final bool granted;

  LocationAccess get _access =>
      granted ? LocationAccess.ready : LocationAccess.denied;

  @override
  Future<LocationAccess> access() async => _access;

  @override
  Future<LocationAccess> requestPermission() async => _access;

  @override
  Future<DeviceLocation> current() async => granted
      ? const DeviceLocation(latitude: 25.5, longitude: 84.0)
      : DeviceLocation.unknown;
}

/// Targets a bottom-navigation destination, since some of these icons also
/// appear in the page content.
Finder _navIcon(IconData icon) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.byIcon(icon),
);

void main() {
  const storedUser = {
    'id': 2,
    'FullName': 'Test User',
    'AppToken': 'token-123',
    'ProfileImage': null,
  };

  Future<void> pumpApp(
    WidgetTester tester, {
    bool signedIn = false,
    FakeAuthApi? api,
    FakeServiceApi? serviceApi,
    FakeBookingApi? bookingApi,
    bool locationGranted = true,
  }) async {
    // Use a phone-sized viewport so screens lay out the way they do on device.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(
      signedIn ? {'auth_session': jsonEncode(storedUser)} : {},
    );
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authApiProvider.overrideWithValue(api ?? FakeAuthApi()),
          serviceApiProvider.overrideWithValue(serviceApi ?? FakeServiceApi()),
          bookingApiProvider.overrideWithValue(bookingApi ?? FakeBookingApi()),
          // Skip the splash hold so tests land on the real screen.
          splashMinimumDurationProvider.overrideWithValue(Duration.zero),
          // Location is a hard gate in the real app, and there is no
          // Geolocator plugin under the test binding, so grant it here.
          // `locationGranted: false` exercises the gate itself.
          locationServiceProvider.overrideWithValue(
            FakeLocationService(granted: locationGranted),
          ),
          // Pin the header to its ordinary dress. Otherwise these tests pass
          // or fail depending on the date: on Gandhi Jayanti or Christmas the
          // festival caption replaces the "Welcome back" line.
          festivalProvider.overrideWithValue(null),
          // The daytime header drifts clouds forever, so pumpAndSettle would
          // never return. Pin the header to its plain state.
          headerSkinProvider.overrideWithValue(null),
        ],
        child: const PartnerApp(),
      ),
    );
    if (locationGranted) {
      await tester.pumpAndSettle();
    } else {
      // The location gate pulses a radar ring forever, so there is nothing
      // to settle on — pump past the entrance animations instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }
  }

  testWidgets('survives a zero-sized first frame', (tester) async {
    // The entry screens are drawn before window metrics arrive, when the
    // available height can still be zero.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(0, 0);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authApiProvider.overrideWithValue(FakeAuthApi()),
          splashMinimumDurationProvider.overrideWithValue(Duration.zero),
        ],
        child: const PartnerApp(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('holds the brand splash before routing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authApiProvider.overrideWithValue(FakeAuthApi()),
          splashMinimumDurationProvider.overrideWithValue(
            const Duration(milliseconds: 400),
          ),
          locationServiceProvider.overrideWithValue(
            const FakeLocationService(),
          ),
          festivalProvider.overrideWithValue(null),
          // The daytime header drifts clouds forever, so pumpAndSettle would
          // never return. Pin the header to its plain state.
          headerSkinProvider.overrideWithValue(null),
        ],
        child: const PartnerApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('without location, not even the login screen opens', (
    tester,
  ) async {
    await pumpApp(tester, locationGranted: false);

    expect(find.text('Allow location'), findsWidgets);
    expect(find.text('Welcome Back'), findsNothing);
  });

  testWidgets('a stored session still cannot get in without location', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, locationGranted: false);

    expect(find.text('Allow location'), findsWidgets);
    expect(find.text('Test User'), findsNothing);
  });

  testWidgets('shows the login screen when there is no session', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Test User'), findsNothing);
  });

  testWidgets('rejects a mobile number that is not 10 digits', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).first, '12345');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a 10 digit mobile number'), findsOneWidget);
  });

  testWidgets('accepts a short password on sign-in', (tester) async {
    // Existing accounts may predate the 6-character rule we apply to new ones.
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).first, '6200075802');
    await tester.enterText(find.byType(TextFormField).last, '12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Use at least 6 characters'), findsNothing);
    expect(find.text('Test User'), findsOneWidget);
  });

  testWidgets('a successful login lands on the home screen', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).first, '9876543210');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsOneWidget);
    // Job counters render as two stat cards now, not a combined strip.
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Open jobs'), findsOneWidget);
  });

  testWidgets('a failed login shows the server message', (tester) async {
    await pumpApp(tester, api: FakeAuthApi(loginSucceeds: false));

    await tester.enterText(find.byType(TextFormField).first, '9876543210');
    await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid mobile number or password'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('a stored session restores straight into the app', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);

    expect(find.text('Test User'), findsOneWidget);
  });

  testWidgets('an unselected service routes to onboarding', (tester) async {
    await pumpApp(
      tester,
      signedIn: true,
      api: FakeAuthApi(isServiceSelected: false),
    );

    expect(find.text('Select your services'), findsOneWidget);
  });

  testWidgets('the jobs tab lists open requests and completed history', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);

    await tester.tap(_navIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();

    // Counts come from the API, not from the number of rows on screen.
    expect(find.text('Upcoming 2'), findsOneWidget);
    expect(find.text('Completed 5'), findsOneWidget);
    expect(find.text('AC Not Cooling Properly'), findsOneWidget);

    await tester.tap(find.text('Completed 5'));
    await tester.pumpAndSettle();

    expect(find.text('Water Leakage from Indoor Unit'), findsOneWidget);
    expect(find.text('AC Not Cooling Properly'), findsNothing);
  });

  testWidgets('a job row opens its detail screen', (tester) async {
    await pumpApp(tester, signedIn: true);

    await tester.tap(_navIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AC Not Cooling Properly'));
    await tester.pumpAndSettle();

    expect(find.text('Job details'), findsOneWidget);
    expect(find.text('#25'), findsOneWidget);
    expect(find.text('Sandeep'), findsOneWidget);
    expect(find.text('9507208908'), findsOneWidget);
    expect(find.text('15 Sep 2026, 6:39 AM'), findsOneWidget);
  });

  testWidgets('logging out returns to the login screen', (tester) async {
    await pumpApp(tester, signedIn: true);

    await tester.tap(_navIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // The profile page scrolls; the action sits below the account menu.
    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('onboarding lists the API categories by service type', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedIn: true,
      api: FakeAuthApi(isServiceSelected: false),
    );

    expect(find.text('Select your services'), findsOneWidget);
    expect(find.text('Home appliances'), findsOneWidget);
    expect(find.text('Technical'), findsOneWidget);
    expect(find.text('Air Conditioner'), findsOneWidget);
    expect(find.text('Laptop'), findsOneWidget);
  });

  testWidgets('Continue stays disabled until a service is ticked', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedIn: true,
      api: FakeAuthApi(isServiceSelected: false),
    );

    FilledButton continueButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );

    expect(continueButton().onPressed, isNull);

    await tester.tap(find.text('Air Conditioner'));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(continueButton().onPressed, isNotNull);
  });

  testWidgets('saving services routes to the dashboard and lists them there', (
    tester,
  ) async {
    final auth = FakeAuthApi(isServiceSelected: false);
    final services = FakeServiceApi();
    await pumpApp(tester, signedIn: true, api: auth, serviceApi: services);

    await tester.tap(find.text('Air Conditioner'));
    await tester.pumpAndSettle();

    // The server reports onboarding complete once the POST lands.
    auth.isServiceSelected = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(services.saved, [1]);
    expect(find.text('Select your services'), findsNothing);
    // Onboarding is done, so the dashboard takes over.
    expect(find.text('Test User'), findsOneWidget);
  });

  testWidgets('accepting an open job posts the status change', (tester) async {
    final bookings = FakeBookingApi();
    await pumpApp(tester, signedIn: true, bookingApi: bookings);

    await tester.tap(_navIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AC Not Cooling Properly'));
    await tester.pumpAndSettle();

    // The action sits below the detail rows on a phone-sized viewport.
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Accept job'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Accept job'));
    await tester.pumpAndSettle();

    // The stored session is user id 2.
    expect(bookings.statusUpdate?.id, 25);
    expect(bookings.statusUpdate?.status, 'A');
    expect(bookings.statusUpdate?.spId, 2);
    // The celebration dialog confirms it, with one of the praise lines.
    expect(find.text('Job accepted'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && Praise.lines.contains(widget.data),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a completed job offers no accept action', (tester) async {
    await pumpApp(tester, signedIn: true);

    await tester.tap(_navIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completed 5'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Water Leakage from Indoor Unit'));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Accept job'), findsNothing);
  });
}

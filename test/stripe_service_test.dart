import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_now_mobile/services/stripe_service.dart';
import 'package:toastification/toastification.dart';

class MockDio extends Mock implements Dio {}

class MockStripe extends Mock implements Stripe {}

class MockToastification extends Mock implements Toastification {}

class MockToastificationItem extends Mock implements ToastificationItem {}

class MockSetupPaymentSheetParameters extends Mock implements SetupPaymentSheetParameters {}

class MockDotEnv extends Mock implements DotEnv {
  final Map<String, String> _values = {};

  @override
  String? operator [](String key) => _values[key];

  @override
  void operator []=(String key, String value) {
    _values[key] = value;
  }

  @override
  Map<String, String> get env => _values;
}

// For registering fallback values
class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeOptions extends Fake implements Options {}

class FakeToastificationItem extends Fake implements ToastificationItem {}

class FakeText extends Fake implements Text {
  @override
  String toString({DiagnosticLevel? minLevel}) {
    return 'FakeText';
  }
}

class FakeSetupPaymentSheetParameters extends Fake implements SetupPaymentSheetParameters {}

void main() {
  // Set up global mocks
  late MockDotEnv mockDotEnv;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeOptions());
    registerFallbackValue(FakeToastificationItem());
    registerFallbackValue(FakeText());
    registerFallbackValue(ToastificationType.success);
    registerFallbackValue(ToastificationStyle.minimal);
    registerFallbackValue(const Duration(seconds: 3));
    registerFallbackValue(FakeSetupPaymentSheetParameters());

    // Set up mockDotEnv with test values
    mockDotEnv = MockDotEnv();
    mockDotEnv['SECRET_KEY'] = 'test_secret_key';

    // Install the mock
    DotEnvMock.setup(mockDotEnv);
  });

  group('Unit Tests', () {
    late StripeService stripeService;
    late MockDio mockDio;
    late MockToastification mockToast;
    late MockToastificationItem mockToastItem;

    setUp(() {
      mockDio = MockDio();
      mockToast = MockToastification();
      mockToastItem = MockToastificationItem();

      // Setup mock for toastification
      when(() => mockToast.show(
            title: any(named: 'title'),
            description: any(named: 'description'),
            type: any(named: 'type'),
            style: any(named: 'style'),
            autoCloseDuration: any(named: 'autoCloseDuration'),
          )).thenReturn(mockToastItem);

      // Get the singleton instance and set mocks
      stripeService = StripeService.instance
        ..dio = mockDio
        ..setToastification(mockToast);
    });

    test('calculateAmount converts correctly', () {
      expect(stripeService.calculateAmountForTesting(100), '10000');
      expect(stripeService.calculateAmountForTesting(50), '5000');
    });

    test('createPaymentIntent handles invalid amount', () async {
      expect(
        () => stripeService.createPaymentIntentForTesting(-1, 'usd'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createPaymentIntent handles Dio error', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => throw DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.unknown,
          ));

      final result = await stripeService.createPaymentIntentForTesting(100, 'usd');
      expect(result, isNull);
    });

    test('handlePaymentSheet shows success toast on success', () async {
      // Mock Stripe to avoid StripeConfigException
      final mockStripe = _MockStripeInstance();
      Stripe.instance = mockStripe;

      // Now we expect the toast to be called
      final result = await stripeService.handlePaymentSheetForTesting();
      expect(result, isTrue);

      verify(() => mockToast.show(
            title: any(named: 'title'),
            description: any(named: 'description'),
            type: ToastificationType.success,
            style: ToastificationStyle.minimal,
            autoCloseDuration: any(named: 'autoCloseDuration'),
          )).called(1);
    });
  });

  group('Integration Tests', () {
    late StripeService stripeService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      stripeService = StripeService.instance..dio = mockDio;

      // Set up Stripe mock for the integration test too
      Stripe.instance = _MockStripeInstance();
    });

    test('makePayment returns false when payment intent creation fails', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => throw DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.unknown,
          ));

      final result = await stripeService.makePayment(amount: 100, currency: "usd");
      expect(result, isFalse);
    });
  });

  group('Security Tests', () {
    test('No sensitive data in debug logs', () async {
      var logMessages = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => logMessages.add(message);

      try {
        final service = StripeService.instance;

        // Mock dio for this test
        final mockDio = MockDio();
        service.dio = mockDio;

        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response(
              data: {'client_secret': 'test_secret'},
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ));

        await service.createPaymentIntentForTesting(100, 'usd');

        expect(logMessages.any((msg) => msg?.contains('SECRET_KEY') ?? false), isFalse);
      } finally {
        // Restore the original debugPrint
        debugPrint = originalDebugPrint;
      }
    });

    test('Invalid currency input is rejected', () async {
      expect(
        () => StripeService.instance.createPaymentIntentForTesting(100, ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Performance Tests', () {
    test('Payment intent creation performance', () async {
      final stopwatch = Stopwatch()..start();
      final service = StripeService.instance;

      // Mock the Dio instance to return quickly
      final mockDio = MockDio();
      service.dio = mockDio;

      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {'client_secret': 'test_secret'},
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ));

      await service.createPaymentIntentForTesting(100, 'usd');
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}

// Helper class to set up dotenv mock
class DotEnvMock {
  static void setup(MockDotEnv mockEnv) {
    // Create a mock env map that will be used by the StripeService
    dotenv = mockEnv;
  }
}

// Properly mocked implementation of Stripe
class _MockStripeInstance implements Stripe {
  @override
  Future<PaymentSheetPaymentOption?> presentPaymentSheet(
      {PaymentSheetPresentOptions? options}) async {
    return null;
  }

  @override
  Future<void> confirmPaymentSheetPayment() async {
    return;
  }

  @override
  Future<PaymentSheetPaymentOption?> initPaymentSheet(
      {required SetupPaymentSheetParameters paymentSheetParameters}) async {
    return null;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MockStripe';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

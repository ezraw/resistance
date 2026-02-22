import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resistance_app/services/user_settings_service.dart';

void main() {
  group('UserSettingsService', () {
    late UserSettingsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = UserSettingsService(prefs);
    });

    group('maxHeartRate', () {
      test('returns null when not set', () {
        expect(service.maxHeartRate, isNull);
      });

      test('stores and retrieves a value', () {
        service.maxHeartRate = 190;
        expect(service.maxHeartRate, 190);
      });

      test('clears value when set to null', () {
        service.maxHeartRate = 190;
        service.maxHeartRate = null;
        expect(service.maxHeartRate, isNull);
      });

      test('overwrites previous value', () {
        service.maxHeartRate = 180;
        service.maxHeartRate = 195;
        expect(service.maxHeartRate, 195);
      });
    });

    group('ftp', () {
      test('returns null when not set', () {
        expect(service.ftp, isNull);
      });

      test('stores and retrieves a value', () {
        service.ftp = 200;
        expect(service.ftp, 200);
      });

      test('clears value when set to null', () {
        service.ftp = 200;
        service.ftp = null;
        expect(service.ftp, isNull);
      });

      test('overwrites previous value', () {
        service.ftp = 150;
        service.ftp = 250;
        expect(service.ftp, 250);
      });
    });

    test('maxHeartRate and ftp are independent', () {
      service.maxHeartRate = 190;
      service.ftp = 250;
      expect(service.maxHeartRate, 190);
      expect(service.ftp, 250);

      service.maxHeartRate = null;
      expect(service.maxHeartRate, isNull);
      expect(service.ftp, 250);
    });
  });
}

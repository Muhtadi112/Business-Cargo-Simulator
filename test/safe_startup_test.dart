import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:business_cargo_simulator/app/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Safe startup recovery', () {
    test('corrupted local save falls back to company creation', () async {
      SharedPreferences.setMockInitialValues({
        'business_cargo_simulator_save_v1': '{ this is not valid json',
      });

      final state = AppState();
      await state.initialize();

      expect(state.isInitialized, isTrue);
      expect(state.company, isNull);
      expect(state.needsCompanySetup, isTrue);

      state.dispose();
    });

    test('empty local storage starts without a company', () async {
      SharedPreferences.setMockInitialValues({});

      final state = AppState();
      await state.initialize();

      expect(state.isInitialized, isTrue);
      expect(state.company, isNull);
      expect(state.vehicles, isEmpty);
      expect(state.contracts, isEmpty);

      state.dispose();
    });
  });
}

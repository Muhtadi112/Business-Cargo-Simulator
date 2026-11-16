import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company.dart';
import '../models/contract.dart';
import '../models/vehicle.dart';

class SavedGame {
  const SavedGame({
    required this.company,
    required this.vehicles,
    required this.contracts,
  });

  final Company company;
  final List<Vehicle> vehicles;
  final List<CargoContract> contracts;
}

class SaveService {
  static const String _saveKey = 'business_cargo_simulator_save_v1';

  Future<bool> hasSave() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.containsKey(_saveKey);
    } catch (error) {
      debugPrint('Checking local save failed: $error');
      return false;
    }
  }

  Future<void> saveGame({
    required Company company,
    required List<Vehicle> vehicles,
    required List<CargoContract> contracts,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'schemaVersion': 1,
        'savedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'company': company.toJson(),
        'vehicles': vehicles.map((vehicle) => vehicle.toJson()).toList(),
        'contracts': contracts.map((contract) => contract.toJson()).toList(),
      };
      final saved = await preferences.setString(_saveKey, jsonEncode(payload));
      if (!saved) {
        debugPrint('SharedPreferences rejected the local save write.');
      }
    } catch (error, stackTrace) {
      debugPrint('Saving local game failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      // Persistence is best-effort and must not crash gameplay.
    }
  }

  Future<SavedGame?> loadGame() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_saveKey);
      if (encoded == null || encoded.trim().isEmpty) return null;

      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Format save tidak valid.');
      }
      final companyJson = decoded['company'];
      final vehicleJson = decoded['vehicles'];
      final contractJson = decoded['contracts'];
      if (companyJson is! Map<String, dynamic> ||
          vehicleJson is! List<dynamic> ||
          contractJson is! List<dynamic>) {
        throw const FormatException('Struktur save tidak lengkap.');
      }

      return SavedGame(
        company: Company.fromJson(companyJson),
        vehicles: vehicleJson
            .whereType<Map<String, dynamic>>()
            .map(Vehicle.fromJson)
            .toList(),
        contracts: contractJson
            .whereType<Map<String, dynamic>>()
            .map(CargoContract.fromJson)
            .toList(),
      );
    } catch (error, stackTrace) {
      debugPrint('Local save is missing or corrupted: $error');
      debugPrintStack(stackTrace: stackTrace);
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(_saveKey);
      } catch (_) {
        // Corrupt-data cleanup is optional; app startup still falls back.
      }
      return null;
    }
  }

  Future<void> resetGame() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_saveKey);
    } catch (error) {
      debugPrint('Resetting local save failed: $error');
    }
  }
}

import 'dart:convert';

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
    final preferences = await SharedPreferences.getInstance();
    return preferences.containsKey(_saveKey);
  }

  Future<void> saveGame({
    required Company company,
    required List<Vehicle> vehicles,
    required List<CargoContract> contracts,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'schemaVersion': 1,
      'savedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'company': company.toJson(),
      'vehicles': vehicles.map((vehicle) => vehicle.toJson()).toList(),
      'contracts': contracts.map((contract) => contract.toJson()).toList(),
    };
    final encoded = jsonEncode(payload);
    final saved = await preferences.setString(_saveKey, encoded);
    if (!saved) {
      throw StateError('Progress game gagal disimpan ke penyimpanan lokal.');
    }
  }

  Future<SavedGame?> loadGame() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_saveKey);
    if (encoded == null || encoded.isEmpty) return null;

    try {
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
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Save game tidak dapat dibaca: $error');
    }
  }

  Future<void> resetGame() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_saveKey);
  }
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:business_cargo_simulator/app/formatters.dart';
import 'package:business_cargo_simulator/models/city.dart';
import 'package:business_cargo_simulator/models/company.dart';
import 'package:business_cargo_simulator/models/contract.dart';
import 'package:business_cargo_simulator/models/vehicle.dart';
import 'package:business_cargo_simulator/services/contract_service.dart';
import 'package:business_cargo_simulator/services/fleet_service.dart';

void main() {
  group('Company model', () {
    test('creates a valid company with initial defaults', () {
      final company = Company.newCompany(
        id: 'company-test',
        name: '  ADIEXPRESS  ',
        headquartersCity: 'Jakarta',
        createdAtUtc: DateTime.utc(2026, 1, 1),
      );

      expect(company.id, 'company-test');
      expect(company.name, 'ADIEXPRESS');
      expect(company.level, 1);
      expect(company.balance, 50000);
      expect(company.unlockedCityIds, <String>['jakarta']);
      expect(company.createdAtUtc.isUtc, isTrue);
    });
  });

  group('City catalog', () {
    test('calculates Jakarta to Singapore distance using geographic coordinates', () {
      final jakarta = CityCatalog.byId('jakarta');
      final singapore = CityCatalog.byId('singapore');
      final distance = CityCatalog.distanceBetween(jakarta, singapore);

      expect(distance, greaterThan(880));
      expect(distance, lessThan(910));
    });

    test('returns zero distance for identical coordinates', () {
      expect(CityNode.distanceKmBetween(0, 0, 0, 0), 0);
    });
  });

  group('Contract service', () {
    test('generates the requested minimum set of valid local contracts', () {
      final company = Company.newCompany(
        id: 'company-test',
        name: 'ADIEXPRESS',
        headquartersCity: 'Jakarta',
      ).copyWith(unlockedCityIds: <String>['jakarta']);
      final service = ContractService(random: Random(7));
      final contracts = service.generateContractsForCompany(
        company,
        count: 5,
        nowUtc: DateTime.utc(2026, 1, 1),
      );

      expect(contracts, hasLength(5));
      expect(contracts.every((item) => item.status == ContractStatus.available), isTrue);
      expect(contracts.every((item) => item.reward > 0), isTrue);
      expect(contracts.every((item) => item.rewardXp > 0), isTrue);
      expect(contracts.every((item) => item.originCityId == 'jakarta'), isTrue);
    });
  });

  group('Fleet service', () {
    test('completes a trip when its UTC arrival timestamp has passed', () {
      final company = Company.newCompany(
        id: 'company-test',
        name: 'ADIEXPRESS',
        headquartersCity: 'Jakarta',
      );
      final vehicle = Vehicle.starter(vehicleId: 'vehicle-test');
      final departure = DateTime.utc(2026, 1, 1, 8);
      const contract = CargoContract(
        contractId: 'contract-test',
        originCityId: 'jakarta',
        originCityName: 'Jakarta',
        destinationCityId: 'singapore',
        destinationCityName: 'Singapore',
        cargoType: CargoType.parcels,
        cargoWeightKg: 500,
        distanceKm: 100,
        reward: 1000,
        rewardXp: 100,
        departureTimeUtc: null,
        arrivalTimeUtc: null,
        status: ContractStatus.available,
      );
      final service = FleetService();
      final assignment = service.assignContract(
        vehicle,
        contract,
        nowUtc: departure,
      );

      expect(assignment.contract.status, ContractStatus.inTransit);
      expect(assignment.vehicle.status, VehicleStatus.enRoute);
      expect(assignment.contract.departureTimeUtc!.isUtc, isTrue);
      expect(assignment.contract.arrivalTimeUtc!.isUtc, isTrue);

      final resolution = service.resolveArrivedTrips(
        company: company,
        vehicles: <Vehicle>[assignment.vehicle],
        contracts: <CargoContract>[assignment.contract],
        nowUtc: assignment.contract.arrivalTimeUtc!.add(const Duration(seconds: 1)),
      );

      expect(resolution.completedContractIds, <String>['contract-test']);
      expect(resolution.contracts.single.status, ContractStatus.completed);
      expect(resolution.vehicles.single.status, VehicleStatus.idle);
      expect(resolution.company.balance, company.balance + contract.reward);
      expect(resolution.company.completedContracts, 1);
    });

    test('rejects a trip when the vehicle cannot carry the cargo', () {
      final service = FleetService();
      final vehicle = Vehicle.starter(vehicleId: 'vehicle-small');
      const contract = CargoContract(
        contractId: 'heavy-contract',
        originCityId: 'jakarta',
        originCityName: 'Jakarta',
        destinationCityId: 'singapore',
        destinationCityName: 'Singapore',
        cargoType: CargoType.machinery,
        cargoWeightKg: 5000,
        distanceKm: 100,
        reward: 1000,
        rewardXp: 100,
        departureTimeUtc: null,
        arrivalTimeUtc: null,
        status: ContractStatus.available,
      );

      expect(
        () => service.assignContract(vehicle, contract, nowUtc: DateTime.utc(2026)),
        throwsStateError,
      );
    });
  });

  group('Game formatters', () {
    test('formats currency, distance, weight and duration consistently', () {
      expect(AppFormatters.money(1234), r'$1,234');
      expect(AppFormatters.distance(12.34), '12.3 km');
      expect(AppFormatters.weight(1500), '1.5 t');
      expect(AppFormatters.duration(const Duration(minutes: 90)), '1h 30m');
      expect(AppFormatters.percentage(75), '75%');
    });
  });
}

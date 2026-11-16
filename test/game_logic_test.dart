import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:business_cargo_simulator/app/formatters.dart';
import 'package:business_cargo_simulator/models/city.dart';
import 'package:business_cargo_simulator/models/company.dart';
import 'package:business_cargo_simulator/models/fuel_system.dart';
import 'package:business_cargo_simulator/models/research.dart';
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

  group('Company progression systems', () {
    test('persists fuel tanks, terminal unlocks, research and goal progress', () {
      final company = Company.newCompany(id: 'progress', name: 'ADI').copyWith(
        fuelSystem: const FuelSystem(diesel: FuelTank(type: FuelType.diesel, level: 2, storedLiters: 4500)),
        depotLevel: 3,
        airportBranchBuilt: true,
        researchLevels: const <String, int>{'efficientEngines': 4},
        dailyDeliveries: 2,
      );
      final restored = Company.fromJson(company.toJson());
      expect(restored.fuelSystem.diesel.level, 2);
      expect(restored.fuelSystem.diesel.storedLiters, 4500);
      expect(restored.depotLevel, 3);
      expect(restored.airportBranchBuilt, isTrue);
      expect(restored.researchLevel('efficientEngines'), 4);
      expect(restored.dailyDeliveries, 2);
    });
    test('research catalog exposes six ten-level upgrades', () {
      expect(ResearchDefinition.all, hasLength(6));
      expect(ResearchRules.maxLevel, 10);
      expect(ResearchRules.upgradeCost(ResearchCategory.efficientEngines, 1), greaterThan(ResearchRules.upgradeCost(ResearchCategory.efficientEngines, 0)));
    });
    test('reputation score maps to the five requested titles', () {
      final base = Company.newCompany(id: 'rank', name: 'ADI');
      expect(base.reputationTitle, 'Pendatang Baru');
      expect(base.copyWith(reputationScore: 1200).reputationTitle, 'Operator Berkembang');
      expect(base.copyWith(reputationScore: 3200).reputationTitle, 'Mitra Elite');
      expect(base.copyWith(reputationScore: 6200).reputationTitle, 'Tycoon Global');
      expect(base.copyWith(reputationScore: 9200).reputationTitle, 'Legenda Logistik');
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

    test('contains a global city network with valid tiers and unique IDs', () {
      final cities = CityCatalog.allCities;
      expect(cities.length, greaterThanOrEqualTo(150));
      expect(cities.map((city) => city.id).toSet().length, cities.length);
      expect(cities.every((city) => city.tier >= 1 && city.tier <= 3), isTrue);
      expect(cities.every((city) =>
        city.latitude >= -90 && city.latitude <= 90 &&
        city.longitude >= -180 && city.longitude <= 180), isTrue);
      expect(CityCatalog.starterCities.map((city) => city.name), containsAll([
        'Jakarta','Singapore','Tokyo','Dubai','Rotterdam','London',
        'New York','Los Angeles','Sao Paulo','Johannesburg','Sydney',
      ]));
    });

    test('returns zero distance for identical coordinates', () {
      expect(CityNode.distanceKmBetween(0, 0, 0, 0), 0);
    });
  });

  group('Multi-modal logistics', () {
    test('catalog contains road, sea and air fleets', () {
      expect(VehicleCatalog.catalog.map((v) => v.mode).toSet(),
          containsAll(TransportMode.values));
      expect(VehicleCatalog.forTier(VehicleTier.coastalContainerFeeder).cargoCapacityKg,
          greaterThan(1000000));
      expect(VehicleCatalog.forTier(VehicleTier.wideBodyJetFreighter).maxSpeedKmh,
          greaterThan(800));
    });

    test('major cities expose port and airport facilities', () {
      final jakarta = CityCatalog.byId('jakarta');
      final singapore = CityCatalog.byId('singapore');
      expect(jakarta.hasPort, isTrue);
      expect(jakarta.hasAirport, isTrue);
      expect(singapore.hasPort, isTrue);
      expect(singapore.hasAirport, isTrue);
    });

    test('road fleet cannot accept a sea contract', () {
      final vehicle = Vehicle.starter(vehicleId: 'road-only');
      final contract = CargoContract(
        contractId: 'sea-only', originCityId: 'jakarta',
        originCityName: 'Jakarta', destinationCityId: 'singapore',
        destinationCityName: 'Singapore', cargoType: CargoType.electronics,
        cargoWeightKg: 500, distanceKm: 900, reward: 100000,
        rewardXp: 500, departureTimeUtc: null, arrivalTimeUtc: null,
        status: ContractStatus.available, transportMode: TransportMode.sea,
        originTerminal: TerminalType.containerPort,
        destinationTerminal: TerminalType.containerPort,
      );
      expect(() => FleetService().assignContract(vehicle, contract,
          nowUtc: DateTime.utc(2026)), throwsStateError);
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

    test('food cargo receives weekly event pay bonus at dispatch', () {
      final vehicle = Vehicle.starter(vehicleId: 'event-van');
      const contract = CargoContract(contractId: 'food-event', originCityId: 'jakarta', originCityName: 'Jakarta', destinationCityId: 'jakarta', destinationCityName: 'Jakarta', cargoType: CargoType.food, cargoWeightKg: 500, distanceKm: 10, reward: 1000, rewardXp: 10, departureTimeUtc: null, arrivalTimeUtc: null, status: ContractStatus.available);
      final assignment = FleetService().assignContract(vehicle, contract, nowUtc: DateTime.utc(2026, 11, 16));
      expect(assignment.contract.reward, 1250);
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
      expect(AppFormatters.money(1234), r'$1.2K');
      expect(GameFormatters.currency(600000), r'$600K');
      expect(GameFormatters.currency(2250000), r'$2.25M');
      expect(AppFormatters.distance(12.34), '12.3 km');
      expect(AppFormatters.weight(1500), '1.5 t');
      expect(AppFormatters.duration(const Duration(minutes: 90)), '1h 30m');
      expect(AppFormatters.percentage(75), '75%');
    });
  });
}

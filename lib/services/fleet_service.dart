import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/company.dart';
import '../models/contract.dart';
import '../models/vehicle.dart';

class FleetAssignment {
  const FleetAssignment({required this.vehicle, required this.contract});

  final Vehicle vehicle;
  final CargoContract contract;
}

class FleetResolution {
  const FleetResolution({
    required this.company,
    required this.vehicles,
    required this.contracts,
    required this.completedContractIds,
  });

  final Company company;
  final List<Vehicle> vehicles;
  final List<CargoContract> contracts;
  final List<String> completedContractIds;
}

class FleetService {
  FleetService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  FleetAssignment assignContract(
    Vehicle vehicle,
    CargoContract contract, {
    DateTime? nowUtc,
  }) {
    if (contract.status != ContractStatus.available) {
      throw StateError('Kontrak ini sudah tidak tersedia.');
    }
    if (!vehicle.canDrive) {
      throw StateError('Kendaraan tidak siap berangkat.');
    }
    if (!vehicle.canCarry(contract.cargoWeightKg)) {
      throw StateError('Kapasitas kendaraan tidak mencukupi.');
    }

    final fuelNeeded = requiredFuelForDistance(vehicle, contract.distanceKm);
    if (vehicle.fuel + 0.0001 < fuelNeeded) {
      throw StateError(
        'BBM tidak cukup. Dibutuhkan ${fuelNeeded.toStringAsFixed(1)} L.',
      );
    }

    final departure = (nowUtc ?? DateTime.now()).toUtc();
    final speed = max(1.0, vehicle.effectiveMaxSpeed);
    final travelHours = contract.distanceKm / speed;
    final travelDuration = Duration(
      microseconds: (travelHours * Duration.microsecondsPerHour).round(),
    );
    final arrival = departure.add(travelDuration);

    final dispatchedVehicle = vehicle.copyWith(
      status: VehicleStatus.enRoute,
      assignedContractId: contract.contractId,
      departureTimeUtc: departure,
      arrivalTimeUtc: arrival,
    );
    final dispatchedContract = contract.copyWith(
      status: ContractStatus.inTransit,
      assignedVehicleId: vehicle.vehicleId,
      departureTimeUtc: departure,
      arrivalTimeUtc: arrival,
    );
    return FleetAssignment(
      vehicle: dispatchedVehicle,
      contract: dispatchedContract,
    );
  }

  FleetResolution resolveArrivedTrips({
    required Company company,
    required List<Vehicle> vehicles,
    required List<CargoContract> contracts,
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final updatedVehicles = List<Vehicle>.of(vehicles);
    final updatedContracts = List<CargoContract>.of(contracts);
    var updatedCompany = company;
    final completedIds = <String>[];

    for (var contractIndex = 0;
        contractIndex < updatedContracts.length;
        contractIndex++) {
      final contract = updatedContracts[contractIndex];
      final arrival = contract.arrivalTimeUtc;
      if (contract.status != ContractStatus.inTransit ||
          arrival == null ||
          arrival.isAfter(now)) {
        continue;
      }

      final vehicleIndex = updatedVehicles.indexWhere(
        (vehicle) => vehicle.vehicleId == contract.assignedVehicleId,
      );
      if (vehicleIndex < 0) continue;

      final vehicle = updatedVehicles[vehicleIndex];
      final fuelUsed = requiredFuelForDistance(vehicle, contract.distanceKm);
      final wear = min(
        35.0,
        max(1.0, contract.distanceKm / 180.0 + vehicle.specifications.fuelConsumptionPer100Km / 18),
      );
      final updatedVehicle = vehicle.copyWith(
        fuel: max(0.0, vehicle.fuel - fuelUsed),
        condition: max(0.0, vehicle.condition - wear),
        status: VehicleStatus.idle,
        clearAssignedContract: true,
        clearDepartureTime: true,
        clearArrivalTime: true,
      );
      updatedVehicles[vehicleIndex] = updatedVehicle;

      updatedContracts[contractIndex] = contract.copyWith(
        status: ContractStatus.completed,
      );

      var xp = updatedCompany.xp + contract.rewardXp;
      var level = updatedCompany.level;
      while (xp >= level * 500) {
        xp -= level * 500;
        level++;
      }
      updatedCompany = updatedCompany.copyWith(
        balance: updatedCompany.balance + contract.reward,
        totalRevenue: updatedCompany.totalRevenue + contract.reward,
        xp: xp,
        level: level,
        reputation: min(100, updatedCompany.reputation + 1),
        completedContracts: updatedCompany.completedContracts + 1,
      );
      completedIds.add(contract.contractId);
    }

    return FleetResolution(
      company: updatedCompany,
      vehicles: updatedVehicles,
      contracts: updatedContracts,
      completedContractIds: completedIds,
    );
  }

  Vehicle createPurchasedVehicle(VehicleTier tier) {
    final specification = VehicleCatalog.forTier(tier);
    return Vehicle(
      vehicleId: _uuid.v4(),
      tier: tier,
      engineLevel: 1,
      cargoLevel: 1,
      fuel: specification.fuelCapacityLiters,
      condition: 100,
      status: VehicleStatus.idle,
    );
  }

  double requiredFuelForDistance(Vehicle vehicle, double distanceKm) {
    final baseFuel = distanceKm *
        vehicle.specifications.fuelConsumptionPer100Km /
        100;
    return baseFuel * 1.15;
  }

  double calculateRefuelCost(Vehicle vehicle, {double pricePerLiter = 1.65}) {
    final missingFuel =
        max(0.0, vehicle.specifications.fuelCapacityLiters - vehicle.fuel);
    return missingFuel * pricePerLiter;
  }

  double calculateRepairCost(Vehicle vehicle) {
    final missingCondition = max(0.0, 100 - vehicle.condition);
    return missingCondition *
        vehicle.specifications.maintenanceCost /
        100;
  }

  Vehicle refuelAndRepair(Vehicle vehicle) {
    return vehicle.copyWith(
      fuel: vehicle.specifications.fuelCapacityLiters,
      condition: 100,
      status: VehicleStatus.idle,
      clearAssignedContract: true,
      clearDepartureTime: true,
      clearArrivalTime: true,
    );
  }
}

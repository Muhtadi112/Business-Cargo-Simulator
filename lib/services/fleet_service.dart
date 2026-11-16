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
  const FleetResolution({required this.company, required this.vehicles, required this.contracts, required this.completedContractIds});
  final Company company;
  final List<Vehicle> vehicles;
  final List<CargoContract> contracts;
  final List<String> completedContractIds;
}

class FleetService {
  FleetService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();
  final Uuid _uuid;

  FleetAssignment assignContract(Vehicle vehicle, CargoContract contract, {DateTime? nowUtc, int fuelEfficiencyLevel = 0, int loadingCrewLevel = 0, int dispatchSoftwareLevel = 0}) {
    if (contract.status != ContractStatus.available) throw StateError('Kontrak ini sudah tidak tersedia.');
    if (!vehicle.canDrive) throw StateError('Kendaraan tidak siap berangkat.');
    if (vehicle.mode != contract.transportMode) throw StateError('Moda tidak cocok: kontrak ${contract.transportMode.name}, armada ${vehicle.mode.name}.');
    final terminal = switch (contract.transportMode) {
      TransportMode.road => TerminalType.warehouse,
      TransportMode.sea => TerminalType.containerPort,
      TransportMode.air => TerminalType.airport,
    };
    if (contract.originTerminal != terminal || contract.destinationTerminal != terminal) {
      throw StateError('Terminal asal dan tujuan tidak sesuai dengan moda transportasi.');
    }
    if (!vehicle.canCarry(contract.cargoWeightKg)) throw StateError('Kapasitas kendaraan tidak mencukupi.');
    final fuelNeeded = requiredFuelForDistance(vehicle, contract.distanceKm) * (1 - fuelEfficiencyLevel.clamp(0, 10) * 0.025);
    if (vehicle.fuel + 0.0001 < fuelNeeded) throw StateError('Bahan bakar tidak cukup. Dibutuhkan ${fuelNeeded.toStringAsFixed(1)} L.');
    final departure = (nowUtc ?? DateTime.now()).toUtc();
    final speed = max(1.0, vehicle.effectiveMaxSpeed);
    final travelHours = contract.distanceKm / speed;
    final handlingMinutes = 20 * (1 - loadingCrewLevel.clamp(0, 10) * 0.04);
    final dispatchMinutes = 5 * (1 - dispatchSoftwareLevel.clamp(0, 10) * 0.04);
    final travelDuration = Duration(microseconds: (travelHours * Duration.microsecondsPerHour).round()) + Duration(seconds: ((handlingMinutes + dispatchMinutes) * 60).round());
    final arrival = departure.add(travelDuration);
    return FleetAssignment(
      vehicle: vehicle.copyWith(status: VehicleStatus.enRoute, assignedContractId: contract.contractId, departureTimeUtc: departure, arrivalTimeUtc: arrival),
      contract: contract.copyWith(status: ContractStatus.inTransit, assignedVehicleId: vehicle.vehicleId, departureTimeUtc: departure, arrivalTimeUtc: arrival, reward: contract.reward * (contract.cargoType == CargoType.food ? 1.25 : 1.0)),
    );
  }

  FleetResolution resolveArrivedTrips({required Company company, required List<Vehicle> vehicles, required List<CargoContract> contracts, DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final updatedVehicles = List<Vehicle>.of(vehicles);
    final updatedContracts = List<CargoContract>.of(contracts);
    var updatedCompany = company;
    final completedIds = <String>[];
    for (var i = 0; i < updatedContracts.length; i++) {
      final contract = updatedContracts[i];
      final arrival = contract.arrivalTimeUtc;
      if (contract.status != ContractStatus.inTransit || arrival == null || arrival.isAfter(now)) continue;
      final vehicleIndex = updatedVehicles.indexWhere((v) => v.vehicleId == contract.assignedVehicleId);
      if (vehicleIndex < 0) continue;
      final vehicle = updatedVehicles[vehicleIndex];
      final fuelUsed = (requiredFuelForDistance(vehicle, contract.distanceKm) * (1 - company.researchLevel('efficientEngines').clamp(0, 10) * 0.025)).toDouble();
      final wear = (min(35.0, max(1.0, contract.distanceKm / 180.0 + vehicle.specifications.fuelConsumptionPer100Km / 18)) * (1 - company.researchLevel('fleetEngineering').clamp(0, 10) * 0.03)).toDouble();
      updatedVehicles[vehicleIndex] = vehicle.copyWith(fuel: max(0.0, vehicle.fuel - fuelUsed), condition: max(0.0, vehicle.condition - wear), status: VehicleStatus.idle, clearAssignedContract: true, clearDepartureTime: true, clearArrivalTime: true);
      updatedContracts[i] = contract.copyWith(status: ContractStatus.completed);
      var xp = updatedCompany.xp + contract.rewardXp;
      var level = updatedCompany.level;
      while (xp >= level * 500) { xp -= level * 500; level++; }
      final reward = (contract.reward * (1 + updatedCompany.researchLevel('keyClients').clamp(0, 10) * 0.02)).toDouble();
      updatedCompany = updatedCompany.copyWith(balance: updatedCompany.balance + reward, totalRevenue: updatedCompany.totalRevenue + reward, xp: xp, level: level, reputation: min(100, updatedCompany.reputation + 1), reputationScore: updatedCompany.reputationScore + 25, completedContracts: updatedCompany.completedContracts + 1);
      completedIds.add(contract.contractId);
    }
    return FleetResolution(company: updatedCompany, vehicles: updatedVehicles, contracts: updatedContracts, completedContractIds: completedIds);
  }

  Vehicle createPurchasedVehicle(VehicleTier tier) {
    final spec = VehicleCatalog.forTier(tier);
    return Vehicle(vehicleId: _uuid.v4(), tier: tier, engineLevel: 1, cargoLevel: 1, fuel: spec.fuelCapacityLiters, condition: 100, status: VehicleStatus.idle);
  }

  double requiredFuelForDistance(Vehicle vehicle, double distanceKm) => distanceKm * vehicle.specifications.fuelConsumptionPer100Km / 100 * 1.15;
  double calculateRefuelCost(Vehicle vehicle, {double pricePerLiter = 1.65}) {
    final missing = max(0.0, vehicle.specifications.fuelCapacityLiters - vehicle.fuel);
    final factor = vehicle.mode == TransportMode.sea ? 0.08 : vehicle.mode == TransportMode.air ? 2.8 : 1.0;
    return missing * pricePerLiter * factor;
  }
  double calculateRepairCost(Vehicle vehicle) => max(0.0, 100 - vehicle.condition) * vehicle.specifications.maintenanceCost / 100;
  Vehicle refuelAndRepair(Vehicle vehicle) => vehicle.copyWith(fuel: vehicle.specifications.fuelCapacityLiters, condition: 100, status: VehicleStatus.idle, clearAssignedContract: true, clearDepartureTime: true, clearArrivalTime: true);
}

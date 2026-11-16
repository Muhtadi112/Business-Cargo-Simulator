enum TransportMode { road, sea, air }

enum VehicleTier {
  lightVan,
  mediumBoxTruck,
  europeanSemiTruck,
  americanHeavyTruck,
  coastalContainerFeeder,
  postPanamaxContainerShip,
  turbopropRegionalCargoPlane,
  wideBodyJetFreighter,
}

enum VehicleStatus { idle, enRoute, maintenance }

class VehicleCatalogEntry {
  const VehicleCatalogEntry({
    required this.tier,
    required this.mode,
    required this.name,
    required this.purchasePrice,
    required this.cargoCapacityKg,
    required this.maxSpeedKmh,
    required this.fuelCapacityLiters,
    required this.fuelConsumptionPer100Km,
    required this.maintenanceCost,
    this.fuelLabel = 'Diesel',
  });

  final VehicleTier tier;
  final TransportMode mode;
  final String name;
  final double purchasePrice;
  final double cargoCapacityKg;
  final double maxSpeedKmh;
  final double fuelCapacityLiters;
  final double fuelConsumptionPer100Km;
  final double maintenanceCost;
  final String fuelLabel;
}

abstract final class VehicleCatalog {
  static const List<VehicleCatalogEntry> catalog = <VehicleCatalogEntry>[
    VehicleCatalogEntry(tier: VehicleTier.lightVan, mode: TransportMode.road, name: 'Light Delivery Van', purchasePrice: 12000, cargoCapacityKg: 1200, maxSpeedKmh: 110, fuelCapacityLiters: 80, fuelConsumptionPer100Km: 10, maintenanceCost: 450, fuelLabel: 'Bensin'),
    VehicleCatalogEntry(tier: VehicleTier.mediumBoxTruck, mode: TransportMode.road, name: 'Medium Box Truck', purchasePrice: 42000, cargoCapacityKg: 7500, maxSpeedKmh: 95, fuelCapacityLiters: 180, fuelConsumptionPer100Km: 22, maintenanceCost: 1250),
    VehicleCatalogEntry(tier: VehicleTier.europeanSemiTruck, mode: TransportMode.road, name: 'European Semi-Truck', purchasePrice: 115000, cargoCapacityKg: 24000, maxSpeedKmh: 90, fuelCapacityLiters: 600, fuelConsumptionPer100Km: 30, maintenanceCost: 3200),
    VehicleCatalogEntry(tier: VehicleTier.americanHeavyTruck, mode: TransportMode.road, name: 'American Heavy Truck', purchasePrice: 145000, cargoCapacityKg: 30000, maxSpeedKmh: 85, fuelCapacityLiters: 700, fuelConsumptionPer100Km: 36, maintenanceCost: 4100),
    VehicleCatalogEntry(tier: VehicleTier.coastalContainerFeeder, mode: TransportMode.sea, name: 'Coastal Container Feeder', purchasePrice: 680000, cargoCapacityKg: 18000000, maxSpeedKmh: 32, fuelCapacityLiters: 1800000, fuelConsumptionPer100Km: 4200, maintenanceCost: 18000, fuelLabel: 'Bunker fuel'),
    VehicleCatalogEntry(tier: VehicleTier.postPanamaxContainerShip, mode: TransportMode.sea, name: 'Post-Panamax Container Ship', purchasePrice: 4200000, cargoCapacityKg: 180000000, maxSpeedKmh: 46, fuelCapacityLiters: 8500000, fuelConsumptionPer100Km: 12500, maintenanceCost: 95000, fuelLabel: 'Marine fuel'),
    VehicleCatalogEntry(tier: VehicleTier.turbopropRegionalCargoPlane, mode: TransportMode.air, name: 'Turboprop Regional Cargo Plane', purchasePrice: 1250000, cargoCapacityKg: 9000, maxSpeedKmh: 520, fuelCapacityLiters: 12000, fuelConsumptionPer100Km: 850, maintenanceCost: 26000, fuelLabel: 'Jet A-1'),
    VehicleCatalogEntry(tier: VehicleTier.wideBodyJetFreighter, mode: TransportMode.air, name: 'Wide-Body Jet Freighter / Jumbo Cargo', purchasePrice: 18500000, cargoCapacityKg: 120000, maxSpeedKmh: 900, fuelCapacityLiters: 190000, fuelConsumptionPer100Km: 1500, maintenanceCost: 240000, fuelLabel: 'Jet A-1'),
  ];

  static List<VehicleCatalogEntry> get entries => catalog;
  static VehicleCatalogEntry forTier(VehicleTier tier) => catalog.firstWhere((entry) => entry.tier == tier);
}

class Vehicle {
  const Vehicle({required this.vehicleId, required this.tier, required this.engineLevel, required this.cargoLevel, required this.fuel, required this.condition, required this.status, this.assignedContractId, this.departureTimeUtc, this.arrivalTimeUtc});
  final String vehicleId;
  final VehicleTier tier;
  final int engineLevel;
  final int cargoLevel;
  final double fuel;
  final double condition;
  final VehicleStatus status;
  final String? assignedContractId;
  final DateTime? departureTimeUtc;
  final DateTime? arrivalTimeUtc;
  factory Vehicle.starter({required String vehicleId}) {
    final spec = VehicleCatalog.forTier(VehicleTier.lightVan);
    return Vehicle(vehicleId: vehicleId, tier: VehicleTier.lightVan, engineLevel: 1, cargoLevel: 1, fuel: spec.fuelCapacityLiters, condition: 100, status: VehicleStatus.idle);
  }
  VehicleCatalogEntry get specifications => VehicleCatalog.forTier(tier);
  TransportMode get mode => specifications.mode;
  double get cargoCapacity => specifications.cargoCapacityKg * (1 + (cargoLevel - 1) * 0.08);
  double get effectiveMaxSpeed => specifications.maxSpeedKmh * (1 + (engineLevel - 1) * 0.04);
  double get estimatedValue => specifications.purchasePrice * (0.55 + condition / 220);
  bool get canDrive => status == VehicleStatus.idle && condition > 0 && fuel > 0;
  bool canCarry(double weightKg) => weightKg <= cargoCapacity;
  Vehicle copyWith({String? vehicleId, VehicleTier? tier, int? engineLevel, int? cargoLevel, double? fuel, double? condition, VehicleStatus? status, String? assignedContractId, bool clearAssignedContract = false, DateTime? departureTimeUtc, bool clearDepartureTime = false, DateTime? arrivalTimeUtc, bool clearArrivalTime = false}) => Vehicle(
    vehicleId: vehicleId ?? this.vehicleId, tier: tier ?? this.tier, engineLevel: engineLevel ?? this.engineLevel, cargoLevel: cargoLevel ?? this.cargoLevel, fuel: fuel ?? this.fuel, condition: condition ?? this.condition, status: status ?? this.status,
    assignedContractId: clearAssignedContract ? null : assignedContractId ?? this.assignedContractId,
    departureTimeUtc: clearDepartureTime ? null : departureTimeUtc ?? this.departureTimeUtc,
    arrivalTimeUtc: clearArrivalTime ? null : arrivalTimeUtc ?? this.arrivalTimeUtc,
  );
  Map<String, dynamic> toJson() => {'vehicleId': vehicleId, 'tier': tier.name, 'engineLevel': engineLevel, 'cargoLevel': cargoLevel, 'fuel': fuel, 'condition': condition, 'status': status.name, 'assignedContractId': assignedContractId, 'departureTimeUtc': departureTimeUtc?.toUtc().toIso8601String(), 'arrivalTimeUtc': arrivalTimeUtc?.toUtc().toIso8601String()};
  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    vehicleId: json['vehicleId'] as String,
    tier: VehicleTier.values.firstWhere((value) => value.name == json['tier'], orElse: () => VehicleTier.lightVan),
    engineLevel: (json['engineLevel'] as num?)?.toInt() ?? 1, cargoLevel: (json['cargoLevel'] as num?)?.toInt() ?? 1, fuel: (json['fuel'] as num?)?.toDouble() ?? 0, condition: (json['condition'] as num?)?.toDouble() ?? 100,
    status: VehicleStatus.values.firstWhere((value) => value.name == json['status'], orElse: () => VehicleStatus.idle),
    assignedContractId: json['assignedContractId'] as String?,
    departureTimeUtc: json['departureTimeUtc'] == null ? null : DateTime.parse(json['departureTimeUtc'] as String).toUtc(),
    arrivalTimeUtc: json['arrivalTimeUtc'] == null ? null : DateTime.parse(json['arrivalTimeUtc'] as String).toUtc(),
  );
}

enum CargoType { documents, parcels, electronics, food, industrialParts, machinery }

enum ContractStatus { available, inTransit, completed, failed }

class CargoContract {
  const CargoContract({
    required this.contractId,
    required this.originCityId,
    required this.originCityName,
    required this.destinationCityId,
    required this.destinationCityName,
    required this.cargoType,
    required this.cargoWeightKg,
    required this.distanceKm,
    required this.reward,
    required this.rewardXp,
    required this.departureTimeUtc,
    required this.arrivalTimeUtc,
    required this.status,
    this.assignedVehicleId,
  });

  final String contractId;
  final String originCityId;
  final String originCityName;
  final String destinationCityId;
  final String destinationCityName;
  final CargoType cargoType;
  final double cargoWeightKg;
  final double distanceKm;
  final double reward;
  final int rewardXp;
  final DateTime? departureTimeUtc;
  final DateTime? arrivalTimeUtc;
  final ContractStatus status;
  final String? assignedVehicleId;

  CargoContract copyWith({
    String? contractId,
    String? originCityId,
    String? originCityName,
    String? destinationCityId,
    String? destinationCityName,
    CargoType? cargoType,
    double? cargoWeightKg,
    double? distanceKm,
    double? reward,
    int? rewardXp,
    DateTime? departureTimeUtc,
    bool clearDepartureTime = false,
    DateTime? arrivalTimeUtc,
    bool clearArrivalTime = false,
    ContractStatus? status,
    String? assignedVehicleId,
    bool clearAssignedVehicle = false,
  }) {
    return CargoContract(
      contractId: contractId ?? this.contractId,
      originCityId: originCityId ?? this.originCityId,
      originCityName: originCityName ?? this.originCityName,
      destinationCityId: destinationCityId ?? this.destinationCityId,
      destinationCityName: destinationCityName ?? this.destinationCityName,
      cargoType: cargoType ?? this.cargoType,
      cargoWeightKg: cargoWeightKg ?? this.cargoWeightKg,
      distanceKm: distanceKm ?? this.distanceKm,
      reward: reward ?? this.reward,
      rewardXp: rewardXp ?? this.rewardXp,
      departureTimeUtc: clearDepartureTime
          ? null
          : departureTimeUtc ?? this.departureTimeUtc,
      arrivalTimeUtc:
          clearArrivalTime ? null : arrivalTimeUtc ?? this.arrivalTimeUtc,
      status: status ?? this.status,
      assignedVehicleId: clearAssignedVehicle
          ? null
          : assignedVehicleId ?? this.assignedVehicleId,
    );
  }

  Map<String, dynamic> toJson() => {
        'contractId': contractId,
        'originCityId': originCityId,
        'originCityName': originCityName,
        'destinationCityId': destinationCityId,
        'destinationCityName': destinationCityName,
        'cargoType': cargoType.name,
        'cargoWeightKg': cargoWeightKg,
        'distanceKm': distanceKm,
        'reward': reward,
        'rewardXp': rewardXp,
        'departureTimeUtc': departureTimeUtc?.toUtc().toIso8601String(),
        'arrivalTimeUtc': arrivalTimeUtc?.toUtc().toIso8601String(),
        'status': status.name,
        'assignedVehicleId': assignedVehicleId,
      };

  factory CargoContract.fromJson(Map<String, dynamic> json) => CargoContract(
        contractId: json['contractId'] as String,
        originCityId: json['originCityId'] as String,
        originCityName: json['originCityName'] as String,
        destinationCityId: json['destinationCityId'] as String,
        destinationCityName: json['destinationCityName'] as String,
        cargoType: CargoType.values.firstWhere(
          (value) => value.name == json['cargoType'],
          orElse: () => CargoType.parcels,
        ),
        cargoWeightKg: (json['cargoWeightKg'] as num).toDouble(),
        distanceKm: (json['distanceKm'] as num).toDouble(),
        reward: (json['reward'] as num).toDouble(),
        rewardXp: (json['rewardXp'] as num?)?.toInt() ?? 0,
        departureTimeUtc: json['departureTimeUtc'] == null
            ? null
            : DateTime.parse(json['departureTimeUtc'] as String).toUtc(),
        arrivalTimeUtc: json['arrivalTimeUtc'] == null
            ? null
            : DateTime.parse(json['arrivalTimeUtc'] as String).toUtc(),
        status: ContractStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => ContractStatus.available,
        ),
        assignedVehicleId: json['assignedVehicleId'] as String?,
      );
}

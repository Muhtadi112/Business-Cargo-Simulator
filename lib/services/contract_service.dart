import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/city.dart';
import '../models/company.dart';
import '../models/contract.dart';

class ContractService {
  ContractService({Random? random, Uuid? uuid})
      : _random = random ?? Random(),
        _uuid = uuid ?? const Uuid();

  final Random _random;
  final Uuid _uuid;

  List<CargoContract> generateContractsForCompany(
    Company company, {
    int count = 8,
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final unlockedCities = CityCatalog.unlockedBy(company.unlockedCityIds);
    if (unlockedCities.isEmpty) {
      throw StateError('Perusahaan belum memiliki kota yang terbuka.');
    }

    final routes = <({CityNode origin, CityNode destination, double distance})>[];
    for (final origin in unlockedCities) {
      for (final destination in unlockedCities) {
        if (origin.id == destination.id) continue;
        final distance = CityCatalog.distanceBetween(origin, destination);
        if (distance >= 25) {
          routes.add((
            origin: origin,
            destination: destination,
            distance: distance,
          ));
        }
      }
    }

    final contracts = <CargoContract>[];
    final requiredLightCount = min(3, max(3, count));
    for (var index = 0; index < requiredLightCount; index++) {
      if (routes.isNotEmpty) {
        final route = routes[_random.nextInt(routes.length)];
        contracts.add(_buildContract(
          route.origin,
          route.destination,
          route.distance,
          lightCargo: true,
          nowUtc: now,
        ));
      } else {
        final hub = unlockedCities.first;
        final localDistance = 18.0 + _random.nextDouble() * 42.0;
        contracts.add(_buildContract(
          hub,
          hub,
          localDistance,
          lightCargo: true,
          nowUtc: now,
          localDelivery: true,
        ));
      }
    }

    final targetCount = max(3, count);
    while (contracts.length < targetCount) {
      final route = routes.isNotEmpty
          ? routes[_random.nextInt(routes.length)]
          : null;
      final origin = route?.origin ?? unlockedCities.first;
      final destination = route?.destination ?? unlockedCities.first;
      final distance = route?.distance ?? (30 + _random.nextDouble() * 90);
      contracts.add(_buildContract(
        origin,
        destination,
        distance,
        lightCargo: false,
        nowUtc: now,
        localDelivery: route == null,
      ));
    }

    return contracts;
  }

  CargoContract _buildContract(
    CityNode origin,
    CityNode destination,
    double distance, {
    required bool lightCargo,
    required DateTime nowUtc,
    bool localDelivery = false,
  }) {
    final lightWeights = <double>[450, 620, 780, 920, 1050, 1150];
    final heavyWeights = <double>[1450, 2200, 3800, 6200, 9000, 14000];
    final weights = lightCargo ? lightWeights : heavyWeights;
    final weight = weights[_random.nextInt(weights.length)];
    final cargoTypes = lightCargo
        ? <CargoType>[
            CargoType.documents,
            CargoType.parcels,
            CargoType.electronics,
          ]
        : CargoType.values;
    final cargoType = cargoTypes[_random.nextInt(cargoTypes.length)];
    final reward = max(
      180.0,
      distance * (1.35 + weight / 7000) + weight * 0.18,
    );
    final xp = max(20, (distance / 7 + weight / 90).round());

    return CargoContract(
      contractId: _uuid.v4(),
      originCityId: origin.id,
      originCityName: localDelivery ? '${origin.name} Metro' : origin.name,
      destinationCityId: destination.id,
      destinationCityName:
          localDelivery ? '${destination.name} Local Zone' : destination.name,
      cargoType: cargoType,
      cargoWeightKg: weight,
      distanceKm: distance,
      reward: reward,
      rewardXp: xp,
      departureTimeUtc: null,
      arrivalTimeUtc: null,
      status: ContractStatus.available,
    );
  }
}

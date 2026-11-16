import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/city.dart';
import '../models/company.dart';
import '../models/contract.dart';
import '../models/vehicle.dart';

class ContractService {
  ContractService({Random? random, Uuid? uuid}) : _random = random ?? Random(), _uuid = uuid ?? const Uuid();
  final Random _random;
  final Uuid _uuid;

  List<CargoContract> generateContractsForCompany(Company company, {int count = 8, DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final cities = CityCatalog.unlockedBy(company.unlockedCityIds);
    if (cities.isEmpty) throw StateError('Perusahaan belum memiliki kota yang terbuka.');
    final contracts = <CargoContract>[];
    final roadRoutes = <(CityNode, CityNode, double)>[];
    final seaRoutes = <(CityNode, CityNode, double)>[];
    final airRoutes = <(CityNode, CityNode, double)>[];
    for (final a in cities) {
      for (final b in cities) {
        if (a.id == b.id) continue;
        final d = CityCatalog.distanceBetween(a, b);
        if (d < 25) continue;
        roadRoutes.add((a, b, d));
        if (a.hasPort && b.hasPort) seaRoutes.add((a, b, d * 1.18));
        if (a.hasAirport && b.hasAirport) airRoutes.add((a, b, d * 1.08));
      }
    }
    final pool = <({TransportMode mode, (CityNode, CityNode, double) route})>[];
    for (final r in roadRoutes) { pool.add((mode: TransportMode.road, route: r)); }
    for (final r in seaRoutes) { pool.add((mode: TransportMode.sea, route: r)); }
    for (final r in airRoutes) { pool.add((mode: TransportMode.air, route: r)); }
    final target = max(3, count);
    while (contracts.length < target) {
      final mode = pool.isEmpty ? TransportMode.road : (contracts.length % 3 == 1 && seaRoutes.isNotEmpty ? TransportMode.sea : contracts.length % 3 == 2 && airRoutes.isNotEmpty ? TransportMode.air : TransportMode.road);
      final routes = mode == TransportMode.sea ? seaRoutes : mode == TransportMode.air ? airRoutes : roadRoutes;
      if (routes.isEmpty) {
        final hub = cities.first;
        contracts.add(_build(hub, hub, 18 + _random.nextDouble() * 42, TransportMode.road, now, local: true));
      } else {
        final route = routes[_random.nextInt(routes.length)];
        contracts.add(_build(route.$1, route.$2, route.$3, mode, now));
      }
    }
    return contracts;
  }

  CargoContract _build(CityNode a, CityNode b, double distance, TransportMode mode, DateTime now, {bool local = false}) {
    final weights = mode == TransportMode.sea ? <double>[250000, 1200000, 5000000, 12000000, 45000000] : mode == TransportMode.air ? <double>[800, 1800, 4200, 7500, 18000, 65000] : <double>[450, 620, 780, 920, 1450, 2200, 3800, 6200, 9000, 14000];
    final weight = weights[_random.nextInt(weights.length)];
    final types = mode == TransportMode.sea ? <CargoType>[CargoType.electronics, CargoType.industrialParts, CargoType.machinery, CargoType.luxuryGoods] : mode == TransportMode.air ? <CargoType>[CargoType.electronics, CargoType.luxuryGoods, CargoType.expressFreight, CargoType.documents] : CargoType.values.take(6).toList();
    final type = types[_random.nextInt(types.length)];
    final reward = switch (mode) {
      TransportMode.road => max(180.0, distance * (1.35 + weight / 7000) + weight * 0.18),
      TransportMode.sea => max(25000.0, distance * 40 + weight * 0.12),
      TransportMode.air => max(18000.0, distance * 100 + weight * 2.2),
    };
    final xp = switch (mode) {
      TransportMode.road => max(20, (distance / 7 + weight / 90).round()),
      TransportMode.sea => max(250, (distance / 2 + weight / 15000).round()),
      TransportMode.air => max(180, (distance / 1.5 + weight / 120).round()),
    };
    final terminal = mode == TransportMode.sea ? TerminalType.containerPort : mode == TransportMode.air ? TerminalType.airport : TerminalType.warehouse;
    return CargoContract(contractId: _uuid.v4(), originCityId: a.id, originCityName: local ? '${a.name} Metro' : a.name, destinationCityId: b.id, destinationCityName: local ? '${b.name} Local Zone' : b.name, cargoType: type, cargoWeightKg: weight, distanceKm: distance, reward: reward, rewardXp: xp, departureTimeUtc: null, arrivalTimeUtc: null, status: ContractStatus.available, transportMode: mode, originTerminal: terminal, destinationTerminal: terminal);
  }
}

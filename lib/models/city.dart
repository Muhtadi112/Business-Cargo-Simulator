import 'dart:math' as math;

class CityNode {
  const CityNode({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.region,
    required this.mapX,
    required this.mapY,
    required this.latitude,
    required this.longitude,
    required this.unlockCost,
    required this.isStarterHub,
  });

  final String id;
  final String name;
  final String countryCode;
  final String countryName;
  final String region;
  final double mapX;
  final double mapY;
  final double latitude;
  final double longitude;
  final double unlockCost;
  final bool isStarterHub;

  static double distanceKmBetween(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusKm = 6371.0088;
    final lat1 = _degreesToRadians(latitude1);
    final lat2 = _degreesToRadians(latitude2);
    final deltaLat = _degreesToRadians(latitude2 - latitude1);
    final deltaLon = _degreesToRadians(longitude2 - longitude1);
    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(deltaLon / 2), 2);
    final boundedA = a.clamp(0.0, 1.0);
    final centralAngle =
        2 * math.atan2(math.sqrt(boundedA), math.sqrt(1 - boundedA));
    return earthRadiusKm * centralAngle;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}

abstract final class CityCatalog {
  static const List<CityNode> cities = <CityNode>[
    CityNode(
      id: 'jakarta',
      name: 'Jakarta',
      countryCode: 'ID',
      countryName: 'Indonesia',
      region: 'Southeast Asia',
      mapX: 0.78,
      mapY: 0.67,
      latitude: -6.2088,
      longitude: 106.8456,
      unlockCost: 0,
      isStarterHub: true,
    ),
    CityNode(
      id: 'singapore',
      name: 'Singapore',
      countryCode: 'SG',
      countryName: 'Singapore',
      region: 'Southeast Asia',
      mapX: 0.80,
      mapY: 0.72,
      latitude: 1.3521,
      longitude: 103.8198,
      unlockCost: 0,
      isStarterHub: true,
    ),
    CityNode(
      id: 'kuala_lumpur',
      name: 'Kuala Lumpur',
      countryCode: 'MY',
      countryName: 'Malaysia',
      region: 'Southeast Asia',
      mapX: 0.78,
      mapY: 0.70,
      latitude: 3.1390,
      longitude: 101.6869,
      unlockCost: 18000,
      isStarterHub: false,
    ),
    CityNode(
      id: 'tokyo',
      name: 'Tokyo',
      countryCode: 'JP',
      countryName: 'Japan',
      region: 'East Asia',
      mapX: 0.88,
      mapY: 0.40,
      latitude: 35.6762,
      longitude: 139.6503,
      unlockCost: 0,
      isStarterHub: true,
    ),
    CityNode(
      id: 'dubai',
      name: 'Dubai',
      countryCode: 'AE',
      countryName: 'United Arab Emirates',
      region: 'Middle East',
      mapX: 0.57,
      mapY: 0.48,
      latitude: 25.2048,
      longitude: 55.2708,
      unlockCost: 0,
      isStarterHub: true,
    ),
    CityNode(
      id: 'rotterdam',
      name: 'Rotterdam',
      countryCode: 'NL',
      countryName: 'Netherlands',
      region: 'Europe',
      mapX: 0.48,
      mapY: 0.27,
      latitude: 51.9244,
      longitude: 4.4777,
      unlockCost: 0,
      isStarterHub: true,
    ),
    CityNode(
      id: 'los_angeles',
      name: 'Los Angeles',
      countryCode: 'US',
      countryName: 'United States',
      region: 'North America',
      mapX: 0.15,
      mapY: 0.38,
      latitude: 34.0522,
      longitude: -118.2437,
      unlockCost: 0,
      isStarterHub: true,
    ),
    CityNode(
      id: 'sydney',
      name: 'Sydney',
      countryCode: 'AU',
      countryName: 'Australia',
      region: 'Oceania',
      mapX: 0.91,
      mapY: 0.83,
      latitude: -33.8688,
      longitude: 151.2093,
      unlockCost: 28000,
      isStarterHub: false,
    ),
  ];

  static CityNode byId(String id) =>
      cities.firstWhere((city) => city.id == id);

  static CityNode? findById(String id) {
    for (final city in cities) {
      if (city.id == id) return city;
    }
    return null;
  }

  static List<CityNode> get starterHubs =>
      cities.where((city) => city.isStarterHub).toList(growable: false);

  static List<CityNode> unlockedBy(List<String> unlockedCityIds) =>
      cities
          .where((city) => unlockedCityIds.contains(city.id))
          .toList(growable: false);

  static double distanceBetween(CityNode origin, CityNode destination) =>
      CityNode.distanceKmBetween(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      );
}

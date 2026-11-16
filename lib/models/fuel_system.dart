enum FuelType { diesel, jetFuel }

class FuelTank {
  const FuelTank({required this.type, this.level = 0, this.storedLiters = 0});
  final FuelType type;
  final int level;
  final double storedLiters;
  double get capacityLiters => level == 0 ? 0.0 : 5000.0 * level * level;
  bool get isBuilt => level > 0;
  double get nextUpgradeCost => (level == 0 ? (type == FuelType.diesel ? 18000.0 : 95000.0) : (type == FuelType.diesel ? 18000.0 : 95000.0) * (level + 1) * 1.7).toDouble();
  FuelTank buildOrUpgrade() => FuelTank(type: type, level: level + 1, storedLiters: storedLiters);
  FuelTank addFuel(double liters) => FuelTank(type: type, level: level, storedLiters: (storedLiters + liters).clamp(0, capacityLiters).toDouble());
  FuelTank consume(double liters) => FuelTank(type: type, level: level, storedLiters: (storedLiters - liters).clamp(0, capacityLiters).toDouble());
  Map<String, dynamic> toJson() => {'type': type.name, 'level': level, 'storedLiters': storedLiters};
  factory FuelTank.fromJson(Map<String, dynamic> json, FuelType fallback) => FuelTank(
    type: FuelType.values.firstWhere((v) => v.name == json['type'], orElse: () => fallback),
    level: (json['level'] as num?)?.toInt() ?? 0,
    storedLiters: (json['storedLiters'] as num?)?.toDouble() ?? 0,
  );
}

class FuelSystem {
  const FuelSystem({this.diesel = const FuelTank(type: FuelType.diesel), this.jetFuel = const FuelTank(type: FuelType.jetFuel)});
  final FuelTank diesel;
  final FuelTank jetFuel;
  FuelTank tank(FuelType type) => type == FuelType.diesel ? diesel : jetFuel;
  FuelSystem update(FuelTank value) => value.type == FuelType.diesel ? FuelSystem(diesel: value, jetFuel: jetFuel) : FuelSystem(diesel: diesel, jetFuel: value);
  Map<String, dynamic> toJson() => {'diesel': diesel.toJson(), 'jetFuel': jetFuel.toJson()};
  factory FuelSystem.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FuelSystem();
    return FuelSystem(
      diesel: json['diesel'] is Map<String, dynamic> ? FuelTank.fromJson(json['diesel'] as Map<String, dynamic>, FuelType.diesel) : const FuelTank(type: FuelType.diesel),
      jetFuel: json['jetFuel'] is Map<String, dynamic> ? FuelTank.fromJson(json['jetFuel'] as Map<String, dynamic>, FuelType.jetFuel) : const FuelTank(type: FuelType.jetFuel),
    );
  }
}

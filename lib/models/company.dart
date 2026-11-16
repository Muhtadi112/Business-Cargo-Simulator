class Company {
  const Company({
    required this.id,
    required this.name,
    required this.headquartersCity,
    required this.countryCode,
    required this.logoId,
    required this.logoColor,
    required this.level,
    required this.xp,
    required this.reputation,
    required this.balance,
    required this.totalRevenue,
    required this.fleetValue,
    required this.completedContracts,
    required this.unlockedCityIds,
    required this.createdAtUtc,
  });

  final String id;
  final String name;
  final String headquartersCity;
  final String countryCode;
  final String logoId;
  final int logoColor;
  final int level;
  final int xp;
  final int reputation;
  final double balance;
  final double totalRevenue;
  final double fleetValue;
  final int completedContracts;
  final List<String> unlockedCityIds;
  final DateTime createdAtUtc;

  factory Company.newCompany({
    required String id,
    required String name,
    String headquartersCity = 'Jakarta',
    String countryCode = 'ID',
    String logoId = 'local_shipping',
    int logoColor = 0xFF2EE59D,
    DateTime? createdAtUtc,
  }) {
    return Company(
      id: id,
      name: name.trim(),
      headquartersCity: headquartersCity,
      countryCode: countryCode,
      logoId: logoId,
      logoColor: logoColor,
      level: 1,
      xp: 0,
      reputation: 50,
      balance: 50000,
      totalRevenue: 0,
      fleetValue: 12000,
      completedContracts: 0,
      unlockedCityIds: <String>[headquartersCity.toLowerCase().replaceAll(' ', '_')],
      createdAtUtc: (createdAtUtc ?? DateTime.now()).toUtc(),
    );
  }

  Company copyWith({
    String? id,
    String? name,
    String? headquartersCity,
    String? countryCode,
    String? logoId,
    int? logoColor,
    int? level,
    int? xp,
    int? reputation,
    double? balance,
    double? totalRevenue,
    double? fleetValue,
    int? completedContracts,
    List<String>? unlockedCityIds,
    DateTime? createdAtUtc,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      headquartersCity: headquartersCity ?? this.headquartersCity,
      countryCode: countryCode ?? this.countryCode,
      logoId: logoId ?? this.logoId,
      logoColor: logoColor ?? this.logoColor,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      reputation: reputation ?? this.reputation,
      balance: balance ?? this.balance,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      fleetValue: fleetValue ?? this.fleetValue,
      completedContracts: completedContracts ?? this.completedContracts,
      unlockedCityIds: List<String>.of(unlockedCityIds ?? this.unlockedCityIds),
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'headquartersCity': headquartersCity,
        'countryCode': countryCode,
        'logoId': logoId,
        'logoColor': logoColor,
        'level': level,
        'xp': xp,
        'reputation': reputation,
        'balance': balance,
        'totalRevenue': totalRevenue,
        'fleetValue': fleetValue,
        'completedContracts': completedContracts,
        'unlockedCityIds': unlockedCityIds,
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
      };

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'] as String,
        name: json['name'] as String,
        headquartersCity: json['headquartersCity'] as String? ?? 'Jakarta',
        countryCode: json['countryCode'] as String? ?? 'ID',
        logoId: json['logoId'] as String? ?? 'local_shipping',
        logoColor: (json['logoColor'] as num?)?.toInt() ?? 0xFF2EE59D,
        level: (json['level'] as num?)?.toInt() ?? 1,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        reputation: (json['reputation'] as num?)?.toInt() ?? 50,
        balance: (json['balance'] as num?)?.toDouble() ?? 50000,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
        fleetValue: (json['fleetValue'] as num?)?.toDouble() ?? 0,
        completedContracts:
            (json['completedContracts'] as num?)?.toInt() ?? 0,
        unlockedCityIds: List<String>.from(
          (json['unlockedCityIds'] as List<dynamic>?) ?? const <String>[],
        ),
        createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
      );
}

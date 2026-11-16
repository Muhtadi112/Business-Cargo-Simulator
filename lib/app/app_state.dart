import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/city.dart';
import 'formatters.dart';
import '../models/company.dart';
import '../models/fuel_system.dart';
import '../models/research.dart';
import '../models/contract.dart';
import '../models/vehicle.dart';
import '../services/contract_service.dart';
import '../services/fleet_service.dart';
import '../services/save_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    SaveService? saveService,
    ContractService? contractService,
    FleetService? fleetService,
  })  : _saveService = saveService ?? SaveService(),
        _contractService = contractService ?? ContractService(),
        _fleetService = fleetService ?? FleetService();

  final SaveService _saveService;
  final ContractService _contractService;
  final FleetService _fleetService;
  final Uuid _uuid = const Uuid();

  Company? _company;
  List<Vehicle> _vehicles = <Vehicle>[];
  List<CargoContract> _contracts = <CargoContract>[];
  int _selectedTab = 0;
  String? _toastMessage;
  Timer? _ticker;
  bool _initialized = false;
  bool _isBusy = false;

  Company? get company => _company;
  bool get hasCompany => _company != null;
  int get totalVehicles => _vehicles.length;
  int get activeVehicles => _vehicles.where((v) => v.status == VehicleStatus.enRoute).length;
  List<Vehicle> get vehicles => List<Vehicle>.unmodifiable(_vehicles);
  List<CargoContract> get contracts =>
      List<CargoContract>.unmodifiable(_contracts);
  int get selectedTab => _selectedTab;
  String? get toastMessage => _toastMessage;
  bool get isInitialized => _initialized;
  bool get isBusy => _isBusy;
  bool get needsCompanySetup => _company == null;
  List<CityNode> get unlockedCities => _company == null
      ? <CityNode>[]
      : CityCatalog.unlockedBy(_company!.unlockedCityIds);

  Future<void> initialize() async {
    if (_initialized) return;
    _isBusy = true;
    notifyListeners();
    try {
      final savedGame = await _saveService.loadGame();
      if (savedGame != null) {
        _company = savedGame.company;
        _vehicles = savedGame.vehicles;
        _contracts = savedGame.contracts;
        _resolveArrivalsAndPersist();
      }
      _initialized = true;
      _ticker ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => _onTick(),
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> createCompany({
    required String name,
    required String headquartersCityId,
    required String logoId,
    required int logoColor,
  }) async {
    if (_company != null) {
      throw StateError('Perusahaan sudah didirikan.');
    }
    final cleanName = name.trim();
    if (cleanName.length < 3) {
      throw ArgumentError('Nama perusahaan minimal 3 karakter.');
    }
    final city = CityCatalog.findById(headquartersCityId);
    if (city == null || !city.isStarterHub) {
      throw ArgumentError('Pilih salah satu kota markas awal yang tersedia.');
    }

    _isBusy = true;
    notifyListeners();
    try {
      _company = Company.newCompany(
        id: _uuid.v4(),
        name: cleanName,
        headquartersCity: city.name,
        countryCode: city.countryCode,
        logoId: logoId,
        logoColor: logoColor,
      ).copyWith(unlockedCityIds: <String>[city.id]);
      _vehicles = <Vehicle>[
        Vehicle.starter(vehicleId: _uuid.v4()),
      ];
      _contracts = _contractService.generateContractsForCompany(
        _company!,
        count: 8,
      );
      await _persist();
      _toastMessage = 'Perusahaan $cleanName resmi didirikan!';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> updateBranding({
    String? name,
    String? logoId,
    int? logoColor,
  }) async {
    final current = _company;
    if (current == null) { throw StateError('Dirikan perusahaan terlebih dahulu.'); }
    final updatedName = name?.trim();
    if (updatedName != null && updatedName.length < 3) {
      throw ArgumentError('Nama perusahaan minimal 3 karakter.');
    }
    _company = current.copyWith(
      name: updatedName == null || updatedName.isEmpty
          ? current.name
          : updatedName,
      logoId: logoId,
      logoColor: logoColor,
    );
    await _persist();
    showToast('Identitas perusahaan berhasil diperbarui.');
  }

  Future<void> resetProgress() async {
    _ticker?.cancel();
    _company = null;
    _vehicles = <Vehicle>[];
    _contracts = <CargoContract>[];
    _selectedTab = 0;
    await _saveService.resetGame();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    showToast('Progres lokal berhasil direset.');
  }

  void setTab(int index) {
    if (index < 0 || index > 6) {
      throw RangeError.range(index, 0, 6, 'index');
    }
    _selectedTab = index;
    notifyListeners();
  }

  Future<void> dispatchContract({
    required String contractId,
    required String vehicleId,
  }) async {
    final company = _company;
    if (company == null) throw StateError('Perusahaan belum didirikan.');
    final contractIndex =
        _contracts.indexWhere((item) => item.contractId == contractId);
    final vehicleIndex =
        _vehicles.indexWhere((item) => item.vehicleId == vehicleId);
    if (contractIndex < 0) throw ArgumentError('Kontrak tidak ditemukan.');
    if (vehicleIndex < 0) throw ArgumentError('Kendaraan tidak ditemukan.');

    final assignment = _fleetService.assignContract(
      _vehicles[vehicleIndex],
      _contracts[contractIndex],
      fuelEfficiencyLevel: company.researchLevel('efficientEngines'),
      loadingCrewLevel: company.researchLevel('loadingCrew'),
      dispatchSoftwareLevel: company.researchLevel('dispatchSoftware'),
    );
    _vehicles[vehicleIndex] = assignment.vehicle;
    _contracts[contractIndex] = assignment.contract;
    await _persist();
    showToast('Kendaraan berangkat menuju tujuan.');
  }

  Future<void> buyVehicle(VehicleTier tier) async {
    final company = _company;
    if (company == null) throw StateError('Perusahaan belum didirikan.');
    final specification = VehicleCatalog.forTier(tier);
    if (specification.mode == TransportMode.air && !company.airportBranchBuilt) throw StateError('Bangun cabang bandara sebelum membeli pesawat kargo.');
    if (specification.mode == TransportMode.sea && !company.seaPortBuilt) throw StateError('Bangun pelabuhan laut sebelum membeli kapal kargo.');
    if (_vehicles.length >= fleetSlots) throw StateError('Slot armada penuh. Upgrade depo atau bangun terminal tambahan.');
    if (company.balance < specification.purchasePrice) {
      throw StateError('Saldo perusahaan tidak mencukupi.');
    }
    final vehicle = _fleetService.createPurchasedVehicle(tier);
    _vehicles = <Vehicle>[..._vehicles, vehicle];
    _company = company.copyWith(
      balance: company.balance - specification.purchasePrice,
      fleetValue: company.fleetValue + specification.purchasePrice,
    );
    await _persist();
    showToast('${specification.name} berhasil dibeli.');
  }

  Future<void> unlockCity(String cityId) async {
    final company = _company;
    if (company == null) throw StateError('Perusahaan belum didirikan.');
    final city = CityCatalog.findById(cityId);
    if (city == null) throw ArgumentError('Kota tidak ditemukan.');
    if (company.unlockedCityIds.contains(cityId)) {
      throw StateError('Kota ini sudah terbuka.');
    }
    if (company.balance < city.unlockCost) {
      throw StateError('Saldo perusahaan tidak mencukupi.');
    }
    _company = company.copyWith(
      balance: company.balance - city.unlockCost,
      unlockedCityIds: <String>[...company.unlockedCityIds, city.id],
    );
    await refreshContracts();
    showToast('Hub ${city.name} berhasil dibuka.');
  }

  Future<void> refuelAndRepairVehicle(String vehicleId) async {
    final company = _company;
    if (company == null) throw StateError('Perusahaan belum didirikan.');
    final index = _vehicles.indexWhere((item) => item.vehicleId == vehicleId);
    if (index < 0) throw ArgumentError('Kendaraan tidak ditemukan.');
    final vehicle = _vehicles[index];
    if (vehicle.status == VehicleStatus.enRoute) {
      throw StateError('Kendaraan yang sedang bertugas tidak bisa diservis.');
    }
    if (vehicle.mode == TransportMode.sea) {
      final seaCost = _fleetService.calculateRefuelCost(vehicle) + _fleetService.calculateRepairCost(vehicle);
      if (company.balance < seaCost) throw StateError('Saldo tidak cukup untuk bunker fuel dan servis kapal.');
      _vehicles[index] = _fleetService.refuelAndRepair(vehicle);
      _company = company.copyWith(balance: company.balance - seaCost);
      await _persist();
      showToast('Bunker fuel dan kondisi kapal sudah penuh.');
      return;
    }
    final fuelType = vehicle.mode == TransportMode.air ? FuelType.jetFuel : FuelType.diesel;
    final tank = company.fuelSystem.tank(fuelType);
    if (!tank.isBuilt) throw StateError('Bangun tangki bahan bakar markas terlebih dahulu.');
    final missingFuel = (vehicle.specifications.fuelCapacityLiters - vehicle.fuel).clamp(0.0, double.infinity).toDouble();
    if (tank.storedLiters < missingFuel) throw StateError('Stok tangki markas tidak cukup untuk mengisi armada.');
    final cost = _fleetService.calculateRepairCost(vehicle);
    if (company.balance < cost) throw StateError('Saldo tidak cukup untuk servis kendaraan.');
    _vehicles[index] = _fleetService.refuelAndRepair(vehicle);
    _company = company.copyWith(balance: company.balance - cost, fuelSystem: company.fuelSystem.update(tank.consume(missingFuel)));
    await _persist();
    showToast('BBM dan kondisi kendaraan sudah penuh.');
  }


  int get fleetSlots => 12 + (_company == null ? 0 : (_company!.depotLevel - 1) * 8) +
      (_company?.riverTerminalBuilt == true ? 12 : 0) +
      (_company?.airportBranchBuilt == true ? 8 : 0) +
      (_company?.seaPortBuilt == true ? 12 : 0);

  Future<void> upgradeFuelTank(FuelType type) async {
    final c = _company;
    if (c == null) throw StateError('Perusahaan belum didirikan.');
    if (type == FuelType.jetFuel && !c.airportBranchBuilt) throw StateError('Cabang bandara harus dibangun sebelum tangki avtur.');
    final tank = c.fuelSystem.tank(type);
    final cost = tank.nextUpgradeCost;
    if (c.balance < cost) throw StateError('Saldo tidak cukup untuk membangun atau upgrade tangki.');
    _company = c.copyWith(balance: c.balance - cost, fuelSystem: c.fuelSystem.update(tank.buildOrUpgrade()));
    await _persist();
    showToast('${type == FuelType.diesel ? 'Tangki solar' : 'Tangki avtur'} berhasil ${tank.isBuilt ? 'di-upgrade' : 'dibangun'}.');
  }

  Future<void> purchaseFuel(FuelType type, {double liters = 1000}) async {
    final c = _company;
    if (c == null) throw StateError('Perusahaan belum didirikan.');
    if (type == FuelType.jetFuel && !c.airportBranchBuilt) throw StateError('Cabang bandara belum dibangun.');
    final tank = c.fuelSystem.tank(type);
    if (!tank.isBuilt) throw StateError('Bangun tangki terlebih dahulu.');
    final accepted = (tank.capacityLiters - tank.storedLiters).clamp(0.0, liters).toDouble();
    if (accepted <= 0) throw StateError('Tangki markas sudah penuh.');
    final price = type == FuelType.diesel ? 1.25 : 2.30;
    final cost = accepted * price;
    if (c.balance < cost) throw StateError('Saldo tidak cukup untuk membeli bahan bakar.');
    _company = c.copyWith(balance: c.balance - cost, fuelSystem: c.fuelSystem.update(tank.addFuel(accepted)));
    await _persist();
    showToast('Stok bahan bakar bertambah ' + accepted.toStringAsFixed(0) + ' liter.');
  }

  Future<void> refuelVehicleFromTank(String vehicleId) async {
    final c = _company;
    if (c == null) throw StateError('Perusahaan belum didirikan.');
    final index = _vehicles.indexWhere((v) => v.vehicleId == vehicleId);
    if (index < 0) throw ArgumentError('Kendaraan tidak ditemukan.');
    final vehicle = _vehicles[index];
    if (vehicle.status == VehicleStatus.enRoute) throw StateError('Armada yang sedang bertugas tidak bisa diisi ulang.');
    if (vehicle.mode == TransportMode.sea) throw StateError('Kapal menggunakan bunker fuel dan tidak memakai tangki solar atau avtur markas.');
    final type = vehicle.mode == TransportMode.air ? FuelType.jetFuel : FuelType.diesel;
    final tank = c.fuelSystem.tank(type);
    if (!tank.isBuilt) throw StateError('Tangki bahan bakar belum dibangun.');
    final needed = (vehicle.specifications.fuelCapacityLiters - vehicle.fuel).clamp(0.0, double.infinity).toDouble();
    if (needed <= 0) throw StateError('Tangki kendaraan sudah penuh.');
    if (tank.storedLiters < needed) throw StateError('Stok tangki markas tidak mencukupi.');
    _vehicles[index] = vehicle.copyWith(fuel: vehicle.specifications.fuelCapacityLiters);
    _company = c.copyWith(fuelSystem: c.fuelSystem.update(tank.consume(needed)));
    await _persist();
    showToast('Armada berhasil diisi dari tangki markas.');
  }

  Future<void> upgradeDepot() async {
    final c = _company;
    if (c == null) throw StateError('Perusahaan belum didirikan.');
    if (c.depotLevel >= 5) throw StateError('Depo darat sudah mencapai Tingkat 5.');
    final cost = 90000.0 * c.depotLevel;
    if (c.balance < cost) throw StateError('Saldo tidak cukup untuk upgrade depo.');
    _company = c.copyWith(balance: c.balance - cost, depotLevel: c.depotLevel + 1);
    await _persist();
    showToast('Depo darat naik ke Tingkat ${c.depotLevel + 1}.');
  }

  Future<void> buildTerminal(String terminal) async {
    final c = _company;
    if (c == null) throw StateError('Perusahaan belum didirikan.');
    final config = switch (terminal) {
      'river' => (level: 12, cost: 600000.0, built: c.riverTerminalBuilt),
      'airport' => (level: 20, cost: 2250000.0, built: c.airportBranchBuilt),
      'seaport' => (level: 30, cost: 9000000.0, built: c.seaPortBuilt),
      _ => throw ArgumentError('Terminal tidak dikenal.'),
    };
    if (c.level < config.level) throw StateError('Terminal ini terbuka pada level ${config.level}.');
    if (config.built) throw StateError('Terminal sudah dibangun.');
    if (c.balance < config.cost) throw StateError('Saldo tidak cukup untuk investasi terminal.');
    _company = switch (terminal) {
      'river' => c.copyWith(balance: c.balance - config.cost, riverTerminalBuilt: true),
      'airport' => c.copyWith(balance: c.balance - config.cost, airportBranchBuilt: true),
      'seaport' => c.copyWith(balance: c.balance - config.cost, seaPortBuilt: true),
      _ => c,
    };
    await _persist();
    await refreshContracts();
    showToast('Terminal baru berhasil dibangun.');
  }

  Future<void> upgradeResearch(ResearchCategory category) async {
    final c = _company;
    if (c == null) throw StateError('Perusahaan belum didirikan.');
    final key = category.name;
    final current = c.researchLevel(key);
    if (current >= ResearchRules.maxLevel) throw StateError('Riset sudah mencapai level maksimum.');
    final cost = ResearchRules.upgradeCost(category, current);
    if (c.balance < cost) throw StateError('Saldo perusahaan tidak mencukupi.');
    final levels = Map<String,int>.of(c.researchLevels)..[key] = current + 1;
    _company = c.copyWith(balance: c.balance - cost, researchLevels: levels);
    await _persist();
    showToast('${ResearchDefinition.byCategory(category).title} naik ke level ${current + 1}.');
  }

  void _applyGoalProgress(int completedCount) {
    final c = _company;
    if (c == null || completedCount <= 0) return;
    final now = DateTime.now().toUtc();
    final dayStart = DateTime.utc(now.year, now.month, now.day);
    final monday = dayStart.subtract(Duration(days: dayStart.weekday - 1));
    var dailyStart = c.dailyGoalStartedAtUtc ?? dayStart;
    var weeklyStart = c.weeklyGoalStartedAtUtc ?? monday;
    var daily = c.dailyDeliveries;
    var weekly = c.weeklyDeliveries;
    if (now.difference(dailyStart).inHours >= 24 || dailyStart.isAfter(now)) { dailyStart = dayStart; daily = 0; }
    if (now.difference(weeklyStart).inDays >= 7 || weeklyStart.isAfter(now)) { weeklyStart = monday; weekly = 0; }
    final oldDaily = daily, oldWeekly = weekly;
    daily = (daily + completedCount).clamp(0, 3).toInt();
    weekly = (weekly + completedCount).clamp(0, 20).toInt();
    var updated = c.copyWith(dailyGoalStartedAtUtc: dailyStart, weeklyGoalStartedAtUtc: weeklyStart, dailyDeliveries: daily, weeklyDeliveries: weekly);
    var reward = 0.0;
    final bonusXp = (oldDaily < 3 && daily >= 3 ? 80 : 0) + (oldWeekly < 20 && weekly >= 20 ? 600 : 0);
    if (oldDaily < 3 && daily >= 3) reward += 2500;
    if (oldWeekly < 20 && weekly >= 20) reward += 25000;
    var xp = updated.xp + bonusXp, level = updated.level;
    while (xp >= level * 500) { xp -= level * 500; level++; }
    if (reward > 0 || bonusXp > 0) {
      updated = updated.copyWith(balance: updated.balance + reward, totalRevenue: updated.totalRevenue + reward, xp: xp, level: level);
      _toastMessage = 'Target tercapai! Bonus ${GameFormatters.currency(reward)} dan $bonusXp XP.';
    }
    _company = updated;
  }

  Future<void> refreshContracts() async {
    final company = _company;
    if (company == null) return;
    final activeContracts = _contracts
        .where((contract) => contract.status == ContractStatus.inTransit)
        .toList();
    final newContracts = _contractService.generateContractsForCompany(
      company,
      count: 8,
    );
    _contracts = <CargoContract>[...activeContracts, ...newContracts];
    await _persist();
    notifyListeners();
  }

  void showToast(String message) {
    _toastMessage = message;
    notifyListeners();
  }

  void clearToast() {
    _toastMessage = null;
    notifyListeners();
  }

  void _onTick() {
    if (_company == null) return;
    final goalCompany = _company!;
    final nowUtc = DateTime.now().toUtc();
    final dayStart = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final monday = dayStart.subtract(Duration(days: dayStart.weekday - 1));
    final dailyStart = goalCompany.dailyGoalStartedAtUtc;
    final weeklyStart = goalCompany.weeklyGoalStartedAtUtc;
    final resetDaily = dailyStart == null || nowUtc.difference(dailyStart).inHours >= 24;
    final resetWeekly = weeklyStart == null || nowUtc.difference(weeklyStart).inDays >= 7;
    if (resetDaily || resetWeekly) {
      _company = goalCompany.copyWith(dailyGoalStartedAtUtc: resetDaily ? dayStart : dailyStart, weeklyGoalStartedAtUtc: resetWeekly ? monday : weeklyStart, dailyDeliveries: resetDaily ? 0 : goalCompany.dailyDeliveries, weeklyDeliveries: resetWeekly ? 0 : goalCompany.weeklyDeliveries);
      unawaited(_persist());
      notifyListeners();
    }
    final beforeCount = _contracts
        .where((contract) => contract.status == ContractStatus.inTransit)
        .length;
    final resolution = _fleetService.resolveArrivedTrips(
      company: _company!,
      vehicles: _vehicles,
      contracts: _contracts,
    );
    final changed = resolution.completedContractIds.isNotEmpty;
    if (changed) {
      _company = resolution.company;
      _vehicles = resolution.vehicles;
      _contracts = resolution.contracts;
      final completed = resolution.completedContractIds.length;
      _applyGoalProgress(completed);
      _toastMessage = '$completed pengiriman selesai. Saldo dan XP bertambah.';
      unawaited(_persist());
      notifyListeners();
    } else if (beforeCount > 0) {
      notifyListeners();
    }
  }

  void _resolveArrivalsAndPersist() {
    final company = _company;
    if (company == null) return;
    final resolution = _fleetService.resolveArrivedTrips(
      company: company,
      vehicles: _vehicles,
      contracts: _contracts,
    );
    if (resolution.completedContractIds.isNotEmpty) {
      _company = resolution.company;
      _vehicles = resolution.vehicles;
      _contracts = resolution.contracts;
      _applyGoalProgress(resolution.completedContractIds.length);
      unawaited(_persist());
    }
  }

  Future<void> _persist() async {
    final company = _company;
    if (company == null) return;
    await _saveService.saveGame(
      company: company,
      vehicles: _vehicles,
      contracts: _contracts,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

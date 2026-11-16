import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/city.dart';
import '../models/company.dart';
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
      _toastMessage = 'Perusahaan ${cleanName} resmi didirikan!';
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
    if (current == null) throw StateError('Dirikan perusahaan terlebih dahulu.');
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
    final cost = _fleetService.calculateRefuelCost(vehicle) +
        _fleetService.calculateRepairCost(vehicle);
    if (company.balance < cost) {
      throw StateError('Saldo tidak cukup untuk isi BBM dan servis.');
    }
    _vehicles[index] = _fleetService.refuelAndRepair(vehicle);
    _company = company.copyWith(balance: company.balance - cost);
    await _persist();
    showToast('BBM dan kondisi kendaraan sudah penuh.');
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

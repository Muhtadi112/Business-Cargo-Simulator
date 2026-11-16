import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/formatters.dart';
import '../models/contract.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  int tab = 0;
  int modeFilter = 0;
  String q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = s.vehicles;
    final vehicles = all
        .where((v) =>
            (modeFilter == 0 || v.mode.index == modeFilter - 1) &&
            v.specifications.name.toLowerCase().contains(q.toLowerCase()))
        .toList();
    final idle = all.where((v) => v.status == VehicleStatus.idle).length;
    final alert = all.where((v) => v.fuel < 20 || v.condition < 55).length;

    return ListView(
      padding: const EdgeInsets.all(13),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() => tab = 0),
                child: Text('Armada • ${all.length}'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => tab = 1),
                child: const Text('Trailer • 0'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => _dealership(context, s),
          icon: const Icon(Icons.add),
          label: const Text('Beli Armada'),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.6,
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          children: [
            _metric('Total Armada', '${all.length}/${s.fleetSlots}'),
            _metric('Menganggur', idle.toString()),
            _metric('Dalam perjalanan', s.activeVehicles.toString()),
            _metric('Perlu perhatian', alert.toString()),
          ],
        ),
        const SizedBox(height: 12),
        if (tab == 0) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _filter('Semua', 0),
              _filter('Darat 🚛', 1),
              _filter('Laut 🚢', 2),
              _filter('Udara ✈️', 3),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari armada',
            ),
          ),
          const SizedBox(height: 10),
          if (vehicles.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Belum ada armada pada filter ini.'),
              ),
            ),
          ...vehicles.map((v) => _vehicle(context, s, v)),
        ] else
          const Text(
            'Belum ada trailer.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
      ],
    );
  }

  Widget _filter(String label, int value) => ChoiceChip(
        label: Text(label),
        selected: modeFilter == value,
        onSelected: (_) => setState(() => modeFilter = value),
      );

  Widget _metric(String title, String value) => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 9)),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ],
        ),
      );

  Widget _vehicle(BuildContext context, AppState s, Vehicle v) {
    final spec = v.specifications;
    final fuelRatio =
        (v.fuel / spec.fuelCapacityLiters).clamp(0.0, 1.0).toDouble();
    final isEnRoute = v.status == VehicleStatus.enRoute;
    final needsAttention = v.status == VehicleStatus.maintenance ||
        v.fuel < spec.fuelCapacityLiters * 0.2 ||
        v.condition < 55;
    final statusColor = needsAttention
        ? AppColors.gold
        : isEnRoute
            ? AppColors.gold
            : AppColors.emerald;
    final statusText = needsAttention
        ? 'PERHATIAN'
        : isEnRoute
            ? 'DALAM PERJALANAN'
            : 'MENGANGGUR';
    final assigned = s.contracts.where(
      (contract) => contract.contractId == v.assignedContractId,
    );
    final activeContract = assigned.isEmpty ? null : assigned.first;
    final city = isEnRoute
        ? (activeContract?.destinationCityName ?? 'Dalam perjalanan')
        : (s.company?.headquartersCity ?? 'Markas');
    final vehicleType = switch (v.mode) {
      TransportMode.road => 'Darat',
      TransportMode.sea => 'Kapal',
      TransportMode.air => 'Pesawat',
    };
    final vehicleIcon = switch (v.mode) {
      TransportMode.road => Icons.local_shipping_rounded,
      TransportMode.sea => Icons.directions_boat_filled_rounded,
      TransportMode.air => Icons.flight_rounded,
    };
    final completedDistance = s.contracts
        .where((contract) =>
            contract.assignedVehicleId == v.vehicleId &&
            contract.status == ContractStatus.completed)
        .fold<double>(0, (total, contract) => total + contract.distanceKm);
    final odometer = completedDistance.round();
    final capacityPalettes = (v.cargoCapacity / 500).round();
    final vehicleNumber = s.vehicles.indexOf(v) + 1;
    final tireLabel = v.mode == TransportMode.road ? 'ban Standar' : 'konfigurasi';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16222A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF22323D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  spec.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _quickAction(
                icon: Icons.build_rounded,
                label: 'Servis',
                onTap: () => _service(context, s, v),
              ),
              const SizedBox(width: 7),
              _quickAction(
                icon: Icons.palette_rounded,
                label: 'Livery',
                onTap: () => _showLiveryDialog(context, spec.name),
              ),
              const SizedBox(width: 7),
              _quickAction(
                icon: Icons.map_rounded,
                label: 'Lacak',
                onTap: () {
                  s.setTab(2);
                  s.showToast('Lokasi armada: $city.');
                },
              ),
              const SizedBox(width: 7),
              _quickAction(
                icon: Icons.link_rounded,
                label: 'Trailer',
                onTap: () => s.showToast(
                  'Sistem pemasangan trailer belum tersedia.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '#$vehicleNumber • ${spec.mode == TransportMode.road ? 'Box / Van' : vehicleType} • $tireLabel',
            style: const TextStyle(
              color: Color(0xFFD6A35C),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 128,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1D303B), Color(0xFF101A20)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 12,
                  top: 10,
                  child: Text(
                    vehicleType.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0x337F9BAA),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    vehicleIcon,
                    size: 82,
                    color: const Color(0xFFD5E1E8),
                    shadows: const [
                      Shadow(color: Color(0x66000000), blurRadius: 18),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 9,
                  child: Text(
                    'ADIEXPRESS  •  FLEET UNIT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$capacityPalettes palet • ${v.effectiveMaxSpeed.toStringAsFixed(0)} km/j',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'BBM',
                  value:
                      '${(fuelRatio * 100).round()}% • ${v.fuel.toStringAsFixed(0)} L',
                  progress: fuelRatio,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _statCard(
                  title: 'KONDISI',
                  value: '${v.condition.toStringAsFixed(0)}%',
                  progress: (v.condition / 100).clamp(0.0, 1.0).toDouble(),
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _statCard(
                  title: 'MASA PAKAI',
                  value: '${_compactKm(odometer)} / 500k km',
                  progress: (odometer / 500000).clamp(0.0, 1.0).toDouble(),
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              _info('SOPIR', 'Kamu'),
              _info('POSISI', city),
              _info('NILAI JUAL KEMBALI',
                  GameFormatters.currency(v.estimatedValue)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(vehicleIcon, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Parkir di $city • kendaraan $vehicleType',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 15, color: AppColors.textPrimary),
          ),
        ),
      );

  Widget _statCard({
    required String title,
    required String value,
    required double progress,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF111C22),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.45,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: color,
                backgroundColor: AppColors.border,
              ),
            ),
          ],
        ),
      );

  Widget _info(String title, String value) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );

  String _compactKm(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }

  Future<void> _service(
      BuildContext context, AppState s, Vehicle vehicle) async {
    try {
      await s.refuelAndRepairVehicle(vehicle.vehicleId);
    } catch (error) {
      s.showToast(error.toString());
    }
  }

  Future<void> _showLiveryDialog(BuildContext context, String vehicleName) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Warna Livery'),
        content: Text(
          'Kustomisasi livery untuk $vehicleName akan tersedia saat sistem branding armada dirilis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _dealership(BuildContext context, AppState s) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: VehicleCatalog.catalog
              .map(
                (entry) => ListTile(
                  leading: Icon(switch (entry.mode) {
                    TransportMode.road => Icons.local_shipping,
                    TransportMode.sea => Icons.directions_boat,
                    TransportMode.air => Icons.flight,
                  }),
                  title: Text(entry.name),
                  subtitle: Text(
                    '${entry.cargoCapacityKg.toStringAsFixed(0)} kg • ${entry.maxSpeedKmh.toStringAsFixed(0)} km/j',
                  ),
                  trailing: Text(GameFormatters.currency(entry.purchasePrice)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await s.buyVehicle(entry.tier);
                    } catch (error) {
                      s.showToast(error.toString());
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

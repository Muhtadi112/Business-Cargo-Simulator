import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/formatters.dart';
import '../models/contract.dart';
import '../theme/app_theme.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});
  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}
class _ContractsScreenState extends State<ContractsScreen> {
  int _tab = 0;
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.contracts;
    final categories = <List<CargoContract>>[
      all.where((e) => e.status == ContractStatus.available).toList(),
      all.where((e) => e.status == ContractStatus.inTransit).toList(),
      all.where((e) => e.status == ContractStatus.completed || e.status == ContractStatus.failed).toList(),
      <CargoContract>[],
    ];
    final visible = categories[_tab].where((e) =>
      '${e.originCityName} ${e.destinationCityName} ${e.cargoType.name}'.toLowerCase().contains(_query.toLowerCase())
    ).toList();
    const labels = ['Tersedia', 'Aktif', 'Riwayat', 'Barang pemain'];
    return ListView(padding: const EdgeInsets.all(13), children: [
      Row(children: List.generate(4, (i) => Expanded(child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: ChoiceChip(
          label: Text('${labels[i]} • ${categories[i].length}', style: const TextStyle(fontSize: 9)),
          selected: _tab == i, onSelected: (_) => setState(() => _tab = i),
        ),
      )))),
      const SizedBox(height: 12),
      TextField(onChanged: (v) => setState(() => _query = v),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari rute atau muatan')),
      const SizedBox(height: 12),
      if (visible.isEmpty)
        const Center(child: Padding(padding: EdgeInsets.all(35), child: Column(children: [
          Icon(Icons.assignment_outlined, size: 44, color: AppColors.textSecondary),
          Text('Belum ada kontrak di kategori ini', style: TextStyle(color: AppColors.textSecondary)),
        ])))
      else
        ...visible.map((c) => _ContractCard(
          contract: c, canDispatch: _tab == 0,
          onDispatch: () => _dispatch(context, state, c.contractId),
        )),
    ]);
  }
  Future<void> _dispatch(BuildContext context, AppState state, String id) async {
    final vehicles = state.vehicles.where((v) => v.canDrive).toList();
    if (vehicles.isEmpty) { state.showToast('Tidak ada kendaraan yang siap berangkat.'); return; }
    await showModalBottomSheet<void>(context: context, builder: (sheetContext) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: vehicles.map((v) => ListTile(
        title: Text(v.specifications.name), subtitle: Text('${v.fuel.toStringAsFixed(0)} L BBM'),
        onTap: () async {
          Navigator.pop(sheetContext);
          try { await state.dispatchContract(contractId: id, vehicleId: v.vehicleId); }
          catch (error) { state.showToast(error.toString()); }
        },
      )).toList()),
    ));
  }
}
class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract, required this.canDispatch, required this.onDispatch});
  final CargoContract contract;
  final bool canDispatch;
  final VoidCallback onDispatch;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(contract.cargoType.name.toUpperCase(), style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w900, fontSize: 10))),
        Text('${contract.distanceKm.toStringAsFixed(0)} km', style: const TextStyle(color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 9),
      Row(children: [
        Expanded(child: Text(contract.originCityName, style: const TextStyle(fontWeight: FontWeight.w900))),
        const Icon(Icons.arrow_forward, color: AppColors.emerald),
        Expanded(child: Text(contract.destinationCityName, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900))),
      ]),
      Text('${contract.cargoWeightKg.toStringAsFixed(0)} kg • ${contract.rewardXp} XP', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      const Divider(),
      Row(children: [
        Expanded(child: Text(GameFormatters.currency(contract.reward), style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w900, fontSize: 16))),
        if (canDispatch) FilledButton(onPressed: onDispatch, child: const Text('Pilih kendaraan')),
      ]),
    ]),
  );
}
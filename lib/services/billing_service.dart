enum LocalProduct { vipMembership, extraFleetSlots }

class LocalPurchaseResult {
  const LocalPurchaseResult({
    required this.success,
    required this.product,
    required this.message,
    required this.purchasedAtUtc,
  });

  final bool success;
  final LocalProduct product;
  final String message;
  final DateTime purchasedAtUtc;
}

/// Local-only purchase simulation for gameplay testing. This does not contact
/// Google Play and does not charge money.
class BillingService {
  bool _vipActive = false;
  int _extraFleetSlots = 0;

  bool get isVipActive => _vipActive;
  int get extraFleetSlots => _extraFleetSlots;
  int get fleetCapacity => 12 + _extraFleetSlots;
  bool get isSimulationOnly => true;

  Future<LocalPurchaseResult> purchase(LocalProduct product) async {
    try {
      switch (product) {
        case LocalProduct.vipMembership:
          _vipActive = true;
          break;
        case LocalProduct.extraFleetSlots:
          _extraFleetSlots += 5;
          break;
      }
      return LocalPurchaseResult(
        success: true,
        product: product,
        message: product == LocalProduct.vipMembership
            ? 'VIP simulasi berhasil diaktifkan.'
            : '5 slot armada simulasi berhasil ditambahkan.',
        purchasedAtUtc: DateTime.now().toUtc(),
      );
    } catch (error) {
      return LocalPurchaseResult(
        success: false,
        product: product,
        message: 'Simulasi pembelian gagal: $error',
        purchasedAtUtc: DateTime.now().toUtc(),
      );
    }
  }

  Future<void> restorePurchases() async {
    // Purchases exist only in this service instance; no Play Store restore.
  }

  void reset() {
    _vipActive = false;
    _extraFleetSlots = 0;
  }
}

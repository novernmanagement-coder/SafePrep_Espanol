import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'app_state.dart';
import 'app_state_persistence.dart';

// ─────────────────────────────────────────────────────────────────
// IDs de producto — deben coincidir exactamente con App Store Connect
// ─────────────────────────────────────────────────────────────────
const String kProductSevenDay = 'SafePrepSevenDay'; // $4.99 — 7 días
const String kProductFourteenDay = 'SafePrepFourteenDay'; // $8.99 — 14 días
const String kProductUnlockApp = 'SafePrepUnlock'; // $9.99 — vitalicio
const String kProductUpgrade =
    'com.geraldmiller.safeprep.upgrade'; // $4.99 — actualizar a vitalicio

// ─────────────────────────────────────────────────────────────────
// IAPService
// ─────────────────────────────────────────────────────────────────
class IAPService {
  IAPService._();
  static final IAPService instance = IAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? _sevenDayProduct;
  ProductDetails? _fourteenDayProduct;
  ProductDetails? _unlockProduct;
  ProductDetails? _upgradeProduct;

  bool _available = false;
  bool get isAvailable => _available;

  // ── Inicialización ──────────────────────────────────────────
  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (e) => debugPrint('IAP stream error: $e'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({
      kProductSevenDay,
      kProductFourteenDay,
      kProductUnlockApp,
      kProductUpgrade,
    });

    if (response.error != null) {
      debugPrint('IAP product load error: ${response.error}');
      return;
    }

    for (final p in response.productDetails) {
      switch (p.id) {
        case kProductSevenDay:
          _sevenDayProduct = p;
          break;
        case kProductFourteenDay:
          _fourteenDayProduct = p;
          break;
        case kProductUnlockApp:
          _unlockProduct = p;
          break;
        case kProductUpgrade:
          _upgradeProduct = p;
          break;
      }
    }

    debugPrint(
      'IAP products loaded: ${response.productDetails.map((p) => p.id).toList()}',
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  // ── Manejadores de compra ───────────────────────────────────
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccess(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint('IAP error: ${purchase.error?.message}');
          break;
        case PurchaseStatus.canceled:
          debugPrint('IAP canceled: ${purchase.productID}');
          break;
        case PurchaseStatus.pending:
          debugPrint('IAP pending: ${purchase.productID}');
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _handleSuccess(PurchaseDetails purchase) async {
    final state = AppState();
    state.hasUnlockedApp = true;
    state.purchaseDate = DateTime.now();

    switch (purchase.productID) {
      case kProductSevenDay:
        state.purchaseType = PurchaseType.sevenDay;
        break;
      case kProductFourteenDay:
        state.purchaseType = PurchaseType.fourteenDay;
        break;
      case kProductUnlockApp:
        state.purchaseType = PurchaseType.lifetime;
        break;
      case kProductUpgrade:
        // Actualización — mantener fecha de compra, elevar a vitalicio
        state.purchaseType = PurchaseType.lifetime;
        break;
    }

    await AppStatePersistence.save();
    debugPrint(
      'IAP success: ${purchase.productID} → ${state.purchaseType.name}',
    );
  }

  // ── Comprar ─────────────────────────────────────────────────
  Future<IAPResult> _buyProduct(ProductDetails? product, String id) async {
    if (!_available) return IAPResult.storeUnavailable;
    if (product == null) {
      await _loadProducts();
      if (product == null) return IAPResult.productNotFound;
    }
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product!),
      );
      return IAPResult.initiated;
    } catch (e) {
      debugPrint('IAP buy error: $e');
      return IAPResult.error;
    }
  }

  Future<IAPResult> buySevenDay() async {
    if (!_available) return IAPResult.storeUnavailable;
    if (_sevenDayProduct == null) await _loadProducts();
    if (_sevenDayProduct == null) return IAPResult.productNotFound;
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _sevenDayProduct!),
      );
      return IAPResult.initiated;
    } catch (e) {
      debugPrint('IAP buy error: $e');
      return IAPResult.error;
    }
  }

  Future<IAPResult> buyFourteenDay() async {
    if (!_available) return IAPResult.storeUnavailable;
    if (_fourteenDayProduct == null) await _loadProducts();
    if (_fourteenDayProduct == null) return IAPResult.productNotFound;
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _fourteenDayProduct!),
      );
      return IAPResult.initiated;
    } catch (e) {
      debugPrint('IAP buy error: $e');
      return IAPResult.error;
    }
  }

  Future<IAPResult> buyUnlockApp() async {
    if (!_available) return IAPResult.storeUnavailable;
    if (_unlockProduct == null) await _loadProducts();
    if (_unlockProduct == null) return IAPResult.productNotFound;
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _unlockProduct!),
      );
      return IAPResult.initiated;
    } catch (e) {
      debugPrint('IAP buy error: $e');
      return IAPResult.error;
    }
  }

  Future<IAPResult> buyUpgrade() async {
    if (!_available) return IAPResult.storeUnavailable;
    if (_upgradeProduct == null) await _loadProducts();
    if (_upgradeProduct == null) return IAPResult.productNotFound;
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _upgradeProduct!),
      );
      return IAPResult.initiated;
    } catch (e) {
      debugPrint('IAP buy error: $e');
      return IAPResult.error;
    }
  }

  // ── Restaurar ────────────────────────────────────────────────
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  // ── Cadenas de precio ────────────────────────────────────────
  String get sevenDayPrice => _sevenDayProduct?.price ?? '\$4.99';
  String get fourteenDayPrice => _fourteenDayProduct?.price ?? '\$8.99';
  String get unlockPrice => _unlockProduct?.price ?? '\$9.99';
  String get upgradePrice => _upgradeProduct?.price ?? '\$4.99';
}

// ── Enum de resultado ──────────────────────────────────────────
enum IAPResult { initiated, storeUnavailable, productNotFound, error }

extension IAPErrorMessage on IAPResult {
  String? get userMessage {
    switch (this) {
      case IAPResult.initiated:
        return null;
      case IAPResult.storeUnavailable:
        return 'El App Store no está disponible en este momento. Por favor, inténtalo más tarde.';
      case IAPResult.productNotFound:
        return 'No se pudo cargar la compra. Por favor, verifica tu conexión e inténtalo de nuevo.';
      case IAPResult.error:
        return 'Algo salió mal. Por favor, inténtalo de nuevo.';
    }
  }
}

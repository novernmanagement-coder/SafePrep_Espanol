import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'app_state.dart';
import 'app_state_persistence.dart';
import 'mixpanel_service.dart';

// ─────────────────────────────────────────────────────────────────
// IDs de producto — deben coincidir exactamente con App Store Connect
// (iOS) y Play Console (Android).
//
// Google Play NO permite mayúsculas en los IDs de producto, así que
// Android usa sus propios IDs en minúsculas (mismo producto, distinto
// ID por tienda). Los IDs de iOS ya están en vivo — no cambiarlos.
// defaultTargetPlatform (de flutter/foundation, vía material) en vez de
// dart:io, igual que en SafePrep Tax.
// ─────────────────────────────────────────────────────────────────
final bool _isAndroid = defaultTargetPlatform == TargetPlatform.android;

final String kProductSevenDay = _isAndroid
    ? 'android_es_sevenday'
    : 'SafePrepEspanolUnlock1Week'; // $4.99 — 7 días
final String kProductFourteenDay = _isAndroid
    ? 'android_es_fourteenday'
    : 'SafePrepEspanolUnlock2Week'; // $8.99 — 14 días
final String kProductUnlockApp = _isAndroid
    ? 'android_es_unlock'
    : 'SafePrepEspanolUnlock'; // $9.99 — vitalicio

// Cuánto tiempo esperará una llamada buy* a que StoreKit resuelva
// (comprado, cancelado o con error) antes de rendirse y devolver
// IAPResult.timeout. Evita que un spinner de carga se quede
// atascado para siempre si el stream de compra nunca emite en algún
// caso límite (p. ej. la app pasa a segundo plano a mitad de la
// compra y se pierde el callback de StoreKit).
const Duration _purchaseTimeout = Duration(seconds: 90);

// ─────────────────────────────────────────────────────────────────
// IAPService
//
// FIXED (ported from SafePrep Manager): buy*() methods now AWAIT the
// real purchase-stream outcome instead of returning immediately after
// submitting the request. The old version returned `.initiated` the
// instant the App Store sheet was requested — success/cancel/error
// resolved later via a stream callback with no way for the caller to
// know what happened, so a button's "Purchasing…" spinner would just
// stop with no result, leaving the paywall stuck after a genuinely
// successful purchase. This was a real bug, not a style choice — see
// [[safeprep-manager]] memory for the original fix.
// ─────────────────────────────────────────────────────────────────
class IAPService {
  IAPService._();
  static final IAPService instance = IAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? _sevenDayProduct;
  ProductDetails? _fourteenDayProduct;
  ProductDetails? _unlockProduct;

  bool _available = false;
  bool get isAvailable => _available;

  // Rastrea las compras en curso para que _onPurchaseUpdate pueda
  // resolver el Future que el método buy* que la llamó está
  // esperando. Indexado por ID de producto — esta app solo tiene una
  // compra en curso por producto a la vez, ya que los botones de
  // compra se deshabilitan mientras cargan.
  final Map<String, Completer<IAPResult>> _pendingPurchases = {};

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
    });

    if (response.error != null) {
      debugPrint('IAP product load error: ${response.error}');
      return;
    }

    // if/else en vez de switch: los IDs ya no son constantes de
    // compilación (dependen de la plataforma), y `case` las exige.
    for (final p in response.productDetails) {
      if (p.id == kProductSevenDay) {
        _sevenDayProduct = p;
      } else if (p.id == kProductFourteenDay) {
        _fourteenDayProduct = p;
      } else if (p.id == kProductUnlockApp) {
        _unlockProduct = p;
      }
    }

    debugPrint(
      'IAP products loaded: ${response.productDetails.map((p) => p.id).toList()}',
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  // ── Manejador del stream de compra ──────────────────────────
  // Aquí es donde se conoce el resultado REAL de una compra —
  // buyNonConsumable() solo confirma que la solicitud fue enviada,
  // no si la persona la completó, canceló, o tuvo un error en la
  // hoja del App Store. Cada resultado aquí resuelve el Completer
  // que el método buy* que llamó está esperando, y también registra
  // un evento de Mixpanel para que los resultados de compra sean
  // visibles en analítica, no solo los toques de botón.
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final completer = _pendingPurchases[purchase.productID];

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccess(purchase);
          MixpanelService.instance.track(
            'purchase_completed',
            properties: {
              'product_id': purchase.productID,
              'restored': purchase.status == PurchaseStatus.restored,
            },
          );
          completer?.complete(IAPResult.success);
          _pendingPurchases.remove(purchase.productID);
          break;

        case PurchaseStatus.error:
          debugPrint('IAP error: ${purchase.error?.message}');
          MixpanelService.instance.track(
            'purchase_failed',
            properties: {
              'product_id': purchase.productID,
              'error': purchase.error?.message ?? 'unknown',
            },
          );
          completer?.complete(IAPResult.error);
          _pendingPurchases.remove(purchase.productID);
          break;

        case PurchaseStatus.canceled:
          debugPrint('IAP canceled: ${purchase.productID}');
          MixpanelService.instance.track(
            'purchase_canceled',
            properties: {'product_id': purchase.productID},
          );
          completer?.complete(IAPResult.canceled);
          _pendingPurchases.remove(purchase.productID);
          break;

        case PurchaseStatus.pending:
          debugPrint('IAP pending: ${purchase.productID}');
          // Aún no resolver — StoreKit sigue trabajando (p. ej.
          // aprobación familiar "Ask to Buy"). Quien llamó sigue
          // esperando hasta _purchaseTimeout.
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _handleSuccess(PurchaseDetails purchase) async {
    final state = AppState();

    // Limpiar el historial de prueba solo en la primera compra.
    if (!state.hasUnlockedApp) {
      state.testHistory.clear();
      state.clearCurriculumProgress();
      state.hasSeenIntro = false;
    }

    state.hasUnlockedApp = true;
    state.purchaseDate = DateTime.now();

    if (purchase.productID == kProductSevenDay) {
      state.purchaseType = PurchaseType.sevenDay;
    } else if (purchase.productID == kProductFourteenDay) {
      state.purchaseType = PurchaseType.fourteenDay;
    } else if (purchase.productID == kProductUnlockApp) {
      state.purchaseType = PurchaseType.lifetime;
    }

    await AppStatePersistence.save();
    debugPrint(
      'IAP success: ${purchase.productID} → ${state.purchaseType.name}',
    );
  }

  // ── Comprar ─────────────────────────────────────────────────
  // Flujo de compra compartido usado por cada método buy* de abajo.
  // Envía la solicitud, luego ESPERA a que _onPurchaseUpdate la
  // resuelva de verdad (success / canceled / error) en vez de
  // regresar apenas se solicita la hoja del App Store.
  Future<IAPResult> _purchase(ProductDetails? Function() getProduct) async {
    if (!_available) return IAPResult.storeUnavailable;

    var product = getProduct();
    if (product == null) {
      await _loadProducts();
      product = getProduct();
      if (product == null) return IAPResult.productNotFound;
    }

    final completer = Completer<IAPResult>();
    _pendingPurchases[product.id] = completer;

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('IAP buy error: $e');
      _pendingPurchases.remove(product.id);
      return IAPResult.error;
    }

    return completer.future.timeout(
      _purchaseTimeout,
      onTimeout: () {
        _pendingPurchases.remove(product!.id);
        return IAPResult.timeout;
      },
    );
  }

  Future<IAPResult> buySevenDay() => _purchase(() => _sevenDayProduct);

  Future<IAPResult> buyFourteenDay() => _purchase(() => _fourteenDayProduct);

  Future<IAPResult> buyUnlockApp() => _purchase(() => _unlockProduct);

  // ── Restaurar ────────────────────────────────────────────────
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  // ── Cadenas de precio ────────────────────────────────────────
  String get sevenDayPrice => _sevenDayProduct?.price ?? '\$4.99';
  String get fourteenDayPrice => _fourteenDayProduct?.price ?? '\$8.99';
  String get unlockPrice => _unlockProduct?.price ?? '\$9.99';
}

// ── Enum de resultado ──────────────────────────────────────────
// NOTA: esto reemplaza el enum anterior, que tenía `initiated`
// (queriendo decir "solicitud enviada", no "compra resuelta"). Cada
// buy* ahora significa: `success` es que la compra realmente se
// completó; ya no existe un valor que signifique "todavía no lo
// sabemos".
enum IAPResult {
  success,
  canceled,
  storeUnavailable,
  productNotFound,
  timeout,
  error,
}

extension IAPErrorMessage on IAPResult {
  String? get userMessage {
    switch (this) {
      case IAPResult.success:
        return null;
      case IAPResult.canceled:
        return null; // el usuario canceló a propósito — no hay error que mostrar
      case IAPResult.storeUnavailable:
        return 'El App Store no está disponible en este momento. Por favor, inténtalo más tarde.';
      case IAPResult.productNotFound:
        return 'No se pudo cargar la compra. Por favor, verifica tu conexión e inténtalo de nuevo.';
      case IAPResult.timeout:
        return 'La compra está tardando más de lo esperado. Verifica tu conexión e inténtalo de nuevo — si se te cobró, usa Restaurar compras.';
      case IAPResult.error:
        return 'Algo salió mal. Por favor, inténtalo de nuevo.';
    }
  }
}

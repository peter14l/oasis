import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IAPService extends ChangeNotifier {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  InAppPurchase? _iapInstance;
  InAppPurchase get _iap => _iapInstance ?? InAppPurchase.instance;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  final List<String> _productIds = ['oasis_pro_monthly'];

  Future<void> init() async {
    try {
      // Accessing instance inside init to avoid potential early access issues
      _iapInstance = InAppPurchase.instance;
      
      _isAvailable = await _iap.isAvailable().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('IAP isAvailable() timed out after 5 seconds');
          return false;
        },
      );
    } catch (e) {
      debugPrint('IAP not available on this platform: $e');
      _isAvailable = false;
    }
    
    if (!_isAvailable) {
      debugPrint('IAP not available or timed out, skipping further IAP init');
      return;
    }

    try {
      final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('IAP Error: $error'),
      );

      await fetchProducts().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('IAP fetchProducts() timed out');
        },
      );
    } catch (e) {
      debugPrint('Error during IAP stream/product setup: $e');
    }
  }

  Future<void> fetchProducts() async {
    if (!_isAvailable) return;

    final ProductDetailsResponse response = await _iap.queryProductDetails(
      _productIds.toSet(),
    );
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    notifyListeners();
  }

  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    if (Platform.isIOS || Platform.isMacOS) {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Show pending UI if needed
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final bool valid = await _verifyPurchase(purchase);
        if (valid) {
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      final supabase = Supabase.instance.client;

      // Call the verification Edge Function
      // We'll need to implement verify-iap Edge Function later
      final response = await supabase.functions.invoke(
        'verify-iap',
        body: {
          'product_id': purchase.productID,
          'purchase_id': purchase.purchaseID,
          'verification_data': purchase.verificationData.serverVerificationData,
          'platform': Platform.isIOS || Platform.isMacOS ? 'apple' : 'google',
        },
      );

      return response.status == 200;
    } catch (e) {
      debugPrint('Purchase verification failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

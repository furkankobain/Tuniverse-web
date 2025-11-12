// Web stub
class PurchaseService {
  static Future<void> initialize() async {}
  static Future<bool> isPro() async => false;
  static Future<void> purchasePro() async {}
  static Future<void> restorePurchases() async {}
  static Future<void> purchaseProduct(String productId) async {}
  static Future<bool> validateTrialCode(String code) async => false;
  static Future<bool> activateTrial() async => false;
}

class SkuIds {
  static const String pro = 'pro';
  static String getProMonthlySku([bool? isTurkey]) => 'pro_monthly';
  static String getProAnnualSku([bool? isTurkey]) => 'pro_annual';
  static String getAdFreeSku([bool? isTurkey]) => 'ad_free';
}

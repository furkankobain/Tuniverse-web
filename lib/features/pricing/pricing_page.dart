import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuniverse/shared/services/purchase_service.dart';
import 'package:tuniverse/shared/services/pro_status_service.dart';
import 'package:tuniverse/core/providers/language_provider.dart';

class PricingPage extends ConsumerStatefulWidget {
  const PricingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends ConsumerState<PricingPage> {
  bool _isLoading = false;
  TextEditingController _codeController = TextEditingController();
  String? _trialMessage;
  late bool _isTurkish;
  late String _currencySymbol;
  late Map<String, String> _prices;

  @override
  void initState() {
    super.initState();
    PurchaseService.initialize();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deviceLocale = Localizations.localeOf(context);
    final isTurkey = deviceLocale.countryCode?.toUpperCase() == 'TR';
    final appLanguage = ref.watch(languageProvider);
    _isTurkish = appLanguage?.languageCode == 'tr' ?? false;
    
    // Fiyat ayarla: Konuma göre para birimi
    _currencySymbol = isTurkey ? '₺' : r'$';
    _prices = isTurkey
        ? {
            'proMonthly': '₺49.99',
            'proAnnual': '₺299.99',
            'adFree': '₺29.99',
          }
        : {
            'proMonthly': r'$4.99',
            'proAnnual': r'$18.99',
            'adFree': r'$3.99',
          };
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _purchaseProduct(String productId) async {
    setState(() => _isLoading = true);
    try {
      await PurchaseService.purchaseProduct(productId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satın alma hatası: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _validateTrialCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _trialMessage = 'Kod boş olamaz');
      return;
    }

    final isValid = await PurchaseService.validateTrialCode(code);
    if (!isValid) {
      setState(() => _trialMessage = '❌ Geçersiz kod');
      return;
    }

    // Code valid - activate trial
    final success = await PurchaseService.activateTrial();
    if (success) {
      setState(() => _trialMessage = '✅ 7 gün ücretsiz deneme aktif!');
      // Clear cache so pro status updates
      ProStatusService.clearCache();
      
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() => _trialMessage = '❌ Aktivasyon başarısız');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiyatlandırma Planları'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            const SizedBox(height: 16),
            const Text(
              'Sende Hangi Paket?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tuniverse Premium sürümüne geçerek tüm özellikleri açın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Free Plan
            _buildPricingCard(
              title: 'Free',
              price: '${_currencySymbol}0',
              duration: _isTurkish ? 'Sonsuza dek' : 'Forever',
              features: [
                '✅ Müzik paylaşımı',
                '✅ Profil özelleştirmesi',
                '✅ Yorum yapabilme',
                '❌ Reklam var',
                '❌ Fotoğraf yükleme',
                '❌ Özel temalar',
              ],
              isHighlighted: false,
              onTap: () => Navigator.pop(context),
              buttonText: 'Zaten Kullanıyorum',
            ),
            const SizedBox(height: 16),

            // AD_FREE Plan
            _buildPricingCard(
              title: _isTurkish ? 'Reklamslız' : 'Ad-Free',
              price: _prices['adFree']!,
              duration: _isTurkish ? 'Bir kerelik ödeme' : 'One-time payment',
              features: [
                _isTurkish ? '✅ Tüm üretsiz özellikler' : '✅ All free features',
                _isTurkish ? '✅ Reklamslız kullanım' : '✅ Ad-free experience',
                _isTurkish ? '❌ Fotoğraf yükleme' : '❌ Photo upload',
                _isTurkish ? '❌ Özel temalar' : '❌ Premium themes',
              ],
              isHighlighted: false,
              onTap: () => _purchaseProduct(SkuIds.getAdFreeSku(_isTurkish)),
              buttonText: _isTurkish ? 'Satın Al' : 'Buy',
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),

            // PRO Monthly
            _buildPricingCard(
              title: _isTurkish ? 'PRO - Aylık' : 'PRO - Monthly',
              price: _prices['proMonthly']!,
              duration: _isTurkish ? '/ay (İptal edilebilir)' : '/month (Cancel anytime)',
              features: [
                _isTurkish ? '✅ Tüm özellikler' : '✅ All features',
                _isTurkish ? '✅ Reklamslız kullanım' : '✅ Ad-free experience',
                _isTurkish ? '✅ Fotoğraf yükleme' : '✅ Photo upload',
                _isTurkish ? '✅ Zengin metin editörü' : '✅ Rich text editor',
                _isTurkish ? '✅ Özel temalar' : '✅ Premium themes',
                _isTurkish ? '✅ PRO rozeti' : '✅ PRO badge',
              ],
              isHighlighted: true,
              onTap: () => _purchaseProduct(SkuIds.getProMonthlySku(_isTurkish)),
              buttonText: _isTurkish ? 'PRO Ol' : 'Go PRO',
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),

            // PRO Annual
            _buildPricingCard(
              title: _isTurkish ? 'PRO - Yıllık' : 'PRO - Annual',
              price: _prices['proAnnual']!,
              duration: _isTurkish ? '/yıl (En iyi fiyat)' : '/year (Best value)',
              features: [
                _isTurkish ? '✅ Tüm özellikler' : '✅ All features',
                _isTurkish ? '✅ Reklamslız kullanım' : '✅ Ad-free experience',
                _isTurkish ? '✅ Fotoğraf yükleme' : '✅ Photo upload',
                _isTurkish ? '✅ Zengin metin editörü' : '✅ Rich text editor',
                _isTurkish ? '✅ Özel temalar' : '✅ Premium themes',
                _isTurkish ? '✅ PRO rozeti' : '✅ PRO badge',
                _isTurkish ? '✅ %63 tasarruf' : '✅ 63% save (vs monthly)',
              ],
              isHighlighted: true,
              onTap: () => _purchaseProduct(SkuIds.getProAnnualSku(_isTurkish)),
              buttonText: _isTurkish ? 'Yıllık PRO' : 'Annual PRO',
              isLoading: _isLoading,
              badge: _isTurkish ? 'EN İYİ' : 'BEST',
            ),
            const SizedBox(height: 32),

            // Trial Code Section
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isTurkish ? '🎁 Deneme Kodun Var mı?' : '🎁 Have a Trial Code?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isTurkish ? '7 gün ücretsiz PRO deneyimi için kodunu gir' : 'Enter your code for 7 days free PRO access',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_trialMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _trialMessage!.startsWith('✅')
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _trialMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _trialMessage!.startsWith('✅')
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: _isTurkish ? 'Deneme kodunu gir' : 'Enter trial code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _validateTrialCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(_isTurkish ? 'Kodu Doğrula' : 'Verify Code'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // FAQ/Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTurkish ? '📋 Sik Sorulan Sorular' : '📋 FAQ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFaqItem(
                      _isTurkish ? 'Aylık aboneliği iptal edebilir miyim?' : 'Can I cancel monthly subscription?',
                      _isTurkish ? 'Evet, Google Play Store ayarlarından istediğiniz zaman iptal edebilirsiniz.' : 'Yes, you can cancel anytime from Google Play Store settings.',
                    ),
                    _buildFaqItem(
                      _isTurkish ? 'Reklamslız seçeneği başka cihazlarda kullanabilir miyim?' : 'Can I use ad-free on other devices?',
                      _isTurkish ? 'Evet, aynı Google hesabı ile giriş yapıldığında tüm cihazlarda aktif olur.' : 'Yes, it works on all devices with the same Google account.',
                    ),
                    _buildFaqItem(
                      _isTurkish ? 'Para iadesi mümkün müdür?' : 'Is refund possible?',
                      _isTurkish ? 'Google Play politikasına göre 48 saat içinde iade talep edebilirsiniz.' : 'You can request refund within 48 hours according to Google Play policy.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String duration,
    required List<String> features,
    required bool isHighlighted,
    required VoidCallback onTap,
    required String buttonText,
    bool isLoading = false,
    String? badge,
  }) {
    return Card(
      elevation: isHighlighted ? 8 : 2,
      color: isHighlighted ? Colors.deepPurple.shade50 : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isHighlighted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AYLAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: price,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: duration,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(feature),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHighlighted
                          ? Colors.deepPurple
                          : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

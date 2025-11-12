import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuniverse/shared/services/purchase_service.dart';
import 'package:tuniverse/shared/services/pro_status_service.dart';
import 'package:tuniverse/core/providers/language_provider.dart';

class ProPlansPage extends ConsumerStatefulWidget {
  const ProPlansPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProPlansPage> createState() => _ProPlansPageState();
}

class _ProPlansPageState extends ConsumerState<ProPlansPage> {
  bool _isLoading = false;
  String? _promoCode;
  String? _promoMessage;
  TextEditingController _promoController = TextEditingController();
  late bool _isTurkish;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appLanguage = ref.watch(languageProvider);
    _isTurkish = appLanguage?.languageCode == 'tr' ?? false;
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _purchaseProduct(String productId) async {
    setState(() => _isLoading = true);
    try {
      await PurchaseService.purchaseProduct(productId);
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isTurkish ? '❌ Hata: $e' : '❌ Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Celebration container
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Celebrate emoji
                  const Text(
                    '🎉',
                    style: TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    _isTurkish ? 'Hoşgeldin PRO Dünyasına! 🚀' : 'Welcome to PRO! 🚀',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Message
                  Text(
                    _isTurkish
                        ? 'Satın almam için teşekkür ederiz! 💜\n\nArtık tüm PRO özelliklerine erişebilirsin:'
                        : 'Thank you for your purchase! 💜\n\nYou now have access to all PRO features:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Benefits
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBenefit('🚫', _isTurkish ? 'Reklamsız Deneyim' : 'Ad-Free Experience'),
                        const SizedBox(height: 12),
                        _buildBenefit('📸', _isTurkish ? 'Fotoğraf Yükleme' : 'Photo Upload'),
                        const SizedBox(height: 12),
                        _buildBenefit('✍️', _isTurkish ? 'Zengin Metin Editörü' : 'Rich Text Editor'),
                        const SizedBox(height: 12),
                        _buildBenefit('🎨', _isTurkish ? 'Özel Temalar' : 'Premium Themes'),
                        const SizedBox(height: 12),
                        _buildBenefit('👑', _isTurkish ? 'PRO Rozeti' : 'PRO Badge'),
                        const SizedBox(height: 12),
                        _buildBenefit('⚡', _isTurkish ? 'Erken Erişim' : 'Early Access'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _isTurkish ? 'Kullanmaya Başla' : 'Get Started',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenefit(String emoji, String text) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _validatePromoCode() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _promoMessage = _isTurkish ? '❌ Kod boş olamaz' : '❌ Code cannot be empty');
      return;
    }

    // Promo kodları
    final validCodes = {
      'TUNIVERSE50': {
        'discount': 50,
        'type': 'percent', // or 'fixed'
        'message': _isTurkish ? '✅ %50 indirim! Kodu uygulandı.' : '✅ 50% off! Code applied.',
      },
      'LAUNCH30': {
        'discount': 30,
        'type': 'percent',
        'message': _isTurkish ? '✅ %30 indirim! Geçerli.' : '✅ 30% off! Valid.',
      },
      'WELCOME': {
        'discount': 7,
        'type': 'days',
        'message': _isTurkish ? '✅ 7 gün ücretsiz! Kodu uygulandı.' : '✅ 7 days free! Code applied.',
      },
    };

    if (validCodes.containsKey(code)) {
      setState(() {
        _promoCode = code;
        _promoMessage = validCodes[code]!['message'] as String;
      });
    } else {
      setState(() => _promoMessage = _isTurkish ? '❌ Geçersiz promosyon kodu' : '❌ Invalid promo code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceLocale = Localizations.localeOf(context);
    final isTurkey = deviceLocale.countryCode?.toUpperCase() == 'TR';
    final appLanguage = ref.watch(languageProvider);
    final isTurkish = appLanguage?.languageCode == 'tr' ?? false;

    final monthlyPrice = isTurkey ? '₺49.99' : r'$4.99';
    final yearlyPrice = isTurkey ? '₺299.99' : r'$18.99';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        title: Text(
          isTurkish ? 'PRO Planları' : 'PRO Plans',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF6200EA), const Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTurkish ? 'PRO Üyesi Ol' : 'Become PRO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isTurkish ? 'Tüm özelliklerin kilidini aç' : 'Unlock all features',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pro Features Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTurkish ? '✨ PRO Özellikleri' : '✨ PRO Features',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.image,
                    title: isTurkish ? '📸 Fotoğraf Yükleme' : '📸 Photo Upload',
                    description: isTurkish
                        ? 'İncelemelerinize fotoğraf ekleyin ve daha zengin içerik oluşturun'
                        : 'Add photos to your reviews and create richer content',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.text_fields,
                    title: isTurkish ? '✍️ Zengin Metin Editörü' : '✍️ Rich Text Editor',
                    description: isTurkish
                        ? 'Kalın, italik, renkler ve daha fazlası ile incelemelerinizi biçimlendirin'
                        : 'Format your reviews with bold, italic, colors and more',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.palette,
                    title: isTurkish ? '🎨 Özel Temalar' : '🎨 Premium Themes',
                    description: isTurkish
                        ? 'Eksklusif renk şemaları ve tasarımlar kullanın'
                        : 'Use exclusive color schemes and designs',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.remove_circle,
                    title: isTurkish ? '🚫 Reklamsız' : '🚫 Ad-Free',
                    description: isTurkish
                        ? 'Kesintisiz deneyim yaşayın, reklamlar tamamen kaldırılır'
                        : 'Enjoy uninterrupted experience, ads completely removed',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.verified,
                    title: isTurkish ? '👑 PRO Rozeti' : '👑 PRO Badge',
                    description: isTurkish
                        ? 'Profilinizde özel PRO rozeti görüntülenecek'
                        : 'Display special PRO badge on your profile',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.flash_on,
                    title: isTurkish ? '⚡ Erken Erişim' : '⚡ Early Access',
                    description: isTurkish
                        ? 'Yeni özeliklere herkesten önce erişin'
                        : 'Access new features before everyone else',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Pricing Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTurkish ? '💰 Fiyatlandırma' : '💰 Pricing',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Monthly Plan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isTurkish ? 'Aylık PRO' : 'Monthly PRO',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isTurkish ? 'İptal Edilebilir' : 'Cancel Anytime',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade900,
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
                                text: monthlyPrice,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: isTurkish ? '/ay' : '/month',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _purchaseProduct(SkuIds.getProMonthlySku(isTurkish)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(
                                    isTurkish ? 'Şimdi Al' : 'Buy Now',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Yearly Plan (Best Value)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF6200EA), const Color(0xFF9C27B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isTurkish ? 'Yıllık PRO' : 'Yearly PRO',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isTurkish ? '%63 Tasarruf' : '63% Save',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
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
                                    text: yearlyPrice,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: isTurkish ? '/yıl' : '/year',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isTurkish ? 'Ayda ₺25 gibi' : r'Just $1.58/month',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _purchaseProduct(SkuIds.getProAnnualSku(isTurkish)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6200EA),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Color(0xFF6200EA)),
                                        ),
                                      )
                                    : Text(
                                        isTurkish ? 'En İyi Teklif' : 'Best Value',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: -12,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isTurkish ? '⭐ ÖNERILEN' : '⭐ RECOMMENDED',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Promo Code Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTurkish ? '🎁 Promosyon Kodun Var mı?' : '🎁 Have a Promo Code?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isTurkish
                            ? 'Kodunuzu girin ve indirim alın'
                            : 'Enter your code and get a discount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _promoController,
                        decoration: InputDecoration(
                          hintText: isTurkish ? 'Promosyon kodunu gir' : 'Enter promo code',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.card_giftcard),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 12),
                      if (_promoMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _promoMessage!.startsWith('✅')
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _promoMessage!,
                            style: TextStyle(
                              color: _promoMessage!.startsWith('✅')
                                  ? Colors.green.shade900
                                  : Colors.red.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _validatePromoCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            isTurkish ? 'Kodu Doğrula' : 'Verify Code',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTurkish ? '💡 Aktif Kodlar:' : '💡 Active Codes:',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TUNIVERSE50 - %50 indirim\nLAUNCH30 - %30 indirim\nWELCOME - 7 gün ücretsiz',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTurkish ? '❓ Sık Sorulan Sorular' : '❓ FAQ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFaqItem(
                    isTurkish ? 'PRO alınca ne değişir?' : 'What changes when I buy PRO?',
                    isTurkish
                        ? 'Reklamlar kaldırılır, tüm özel özellikler açılır ve PRO rozeti aktivasyon edilir.'
                        : 'Ads are removed, all special features are unlocked, and PRO badge is activated.',
                    isDark,
                  ),
                  _buildFaqItem(
                    isTurkish ? 'PRO iptal edilebilir mi?' : 'Can PRO be cancelled?',
                    isTurkish
                        ? 'Evet, aylık PRO aboneliği istediğiniz zaman iptal edebilirsiniz.'
                        : 'Yes, monthly PRO subscription can be cancelled anytime.',
                    isDark,
                  ),
                  _buildFaqItem(
                    isTurkish ? 'Başka cihazlarda çalışır mı?' : 'Does it work on other devices?',
                    isTurkish
                        ? 'Evet, aynı Google hesabı ile giriş yapıldığında tüm cihazlarda aktif olur.'
                        : 'Yes, it works on all devices with the same Google account.',
                    isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer, bool isDark) {
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
        const SizedBox(height: 6),
        Text(
          answer,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

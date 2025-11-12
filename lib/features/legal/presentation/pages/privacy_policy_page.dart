import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/login');
        }
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gizlilik Politikası',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MusicShare Gizlilik Politikası',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Son güncelleme: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Privacy Content
            _buildSection(
              context,
              '1. Giriş',
              'Bu gizlilik politikası, MusicShare uygulamasını kullanırken kişisel verilerinizin nasıl toplandiğını, kullanıldığını ve korunduğunu açıklar. Verilerinizin güvenliği bizim için önemlidir.',
            ),
            
            _buildSection(
              context,
              '2. Toplanan Veriler',
              '• Hesap bilgileri (e-posta, kullanıcı adı, ad)\n• Müzik tercihleri ve puanları\n• Spotify entegrasyonu verileri\n• Cihaz bilgileri (platform, versiyon)\n• Kullanım istatistikleri\n• Yorumlar ve listeler',
            ),
            
            _buildSection(
              context,
              '3. Veri Kullanımı',
              'Verileriniz şu amaçlarla kullanılır:\n• Hesap yönetimi ve kimlik doğrulama\n• Kişiselleştirilmiş müzik önerileri\n• Platform geliştirme ve analiz\n• Müzik puanlama ve yorum sistemi\n• Sosyal özellikler (takip, paylaşım)',
            ),
            
            _buildSection(
              context,
              '4. Spotify Entegrasyonu',
              'Spotify hesabınızla bağlantı kurduğunuzda:\n• Dinleme geçmişinize erişim\n• Kayıtlı müziklerinize erişim\n• Çalma listelerinize erişim\n• Takip ettiğiniz sanatçılara erişim\nBu veriler sadece kişiselleştirme için kullanılır.',
            ),
            
            _buildSection(
              context,
              '5. Veri Paylaşımı',
              'Kişisel verileriniz:\n• Üçüncü taraflarla paylaşılmaz\n• Sadece yasal zorunluluk durumunda açıklanır\n• Anonimleştirilmiş istatistikler için kullanılabilir\n• İş ortaklarıyla sadece gerekli durumlarda paylaşılır',
            ),
            
            _buildSection(
              context,
              '6. Veri Güvenliği',
              'Verilerinizi korumak için:\n• Şifreleme teknolojileri kullanılır\n• Güvenli sunucular kullanılır\n• Düzenli güvenlik güncellemeleri yapılır\n• Erişim kontrolleri uygulanır\n• Backup ve kurtarma sistemleri mevcuttur',
            ),
            
            _buildSection(
              context,
              '7. Çerezler ve Takip',
              'Uygulama şu teknolojileri kullanır:\n• Yerel depolama (ayarlar, tercihler)\n• Analitik çerezler (kullanım istatistikleri)\n• Performans çerezleri (hız optimizasyonu)\n• Fonksiyonel çerezler (özellik kullanımı)',
            ),
            
            _buildSection(
              context,
              '8. Kullanıcı Hakları',
              'Haklarınız:\n• Verilerinize erişim\n• Verilerinizi düzeltme\n• Verilerinizi silme\n• Veri işlemeyi kısıtlama\n• Veri taşınabilirliği\n• İtiraz etme hakkı',
            ),
            
            _buildSection(
              context,
              '9. Veri Saklama',
              'Verileriniz:\n• Hesap aktif olduğu sürece saklanır\n• Hesap silindiğinde 30 gün sonra tamamen silinir\n• Yasal yükümlülükler için gerekli süre saklanır\n• Anonimleştirilmiş veriler analiz için saklanabilir',
            ),
            
            _buildSection(
              context,
              '10. Çocuk Gizliliği',
              '13 yaş altındaki çocukların verilerini bilerek toplamayız. Bu durumu tespit ettiğimizde ilgili verileri derhal sileriz.',
            ),
            
            _buildSection(
              context,
              '11. Politika Değişiklikleri',
              'Bu politika değiştirilebilir. Önemli değişiklikler kullanıcılara bildirilir. Değişiklikler yürürlüğe girdiği tarihten itibaren geçerlidir.',
            ),
            
            _buildSection(
              context,
              '12. İletişim',
              'Gizlilik ile ilgili sorularınız için:\n• E-posta: privacy@musicshare.com\n• Adres: MusicShare Teknoloji A.Ş.\n• İstanbul, Türkiye\n• Telefon: +90 (212) XXX XX XX',
            ),
            
            const SizedBox(height: 32),
            
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.security_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Verilerinizin güvenliği bizim önceliğimizdir. Sorularınız için bizimle iletişime geçebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

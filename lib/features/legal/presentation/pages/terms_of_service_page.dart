import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          'Kullanım Şartları',
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
                    Icons.description_outlined,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MusicShare Kullanım Şartları',
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

            // Terms Content
            _buildSection(
              context,
              '1. Hizmet Tanımı',
              'MusicShare, kullanıcıların müzik parçalarını puanlayabileceği, yorumlayabileceği ve listeler oluşturabileceği bir sosyal müzik platformudur. Platform, Spotify entegrasyonu ile müzik dinleme deneyimini geliştirir.',
            ),
            
            _buildSection(
              context,
              '2. Kullanıcı Sorumlulukları',
              '• Gerçek ve güncel bilgiler sağlamak\n• Telif hakkı ihlali yapmamak\n• Diğer kullanıcılara saygılı davranmak\n• Spam veya zararlı içerik paylaşmamak\n• Hesap güvenliğini sağlamak',
            ),
            
            _buildSection(
              context,
              '3. İçerik Politikası',
              'Kullanıcılar, paylaştıkları içeriklerden sorumludur. Platform, uygunsuz içerikleri kaldırma hakkını saklı tutar. Müzik puanları ve yorumlar objektif olmalıdır.',
            ),
            
            _buildSection(
              context,
              '4. Gizlilik ve Veri Kullanımı',
              'Kişisel verileriniz gizlilik politikamız kapsamında korunur. Spotify entegrasyonu için gerekli izinler alınır. Verileriniz üçüncü taraflarla paylaşılmaz.',
            ),
            
            _buildSection(
              context,
              '5. Hesap Güvenliği',
              'Hesabınızın güvenliğinden sorumlusunuz. Şifrenizi güçlü tutun ve başkalarıyla paylaşmayın. Şüpheli aktiviteleri derhal bildirin.',
            ),
            
            _buildSection(
              context,
              '6. Hizmet Değişiklikleri',
              'Platform, hizmetleri önceden haber vererek değiştirme hakkını saklı tutar. Önemli değişiklikler kullanıcılara bildirilir.',
            ),
            
            _buildSection(
              context,
              '7. Sorumluluk Reddi',
              'Platform, kullanıcıların deneyimlerinden sorumlu değildir. Müzik içerikleri üçüncü taraflarca sağlanır.',
            ),
            
            _buildSection(
              context,
              '8. İletişim',
              'Sorularınız için: support@musicshare.com\nAdres: MusicShare Teknoloji A.Ş.\nİstanbul, Türkiye',
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
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bu şartları kabul ederek MusicShare hizmetlerini kullanmaya başlayabilirsiniz.',
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

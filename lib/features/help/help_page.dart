import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  int _expandedIndex = -1;

  final List<FAQItem> faqs = [
    FAQItem(
      question: 'Spotify hesabımı nasıl bağlarım?',
      answer:
          'Ayarlar > Spotify Bağlantısı seçeneğine gidip Spotify hesabınızla giriş yapabilirsiniz.',
    ),
    FAQItem(
      question: 'Müzik nasıl puanlarım?',
      answer:
          'Arama yapıp istediğiniz şarkıyı seçip, Puanla butonuna tıklayıp 1-5 yıldız arasında puan verebilirsiniz.',
    ),
    FAQItem(
      question: 'Profilimi özel yapabilir miyim?',
      answer:
          'Evet, Ayarlar > Profil seçeneğinde "Özel Profil" seçeneğini açabilirsiniz.',
    ),
    FAQItem(
      question: 'Başka kullanıcıları nasıl bulabilirim?',
      answer: 'Arama sekmesinde kullanıcı adını yazarak başka müzik sevgileri bulabilirsiniz.',
    ),
    FAQItem(
      question: 'Verilerim güvenli midir?',
      answer:
          'Evet, tüm verileriniz Firebase tarafından şifrelenerek depolanmaktadır ve güvenlidir.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Yardım & SSS'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Contact section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bize Ulaş',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactButton(
                    icon: Icons.email,
                    label: 'E-posta Gönder',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildContactButton(
                    icon: Icons.bug_report,
                    label: 'Hata Bildir',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildContactButton(
                    icon: Icons.lightbulb,
                    label: 'Özellik Öner',
                    onTap: () {},
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            // FAQ section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sık Sorulan Sorular',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      return _buildFAQItem(index, isDark);
                    },
                  ),
                ],
              ),
            ),
            // Footer links
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daha Fazla',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLinkButton('Gizlilik Politikası', isDark),
                  const SizedBox(height: 8),
                  _buildLinkButton('Hizmet Şartları', isDark),
                  const SizedBox(height: 8),
                  _buildLinkButton('Hakkında', isDark),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Tuniverse v1.0.0',
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 12,
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

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildFAQItem(int index, bool isDark) {
    final item = faqs[index];
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? AppTheme.primaryColor
              : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? -1 : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.question,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(
                item.answer,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(String label, bool isDark) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

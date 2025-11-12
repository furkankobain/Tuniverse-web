import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help & FAQ Page
/// Complete help center with FAQs, support, and bug reporting
class HelpAndFAQPage extends StatefulWidget {
  const HelpAndFAQPage({super.key});

  @override
  State<HelpAndFAQPage> createState() => _HelpAndFAQPageState();
}

class _HelpAndFAQPageState extends State<HelpAndFAQPage> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredFAQs = _selectedCategory == 'all'
        ? _faqs
        : _faqs.where((faq) => faq.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım & SSS'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Actions
          _buildQuickActions(context),

          const SizedBox(height: 24),

          // Category Filter
          _buildCategoryFilter(),

          const SizedBox(height: 16),

          // FAQ List
          ...filteredFAQs.map((faq) => _buildFAQItem(faq, theme)),

          const SizedBox(height: 32),

          // Still Need Help Section
          _buildStillNeedHelp(context, theme),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı İşlemler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.bug_report,
                    label: 'Hata Bildir',
                    color: Colors.red,
                    onTap: () => _showBugReportDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.email,
                    label: 'İletişim',
                    color: Colors.blue,
                    onTap: () => _contactSupport(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.policy,
                    label: 'Gizlilik',
                    color: Colors.green,
                    onTap: () => _openPrivacyPolicy(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.description,
                    label: 'Şartlar',
                    color: Colors.orange,
                    onTap: () => _openTerms(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'name': 'Tümü', 'icon': Icons.all_inclusive},
      {'id': 'account', 'name': 'Hesap', 'icon': Icons.person},
      {'id': 'music', 'name': 'Müzik', 'icon': Icons.music_note},
      {'id': 'playlist', 'name': 'Playlist', 'icon': Icons.queue_music},
      {'id': 'social', 'name': 'Sosyal', 'icon': Icons.people},
      {'id': 'technical', 'name': 'Teknik', 'icon': Icons.settings},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : null,
                  ),
                  const SizedBox(width: 4),
                  Text(cat['name'] as String),
                ],
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat['id'] as String;
                });
              },
              selectedColor: const Color(0xFFFF5E5E),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF5E5E).withOpacity(0.1),
          child: Icon(
            faq.icon,
            color: const Color(0xFFFF5E5E),
            size: 20,
          ),
        ),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStillNeedHelp(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5E5E), Color(0xFFFF8E3C)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.help_outline,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Hala Yardıma İhtiyacınız Var mı?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Destek ekibimiz size yardımcı olmaktan mutluluk duyar!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _contactSupport(),
            icon: const Icon(Icons.email),
            label: const Text('Destek Ekibiyle İletişime Geç'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF5E5E),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata Bildir'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Kısa bir başlık girin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Hatayı detaylı açıklayın',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Send bug report to server
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hata raporu gönderildi. Teşekkürler!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@tuniverse.app',
      query: 'subject=Tuniverse Destek Talebi',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    // TODO: Open privacy policy URL
    final Uri url = Uri.parse('https://tuniverse.app/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTerms() async {
    // TODO: Open terms of service URL
    final Uri url = Uri.parse('https://tuniverse.app/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // FAQ Data
  final List<FAQItem> _faqs = [
    FAQItem(
      category: 'account',
      icon: Icons.login,
      question: 'Nasıl hesap oluştururum?',
      answer: 'Ana ekranda "Kayıt Ol" butonuna tıklayın. Email ve şifre ile kayıt olabilir veya Google hesabınızla giriş yapabilirsiniz.',
    ),
    FAQItem(
      category: 'account',
      icon: Icons.lock_reset,
      question: 'Şifremi unuttum, ne yapmalıyım?',
      answer: 'Giriş ekranında "Şifremi Unuttum" linkine tıklayın. Email adresinize şifre sıfırlama linki gönderilecektir.',
    ),
    FAQItem(
      category: 'music',
      icon: Icons.music_note,
      question: 'Spotify hesabımı nasıl bağlarım?',
      answer: 'Ayarlar > Spotify Bağlantısı menüsünden Spotify hesabınıza giriş yapabilirsiniz. Bu sayede playlistlerinizi içe aktarabilirsiniz.',
    ),
    FAQItem(
      category: 'playlist',
      icon: Icons.queue_music,
      question: 'Playlist nasıl oluştururum?',
      answer: 'Playlists sekmesinde "+" butonuna tıklayın. Playlist adı, açıklama ekleyin ve şarkı eklemeye başlayın.',
    ),
    FAQItem(
      category: 'playlist',
      icon: Icons.qr_code,
      question: 'QR kod ile playlist nasıl paylaşırım?',
      answer: 'Playlist detay sayfasında "Paylaş" butonuna tıklayın ve "QR Kod" seçeneğini seçin. QR kod otomatik oluşturulacaktır.',
    ),
    FAQItem(
      category: 'social',
      icon: Icons.people,
      question: 'Arkadaşlarımı nasıl bulabilirim?',
      answer: 'Arama sekmesinde "Kullanıcılar" kategorisinden username veya email ile arama yapabilirsiniz.',
    ),
    FAQItem(
      category: 'social',
      icon: Icons.notifications,
      question: 'Bildirimleri nasıl yönetirim?',
      answer: 'Ayarlar > Bildirimler menüsünden hangi bildirimleri almak istediğinizi seçebilirsiniz.',
    ),
    FAQItem(
      category: 'technical',
      icon: Icons.cloud_off,
      question: 'Çevrimdışı mod nasıl çalışır?',
      answer: 'İndirdiğiniz şarkılar ve playlistler çevrimdışıyken de dinlenebilir. Ayarlar > Çevrimdışı menüsünden yönetebilirsiniz.',
    ),
    FAQItem(
      category: 'technical',
      icon: Icons.storage,
      question: 'Uygulama çok yer kaplıyor, ne yapmalıyım?',
      answer: 'Ayarlar > Depolama Yönetimi menüsünden önbellek ve indirilen dosyaları temizleyebilirsiniz.',
    ),
    FAQItem(
      category: 'music',
      icon: Icons.star,
      question: 'Şarkıları nasıl puanlarım?',
      answer: 'Şarkı detay sayfasında yıldız ikonlarına tıklayarak 1-5 arası puan verebilirsiniz.',
    ),
  ];
}

class FAQItem {
  final String category;
  final IconData icon;
  final String question;
  final String answer;

  FAQItem({
    required this.category,
    required this.icon,
    required this.question,
    required this.answer,
  });
}

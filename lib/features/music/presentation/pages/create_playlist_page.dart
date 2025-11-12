import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';

class CreatePlaylistPage extends ConsumerStatefulWidget {
  const CreatePlaylistPage({super.key});

  @override
  ConsumerState<CreatePlaylistPage> createState() => _CreatePlaylistPageState();
}

class _CreatePlaylistPageState extends ConsumerState<CreatePlaylistPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Yeni Çalma Listesi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _savePlaylist,
              child: Text(
                'Kaydet',
                style: TextStyle(
                  color: ModernDesignSystem.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? ModernDesignSystem.darkGradient
              : LinearGradient(
                  colors: [
                    ModernDesignSystem.lightBackground,
                    ModernDesignSystem.accentPurple.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image Placeholder
                _buildCoverImageSection(isDark),
                
                const SizedBox(height: 24),
                
                // Playlist Name
                _buildNameField(isDark),
                
                const SizedBox(height: 16),
                
                // Description
                _buildDescriptionField(isDark),
                
                const SizedBox(height: 16),
                
                // Privacy Toggle
                _buildPrivacyToggle(isDark),
                
                const SizedBox(height: 24),
                
                // Info Card
                _buildInfoCard(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection(bool isDark) {
    return Center(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          gradient: ModernDesignSystem.purpleGradient,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
          boxShadow: ModernDesignSystem.getGlowEffect(
            ModernDesignSystem.accentPurple,
            intensity: 0.3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_note_rounded,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              'Kapak Resmi',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(bool isDark) {
    return Container(
      decoration: isDark 
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
              boxShadow: ModernDesignSystem.mediumShadow,
            ),
      child: TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Çalma Listesi Adı',
          hintText: 'Favori Şarkılarım',
          prefixIcon: const Icon(Icons.title_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Lütfen bir isim girin';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark) {
    return Container(
      decoration: isDark 
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
              boxShadow: ModernDesignSystem.mediumShadow,
            ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Açıklama (Opsiyonel)',
          hintText: 'Bu çalma listesi hakkında...',
          prefixIcon: const Icon(Icons.description_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(20),
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isDark 
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
              boxShadow: ModernDesignSystem.mediumShadow,
            ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ModernDesignSystem.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isPublic ? Icons.public_rounded : Icons.lock_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Genel Çalma Listesi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPublic 
                      ? 'Herkes görebilir'
                      : 'Sadece sen görebilirsin',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.6)
                        : ModernDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              setState(() => _isPublic = value);
            },
            activeColor: ModernDesignSystem.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModernDesignSystem.accentBlue.withValues(alpha: 0.1),
            ModernDesignSystem.accentTeal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
        border: Border.all(
          color: ModernDesignSystem.accentBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: ModernDesignSystem.accentBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Çalma listesi oluşturduktan sonra şarkı ekleyebilirsiniz',
              style: TextStyle(
                fontSize: 13,
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.8)
                    : ModernDesignSystem.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} oluşturuldu!'),
            backgroundColor: ModernDesignSystem.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bir hata oluştu'),
            backgroundColor: ModernDesignSystem.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

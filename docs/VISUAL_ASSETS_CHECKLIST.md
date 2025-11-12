# 🎨 Görsel Varlıklar Kontrol Listesi

> **📍 Dosya Konumu:** `C:\Users\Furkan\tuniverse\docs\VISUAL_ASSETS_CHECKLIST.md`
> 
> **🎯 Amaç:** Tuniverse uygulamasının tüm görsel tasarım gereksinimlerini takip etmek
>
> **📅 Son Güncelleme:** 10 Kasım 2025

---

## 📂 Nasıl Kullanılır?

1. **Dosyayı Açmak İçin:**
   - VS Code'da: `Ctrl+P` → `VISUAL_ASSETS_CHECKLIST.md` yazın
   - Veya: `C:\Users\Furkan\tuniverse\docs\` klasörüne gidin

2. **Kontrol Listesini Güncellemek:**
   - `[ ]` işareti: Yapılmadı
   - `[x]` işareti: Tamamlandı
   - Git commit'lerinde bu dosyayı güncelleyin

3. **Varlık Dosyalarını Eklemek:**
   - Görseller: `assets/images/quiz/` klasörüne
   - Animasyonlar: `assets/animations/quiz/` klasörüne
   - İkonlar: Emoji kullan veya `assets/icons/quiz/` klasörüne

---

## 🎮 Music Quiz Sistemi - Tasarım Gereksinimleri

### 1. 🏠 Quiz Ana Sayfa (`quiz_main_page.dart`)

**📍 Dosya Yolu:** `lib/features/quiz/presentation/pages/quiz_main_page.dart`

**Mevcut Sorunlar:**
- ❌ Sade gradient header
- ❌ Basit kartlar
- ❌ Animasyon yok
- ❌ Sıkıcı görünüm

**Yapılacaklar:**
- [ ] **Mor gradient arka plan** (#6B46C1 → #2D1B69)
- [ ] **Başlık:** "♪ Music Quiz ♪" (sarı renk, büyük font)
- [ ] **Toplam oyun sayacı:** "▷ 855,629 plays" (küçük, beyaz)
- [ ] **Animasyonlu müzik notaları** (yüzen parçacıklar)
- [ ] **Modern oyun modu kartları:**
  - Dark navy arka plan (#1E293B)
  - İkon + başlık
  - Hover efekti (scale 1.05)
  - Gölge efekti
- [ ] **Pro rozeti animasyonu**
- [ ] **"Select Mode" alt başlığı** (sarı, orta boy)

**Referans Renkler:**
```dart
// Arka plan gradient
LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF6B46C1), Color(0xFF2D1B69)],
)

// Kart rengi
Color(0xFF1E293B)

// Sarı vurgu
Color(0xFFFFD700)
```

---

### 2. 🎵 Şarkıyı Tahmin Et - Kurulum (`guess_song_setup_page.dart`)

**📍 Dosya Yolu:** `lib/features/quiz/presentation/pages/guess_song_setup_page.dart`

**Mevcut Sorunlar:**
- ❌ Sade text input'lar
- ❌ Listeleme şeklinde talimatlar
- ❌ Sıkıcı kırmızı kutu

**Yapılacaklar:**
- [ ] **Mor gradient arka plan** (quiz_main_page ile aynı)
- [ ] **Üst tab:** "🎵 Guess the Song" (sarı, navy kart içinde)
- [ ] **Açıklama:** "Listen for 5 seconds and guess the song" (beyaz, küçük)
- [ ] **"Search Artists" başlığı** (sarı)
- [ ] **Arama kutusu:**
  - Dark navy (#1E293B)
  - Arama ikonu solda
  - Placeholder: "manif", "blok3", vb.
  - Autocomplete dropdown (artist avatarları ile)
- [ ] **Popüler sanatçılar carousel:**
  - "This Week's Popular Artists" başlığı (sarı)
  - Yuvarlak avatar'lar (6-10 kişi)
  - İsimler avatar altında
  - Yatay scroll
- [ ] **PLAY butonu:**
  - Gri/beyaz arka plan
  - Büyük, kalın
  - Tam genişlik
- [ ] **PLAY ON STREAM butonu:**
  - Yeşil→Kırmızı gradient (#00FF00 → #FF0000)
  - Kickstarter + Twitch + YouTube ikonları
  - Tam genişlik

**Gerekli Varlıklar:**
- Spotify API'den artist avatar'ları (runtime'da çekilecek)
- Platform ikonları: `assets/icons/kickstarter.png`, `twitch.png`, `youtube.png`

---

### 3. 🎤 Sanatçıyı Tahmin Et - Kurulum (`guess_artist_setup_page.dart`)

**📍 Dosya Yolu:** `lib/features/quiz/presentation/pages/guess_artist_setup_page.dart`

**Mevcut Sorunlar:**
- ❌ Sıkıcı genre chip'leri
- ❌ Görsel hiyerarşi yok
- ❌ Düz renkler

**Yapılacaklar:**
- [ ] **Mor gradient arka plan**
- [ ] **Üst tab:** "🎤 Guess the Artist" (sarı, navy kart)
- [ ] **Açıklama:** "Listen for 5 seconds and guess the artist"
- [ ] **"Select Genres" başlığı** (sarı)
- [ ] **Genre chip'leri:**
  - 🌍 **Pop** (mor border, beyaz text)
  - 🇹🇷 **Türkçe Pop** (mor border, "TR" bayrağı)
  - 🎸 **Rock**
  - 🇹🇷 **Türkçe Rock**
  - 🎤 **Hip-Hop**
  - 🇹🇷 **Türkçe Rap**
  - 🤘 **Metal**
  - 🇮🇹 **Pop Italiano**
  - 🇰🇷 **K-Pop**
  - **MORE** butonu (yarı transparan)
- [ ] **Seçili chip animasyonu:** Dolu mor arka plan
- [ ] **PLAY butonu:** Kırmızı gradient (#FF4444 → #CC0000)

**İkon Listesi:**
```dart
// Emoji olarak kullan
'🌍' // Global
'🇹🇷' // Türkiye
'🎸' // Rock
'🎤' // Hip-Hop/Rap
'🤘' // Metal
'🇮🇹' // İtalya
'🇰🇷' // K-Pop
```

---

### 4. 🎮 Quiz Oyun Sayfası (`quiz_game_page.dart`)

**📍 Dosya Yolu:** `lib/features/quiz/presentation/pages/quiz_game_page.dart`

**Mevcut Sorunlar:**
- ❌ Basit audio player kartı
- ❌ Düz butonlar
- ❌ Enerji yok
- ❌ Görsel feedback eksik

**Yapılacaklar:**
- [ ] **Üst göstergeler:**
  - Soru numarası dot'ları (1-10)
  - 1. soru sarı, diğerleri gri
  - Cevaplanan yeşil, yanlış kırmızı
- [ ] **Timer widget:**
  - Ortada büyük ▶️ play butonu (sarı)
  - Sol: 0:05.0 (geçen süre)
  - Sağ: 00:05 (kalan süre)
  - Volume ikonu + seviye (28%)
- [ ] **Albüm cover'ları:**
  - 3 tane yan yana
  - Glow/border efekti
  - Seçildiğinde sarı border
  - Şarkı adı altında (sarı buton)
- [ ] **Doğru cevap animasyonu:**
  - Yeşil glow
  - Confetti patlaması
  - Ses efekti (opsiyonel)
- [ ] **Yanlış cevap animasyonu:**
  - Kırmızı glow + sallama
  - Doğru cevabı göster (yeşil)
- [ ] **Artist mod için:**
  - Artist fotoğrafları (yuvarlak)
  - Artist isimleri altında

**Gerekli Varlıklar:**
- `assets/animations/quiz/correct_answer.json` (Lottie)
- `assets/animations/quiz/wrong_answer.json` (Lottie)
- Confetti package zaten var ✅

---

### 5. 🏆 Quiz Sonuç Sayfası (`quiz_result_page.dart`)

**📍 Dosya Yolu:** `lib/features/quiz/presentation/pages/quiz_result_page.dart`

**Mevcut Sorunlar:**
- ❌ Basit kupa ikonu
- ❌ Sade skor gösterimi
- ❌ Kutlama hissi yok

**Yapılacaklar:**
- [ ] **Animasyonlu kupa:**
  - Altın (10/10), Gümüş (7-9), Bronz (4-6)
  - Glow efekti
  - Dönen animasyon
- [ ] **Confetti patlaması:** (7+ doğru için)
- [ ] **Skor sayacı animasyonu:**
  - 0'dan hedef skora sayma
  - Büyük, kalın font
  - Sarı renk
- [ ] **Performans mesajı:**
  - "Perfect! 🎉" (10/10)
  - "Excellent! 🌟" (8-9)
  - "Great Job! 👏" (6-7)
  - "Good Try! 👍" (4-5)
  - "Keep Practicing! 💪" (0-3)
- [ ] **İstatistik kartları:**
  - Doğru cevaplar: X/10
  - Doğruluk oranı: %XX
  - Glassmorphism efekti
- [ ] **Rank rozeti:**
  - Top 10: Altın taç 👑
  - Top 50: Gümüş madalya 🥈
  - Top 100: Bronz madalya 🥉
- [ ] **Paylaş butonu:**
  - Sosyal medya ikonları
  - Özel tasarım kartı oluştur
- [ ] **Leaderboard önizlemesi:**
  - Top 3'ü göster
  - "View Full Leaderboard" butonu

**Gerekli Varlıklar:**
- `assets/images/quiz/trophy_gold.png`
- `assets/images/quiz/trophy_silver.png`
- `assets/images/quiz/trophy_bronze.png`
- `assets/animations/quiz/trophy_animation.json`

---

### 6. 🥇 Liderlik Tablosu (`leaderboard_page.dart`)

**📍 Dosya Yolu:** `lib/features/quiz/presentation/pages/leaderboard_page.dart`

**Mevcut Sorunlar:**
- ❌ Basit liste görünümü
- ❌ Top 3 için podium yok
- ❌ Sade profil fotoğrafları
- ❌ Sıralama göstergesi eksik

**Yapılacaklar:**
- [ ] **Podium widget (Top 3):**
  - 2. sıra: Sol, orta boy
  - 1. sıra: Orta, en büyük, taç 👑
  - 3. sıra: Sağ, küçük
  - Altın, gümüş, bronz renkler
- [ ] **Profil frame'leri:**
  - Pro kullanıcılar: Altın frame
  - Normal kullanıcılar: Gri frame
  - Animasyonlu gradient (Pro)
- [ ] **Sıralama rozetleri:**
  - 1-3: Madalya ikonu
  - 4-10: Altın renk
  - 11-50: Gümüş renk
  - 51+: Normal renk
- [ ] **Mevcut kullanıcı vurgusu:**
  - Sarı glow efekti
  - Daha kalın border
  - Otomatik scroll
- [ ] **Pull-to-refresh animasyonu**
- [ ] **Shimmer loading efekti:**
  - Liste yüklenirken
  - Gradient animasyonu
- [ ] **Süre toggle'ı:**
  - "Monthly" / "All Time"
  - Animasyonlu geçiş
  - Sarı seçili tab

**Gerekli Varlıklar:**
- `assets/images/quiz/medal_gold.png`
- `assets/images/quiz/medal_silver.png`
- `assets/images/quiz/medal_bronze.png`
- `assets/images/quiz/crown.png`
- `assets/images/quiz/podium.png`

---

## 🎨 Tasarım Sistemi

### Renk Paleti

```dart
// Ana renkler
const primaryPurple = Color(0xFF6B46C1);
const darkPurple = Color(0xFF2D1B69);
const primaryGold = Color(0xFFFFD700);
const lightGold = Color(0xFFFFE55C);

// Kartlar & Arka planlar
const navyCard = Color(0xFF1E293B);
const darkCard = Color(0xFF0F172A);

// Gradient'ler
final purpleGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF6B46C1), Color(0xFF2D1B69)],
);

final goldGradient = LinearGradient(
  colors: [Color(0xFFFFD700), Color(0xFFFFE55C)],
);

final greenRedGradient = LinearGradient(
  colors: [Color(0xFF00FF00), Color(0xFFFF0000)],
);

// Dark mode
const darkBg = Color(0xFF1a1a2e);
const darkCardBg = Color(0xFF16213e);
```

### Tipografi

```dart
// Başlıklar
TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: Color(0xFFFFD700),
  letterSpacing: 1.2,
)

// Alt başlıklar
TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  color: Colors.white,
)

// Gövde metni
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: Colors.white70,
)

// Küçük metin
TextStyle(
  fontSize: 14,
  color: Colors.white60,
)
```

### Animasyonlar

```dart
// Micro-interaction
Duration(milliseconds: 200)

// Sayfa geçişleri
Duration(milliseconds: 400)

// Kutlamalar
Duration(milliseconds: 1000)

// Sonsuz animasyonlar
Duration(seconds: 3) // repeat
```

---

## 📦 Gerekli Asset Dosyaları

### 📁 Görseller (`assets/images/quiz/`)

```
assets/
└── images/
    └── quiz/
        ├── trophy_gold.png          # Altın kupa
        ├── trophy_silver.png        # Gümüş kupa
        ├── trophy_bronze.png        # Bronz kupa
        ├── medal_gold.png           # Altın madalya
        ├── medal_silver.png         # Gümüş madalya
        ├── medal_bronze.png         # Bronz madalya
        ├── crown.png                # Taç (1. sıra)
        ├── podium.png               # Podium grafiği
        ├── vinyl_record.png         # Dönen plak
        └── music_notes.png          # Müzik notaları sprite
```

**Nereden bulunur?**
- Ücretsiz: [Flaticon](https://www.flaticon.com), [Freepik](https://www.freepik.com)
- Premium: [IconScout](https://iconscout.com), [Icons8](https://icons8.com)
- Kendin çiz: Figma, Adobe Illustrator

### 🎬 Animasyonlar (`assets/animations/quiz/`)

```
assets/
└── animations/
    └── quiz/
        ├── music_loading.json       # Loading animasyonu
        ├── confetti.json            # Kutlama
        ├── correct_answer.json      # Doğru cevap
        ├── wrong_answer.json        # Yanlış cevap
        ├── trophy_animation.json    # Kupa animasyonu
        └── vinyl_spin.json          # Dönen plak
```

**Nereden bulunur?**
- [LottieFiles](https://lottiefiles.com) - Ücretsiz JSON animasyonlar
- Arama terimleri: "music quiz", "trophy", "confetti", "vinyl record"

### 🎯 İkonlar

Emoji kullan (kod içinde):
```dart
'♪'  // Müzik notu
'▷'  // Play
'🏆' // Kupa
'👑' // Taç
'⭐' // Yıldız
'✨' // Parıltı
'🌍' // Dünya
'🇹🇷' // Türk bayrağı
'🎸' // Gitar
'🎤' // Mikrofon
```

---

## 📋 pubspec.yaml Güncellemeleri

Gerekli paketler zaten ekli:
- ✅ `just_audio: ^0.9.46` - Audio player
- ✅ `confetti: ^0.7.0` - Kutlama animasyonu
- ✅ `lottie: ^3.1.0` - JSON animasyonlar

Eksik paketler (gerekirse):
```yaml
dependencies:
  shimmer: ^3.0.0  # Loading efekti
  flutter_animate: ^4.5.0  # Kolay animasyonlar
```

Asset klasörlerini ekle:
```yaml
flutter:
  assets:
    - assets/images/quiz/
    - assets/animations/quiz/
    - assets/icons/quiz/
```

---

## 🚀 Öncelik Sırası

### 🔴 YÜKSEK ÖNCELİK (Çekirdek UX)
1. [ ] Quiz Oyun Sayfası redesign
2. [ ] Sonuç Sayfası animasyonlar
3. [ ] Ana Sayfa mor gradient
4. [ ] Loading state'leri

### 🟡 ORTA ÖNCELİK (Görsel Cilalanma)
5. [ ] Kurulum sayfaları iyileştirme
6. [ ] Liderlik tablosu podium
7. [ ] Artist search autocomplete
8. [ ] Genre selection animasyonlar

### 🟢 DÜŞÜK ÖNCELİK (Nice-to-have)
9. [ ] İleri seviye animasyonlar
10. [ ] Ses efektleri
11. [ ] Haptic feedback
12. [ ] Sosyal paylaşım kartları

---

## ✅ Tamamlanma Kontrolü

### Quiz Ana Sayfa
- [ ] Mor gradient arka plan
- [ ] Toplam oyun sayacı
- [ ] Modern kart tasarımı
- [ ] Animasyonlu elementler

### Kurulum Sayfaları
- [ ] Artist search + autocomplete
- [ ] Popüler sanatçılar carousel
- [ ] Genre chip'leri + ikonlar
- [ ] Gradient butonlar

### Oyun Sayfası
- [ ] Soru göstergeleri (dots)
- [ ] Timer + play butonu
- [ ] Album cover glow'ları
- [ ] Cevap animasyonları

### Sonuç Sayfası
- [ ] Animasyonlu kupa
- [ ] Confetti efekti
- [ ] Skor sayacı
- [ ] Rank rozetleri

### Liderlik Tablosu
- [ ] Top 3 podium
- [ ] Madalya ikonları
- [ ] Pro frame'ler
- [ ] Kullanıcı vurgusu

---

## 📝 Notlar

- **Performans:** Tüm animasyonlar 60fps hedefinde
- **Accessibility:** Minimum font 14px, dokunma alanları 44x44px
- **Responsive:** Mobile-first, tablet için optimize edilecek
- **Dark mode:** Tüm renkler dark mode'da test edilecek
- **Testing:** Her sayfa emulator'de görsel test yapılacak

---

## 🔗 Faydalı Linkler

- [Material Design](https://material.io/design)
- [Flutter Animation Guide](https://docs.flutter.dev/ui/animations)
- [LottieFiles](https://lottiefiles.com)
- [Flaticon](https://www.flaticon.com)
- [Color Hunt](https://colorhunt.co) - Renk paletleri

---

## 📅 İlerleme Takibi

**Başlangıç:** 10 Kasım 2025
**Hedef Tamamlanma:** TBD
**Mevcut Durum:** 🟡 Geliştirme Aşamasında

**Tamamlanma Yüzdesi:** 15%
- ✅ Quiz çalışıyor (fonksiyonel)
- ✅ Firestore rules hazır
- ⏳ Tasarımlar yapılıyor
- ⏳ Asset'ler toplanıyor

---

**Son Güncelleme:** 10 Kasım 2025, 11:17
**Güncelleyen:** AI Assistant
**Durum:** 📝 Aktif Geliştirme

# 🎵 Tuniverse - Müzik Evreni Uygulaması

Letterboxd'den ilham alan, müzik severler için modern bir müzik keşif ve paylaşım uygulaması. Tuniverse ile müzik dünyanızı keşfedin! Flutter ve Firebase ile geliştirildi.

## ✨ Özellikler

### 🎵 Müzik Özellikleri
- **Müzik Değerlendirme Sistemi** - Favori şarkılarını puanla ve yorumla
- **Gelişmiş Arama** - Sanatçı, albüm, şarkı ve kullanıcı bazında ara
- **Spotify Entegrasyonu** - Spotify hesabınla bağlan ve playlistlerini içe aktar
- **Discovery & Recommendations** - Spotify API ve Last.fm ile kişiselleştirilmiş öneriler
- **Playlist Yönetimi** - Kendi playlistlerini oluştur ve yönet
- **Akıllı Playlistler** - Ruh hali, tür, dönem ve aktivite bazlı otomatik playlistler
- **Playlist Etiketleri** - Playlistlerini kategorize et ve organize et
- **Playlist Keşfi** - Diğer kullanıcıların public playlistlerini keşfet
- **QR Kod Paylaşımı** - Playlistleri QR kod ile kolayca paylaş
- **Müzik Paylaşımı** - Şarkı, albüm ve playlist paylaş

### 👥 Sosyal Özellikler
- **Kullanıcı Profilleri** - Detaylı profil sayfaları (incelemeler, listeler, favoriler, aktivite)
- **Takip Sistemi** - Diğer kullanıcıları takip et/takipten çık
- **Sosyal Feed** - Takip ettiğin kullanıcıların aktivitelerini gör
- **Kullanıcı Arama** - Username, email veya isim ile kullanıcı ara
- **Profil İstatistikleri** - Takipçi, takip, inceleme ve liste sayıları

### 💬 Mesajlaşma (DM) Özellikleri
- **Gerçek Zamanlı Mesajlaşma** - Anlık mesajlaşma desteği
- **Müzik Paylaşımı** - Mesajlarda şarkı, albüm ve playlist paylaş
- **Yazıyor Göstergesi** - Karşı tarafın yazdığını gör
- **Online/Offline Durumu** - Kullanıcıların çevrimiçi durumunu takip et
- **Mesaj İşlemleri** - Mesajları kopyala, sil, yanıtla
- **Okundu Bilgisi** - Mesajların okunup okunmadığını gör
- **Kullanıcı Arama** - Kolayca kullanıcı bul ve sohbet başlat

### 🎨 Genel Özellikler
- **Modern UI/UX** - Karanlık/Aydınlık mod desteğiyle güzel arayüz
- **Profil Sistemi** - Kullanıcı profilleri ve playlist sayaçları
- **Responsive Tasarım** - Tüm ekran boyutlarında mükemmel çalışır
- **Firebase Backend** - Güvenli ve hızlı veri yönetimi

## 🚀 Başlangıç

### Gereksinimler

- Flutter SDK (3.9.2 veya üzeri)
- Dart SDK (3.9.2 veya üzeri)
- Android Studio / VS Code
- Firebase hesabı (Firestore + Realtime Database)
- Spotify Developer hesabı (opsiyonel)
- Android için google-services.json paket adı: com.musicshare.app (mevcut applicationId)

### Kurulum

1. **Projeyi klonla:**
```bash
git clone https://github.com/furkankobain/tuniverse.git
cd tuniverse
```

2. **Bağımlılıkları yükle:**
```bash
flutter pub get
```

3. **Firebase Kurulumu:**
- `FIREBASE_SETUP.md` dosyasındaki adımları takip et
- Firestore ve Realtime Database'i aktif et
- Security rules'ları deploy et

4. **Uygulamayı çalıştır:**
```bash
flutter run
```

## 🔧 Geliştirme

### Yeni Eklenen Servisler (Nov 2, 2025)
- **queue_service.dart** - Çalma kuyruğu yönetimi (shuffle, repeat, reorder)
- **audio_effects_service.dart** - Crossfade & EQ (21 preset)
- **sleep_timer_service.dart** - Uyku zamanlayıcısı
- **social_interactions_service.dart** - Beğeni, yorum, paylaşım
- **personalized_discovery_service.dart** - Daily Mix & Release Radar
- **music_exploration_service.dart** - Decade & Genre keşfi

### Teknoloji Stack
- **Flutter** - Mobil uygulama framework'ü
- **Firebase Firestore** - NoSQL veritabanı
- **Firebase Realtime Database** - Online status takibi
- **Firebase Storage** - Resim ve medya depolama (Blaze Plan)
- **Firebase Auth** - Kullanıcı kimlik doğrulama
- **Riverpod** - State management
- **GoRouter** - Navigation
- **Spotify API** - Müzik verisi

### Mimari
- **Feature-based** klasör yapısı
- **Service Pattern** - Firebase servisleri için
- **Model-View** yapısı
- **Real-time listeners** - Firestore ve Realtime DB

### Kod Stili
- **Flutter Lints** kuralları uygulanıyor
- **Tutarlı isimlendirme** konvansiyonları
- **Kapsamlı dökümantasyon**

## 🎨 Görsel Gereksinimler & Tasarım

### 📱 Uygulama İkonları & Logo

#### Ana Logo (Öncelik: YÜKSEK)
- **Uygulama İkonu** (app_icon.png)
  - Boyutlar: 1024x1024px (yüksek çözünürlük)
  - Format: PNG (transparent background)
  - Stil: Modern, müzik temalı, Letterboxd esinli
  - Renkler: #FF5E5E (ana renk) + gradient efekti
  - Android adaptive icon için: 512x512px (foreground + background ayrı)
  - iOS için: 1024x1024px (rounded corners otomatik)

#### Splash Screen (Öncelik: YÜKSEK)
- **Açılış Ekranı Görseli** (splash_logo.png)
  - Boyut: 1080x1920px (9:16 aspect ratio)
  - Logo + "Tuniverse" yazısı
  - Animasyonlu versiyon için Lottie JSON (opsiyonel)

#### Onboarding Görselleri (Öncelik: ORTA)
- **4 adet onboarding illustration**
  1. `onboarding_1.png` - Müzik keşfi teması (800x600px)
  2. `onboarding_2.png` - Sosyal özellikler (800x600px)
  3. `onboarding_3.png` - Playlist yönetimi (800x600px)
  4. `onboarding_4.png` - Analytics & Stats (800x600px)
  - Stil: Flat design, tutarlı renk paleti
  - Format: PNG veya SVG

### 🎵 Müzik Özellikleri İkonları

#### Kategori İkonları (Öncelik: ORTA)
- **Genre Icons** (128x128px her biri)
  - `genre_rock.png` - Kaya/Gitar temalı
  - `genre_pop.png` - Yıldız/Mikrofon
  - `genre_hiphop.png` - Mikrofon/Şapka
  - `genre_electronic.png` - Dalga/Synthesizer
  - `genre_jazz.png` - Saksafon/Nota
  - `genre_classical.png` - Keman/Orkestra
  - `genre_metal.png` - Şimşek/Gitar
  - `genre_indie.png` - Kaset/Retro
  - `genre_country.png` - Kovboy şapkası/Gitar
  - `genre_rnb.png` - Kalp/Mikrofon

#### Mood/Activity İkonları (128x128px)
- `mood_energetic.png` - Enerji/Yıldırım
- `mood_chill.png` - Ay/Rahatlama
- `mood_happy.png` - Güneş/Gülümseme
- `mood_focus.png` - Hedef/Konsantrasyon
- `activity_workout.png` - Dumbbell/Koşu
- `activity_party.png` - Parti/Dans
- `activity_study.png` - Kitap/Kahve
- `activity_sleep.png` - Uyku/Bulut

### 🏆 Gamification Görselleri

#### Achievement Badges (Öncelik: YÜKSEK)
- **17 adet rozet görseli** (256x256px)
  - `badge_first_review.png` - İlk değerlendirme
  - `badge_social_butterfly.png` - 10 arkadaş takip
  - `badge_playlist_master.png` - 5 playlist oluşturma
  - `badge_early_bird.png` - Sabah dinleme
  - `badge_night_owl.png` - Gece dinleme
  - `badge_explorer.png` - 50 sanatçı keşfi
  - `badge_critic.png` - 50 değerlendirme
  - `badge_curator.png` - 10 public playlist
  - `badge_influencer.png` - 100 takipçi
  - `badge_generous.png` - 100 beğeni
  - `badge_collaborator.png` - İlk ortak playlist
  - `badge_collector.png` - 500 favori şarkı
  - `badge_completionist.png` - 1000 şarkı dinleme
  - `badge_veteran.png` - 1 yıl kullanım
  - `badge_legend.png` - Tüm achievement'lar
  - `badge_streak_7.png` - 7 günlük streak
  - `badge_streak_30.png` - 30 günlük streak
  - Stil: Renkli, gradient, parlak efektler
  - 3 tier: Bronze, Silver, Gold versiyonları

#### Leaderboard İkonları
- `trophy_gold.png` - 1. sıra (128x128px)
- `trophy_silver.png` - 2. sıra (128x128px)
- `trophy_bronze.png` - 3. sıra (128x128px)

### 📊 Analytics & Stats Görselleri

#### Visualizer İkonları (Öncelik: DÜŞÜK)
- `visualizer_bars.png` - Bar chart animasyon base
- `visualizer_wave.png` - Dalga formu
- `visualizer_circle.png` - Circular spectrum
- Boyut: 512x512px, transparent PNG

#### Map & Globe İkonları
- `world_map.png` - Dünya haritası silueti (1024x512px)
- `location_pin.png` - Konum işaretleyici (64x64px)

### 🎭 Empty State İllüstrasyonları

#### Boş Durum Görselleri (Öncelik: ORTA)
- `empty_playlists.png` - Boş playlist görseli (400x300px)
- `empty_favorites.png` - Boş favoriler (400x300px)
- `empty_messages.png` - Boş mesaj kutusu (400x300px)
- `empty_notifications.png` - Boş bildirimler (400x300px)
- `empty_search.png` - Arama sonucu yok (400x300px)
- `empty_friends.png` - Arkadaş yok (400x300px)
- Stil: Minimalist, tek renk veya hafif gradient

### 🎨 Background & Gradient Assets

#### Arka Plan Görselleri (Öncelik: DÜŞÜK)
- `gradient_primary.png` - Ana gradient (#FF5E5E → #FF8E3C)
- `gradient_secondary.png` - İkincil gradient (Purple → Blue)
- `pattern_music.png` - Müzik notası pattern (tileable)
- `pattern_waves.png` - Ses dalgası pattern (tileable)
- Boyut: 1080x1920px veya tileable 512x512px

### 🎬 Animasyon Assets (Opsiyonel)

#### Lottie Animasyonları
- `loading_music.json` - Yükleme animasyonu
- `success_check.json` - Başarılı işlem
- `empty_state.json` - Boş durum animasyonu
- `music_playing.json` - Müzik çalıyor animasyonu
- Format: Lottie JSON (lottiefiles.com'dan hazır veya custom)

### 📸 Ekran Görüntüleri (Play Store/App Store)

#### Store Listing Screenshots (Öncelik: YÜKSEK)
- **5-8 adet ekran görüntüsü** (1080x1920px veya 1242x2688px)
  1. Ana sayfa (keşif feed)
  2. Şarkı detay sayfası
  3. Playlist oluşturma
  4. Sosyal feed
  5. Profil sayfası
  6. Mesajlaşma
  7. Analytics/Stats
  8. Gamification (achievements)
- Her screenshot için:
  - Temiz UI (test verileri değil, gerçekçi içerik)
  - Tutarlı telefon frame (iPhone/Android mockup)
  - Açıklayıcı text overlay (opsiyonel)

#### Promo Grafikleri
- **Feature Graphic** (1024x500px) - Play Store banner
- **App Preview Video** - 30 saniye demo (opsiyonel)

### 🎨 Tasarım Kaynakları & Araçlar

#### Önerilen Araçlar:
- **Figma/Adobe XD** - UI mockup ve prototipleme
- **Canva Pro** - Hızlı grafik tasarımı
- **Flaticon/IconScout** - İkon kütüphaneleri (ücretli premium)
- **Unsplash/Pexels** - Ücretsiz fotoğraf kaynağı
- **LottieFiles** - Hazır animasyon kütüphanesi
- **Freepik** - Vektör illustration (Premium)

#### Renk Paleti (Brand Colors):
```
Primary: #FF5E5E (Kırmızı/Pembe)
Secondary: #FF8E3C (Turuncu)
Accent: #9C27B0 (Mor)
Dark: #1E1E1E (Karanlık mod)
Light: #FFFFFF (Aydınlık mod)
```

### 📋 Öncelik Sıralaması

**Phase 1 (ZORUNLU):**
1. ✅ Uygulama ikonu (app_icon.png)
2. ✅ Splash screen logo
3. ✅ 17 Achievement rozetleri
4. ✅ Store screenshots (5 adet minimum)

**Phase 2 (ÖNERİLEN):**
1. Genre/Mood ikonları (10 adet)
2. Empty state illustrasyonları (6 adet)
3. Onboarding görselleri (4 adet)
4. Leaderboard trophy'leri

**Phase 3 (OPSİYONEL):**
1. Lottie animasyonlar
2. Background patterns
3. Visualizer assets
4. App preview video

### 📁 Dosya Organizasyonu

```
assets/
├── images/
│   ├── logos/
│   │   ├── app_icon.png
│   │   └── splash_logo.png
│   ├── onboarding/
│   │   ├── onboarding_1.png
│   │   └── ...
│   ├── badges/
│   │   ├── badge_first_review.png
│   │   └── ...
│   ├── genres/
│   │   ├── genre_rock.png
│   │   └── ...
│   ├── moods/
│   │   ├── mood_energetic.png
│   │   └── ...
│   └── empty_states/
│       ├── empty_playlists.png
│       └── ...
├── icons/
│   ├── trophy_gold.png
│   └── ...
└── animations/
    ├── loading_music.json
    └── ...
```

### 💡 Tasarım Notları

- **Tutarlılık:** Tüm görseller aynı stil/tema
- **Responsive:** 1x, 2x, 3x versiyonları (Flutter auto-handle)
- **Dark Mode:** Karanlık mod uyumlu renkler
- **Accessibility:** Yüksek kontrast, okunabilir
- **File Size:** Optimize edilmiş (<200KB per image)
- **Copyright:** Telif hakkı sorunları olmayan kaynaklar

## 🗂️ Proje Yapısı

```
lib/
├── core/              # Tema, sabitler, yardımcılar
├── features/          # Özellik bazlı modüller
│   ├── auth/         # Kimlik doğrulama
│   ├── messaging/    # DM sistemi
│   ├── playlists/    # Playlist yönetimi
│   └── profile/      # Kullanıcı profili
├── shared/           # Paylaşılan bileşenler
│   ├── models/       # Veri modelleri
│   ├── services/     # Firebase servisleri
│   └── widgets/      # Ortak widgetlar
└── main.dart         # Uygulama giriş noktası
```

## ✅ Tamamlanan Özellikler

### Discovery & Recommendations (Keşif ve Öneriler)
- ✅ **Spotify Recommendations API** - Kişiselleştirilmiş şarkı önerileri
- ✅ **Last.fm Benzer Şarkılar** - Benzer şarkı keşfi
- ✅ **Track Detail Önerileri** - Her şarkı sayfasında ilgili öneriler

### Enhanced Artist & Album Pages (Gelişmiş Sanatçı ve Albüm Sayfaları)
- ✅ **Artist Detail Page** - 3 tab (Hakkında, Popüler Şarkılar, Diskografi)
- ✅ **Last.fm Entegrasyonu** - Sanatçı biyografisi ve benzer sanatçılar
- ✅ **Aylık Dinleyici** - Spotify follower verisi gösterimi
- ✅ **Album Detail Page** - İstatistikler, review/rating sistemi
- ✅ **Şarkı Listesi** - Tam track list ile entegre detay

### Social Features (Sosyal Özellikler)
- ✅ **User Profile Pages** - Detaylı kullanıcı profil sayfaları
- ✅ **Takip Sistemi** - Follow/Unfollow özelliği
- ✅ **Kullanıcı Arama** - Gelişmiş kullanıcı arama sistemi
- ✅ **Social Feed** - Aktivite feed (Tümü, Takip, Popüler)
- ✅ **Profil Tabları** - İncelemeler, Listeler, Favori, Aktivite

### Advanced Filtering & Sorting (Gelişmiş Filtreleme)
- ✅ **Genre Filtreleme** - 12+ müzik türü filtresi
- ✅ **Yıl Aralığı** - Min/max yıl seçimi
- ✅ **Popülerlik ve Rating** - Slider ile hassas filtreleme
- ✅ **Sıralama Seçenekleri** - En Yeni, En Popüler, En Yüksek Puan, Alfabetik
- ✅ **Modern Bottom Sheet** - Kullanıcı dostu arayüz

### Smart Playlists (Akıllı Playlistler)
- ✅ **Ruh Hali Bazlı** - Enerjik, Sakin, Mutlu, Konsantrasyon
- ✅ **Tür Bazlı** - Rock, Pop, Hip Hop koleksiyonları
- ✅ **Dönem Bazlı** - 90'lar, 2000'ler, 2010'lar nostalji listeleri
- ✅ **Aktivite Bazlı** - Spor, Parti için optimize listeler
- ✅ **Otomatik Oluşturma** - Kullanıcı kütüphanesine göre
- ✅ **Modern Gradient Cards** - Görsel olarak zengin tasarım

### Collaborative Playlists (Ortak Playlistler)
- ✅ **Rol Tabanlı İzinler** - Owner, Editor, Viewer rolleri
- ✅ **İşbirlikçi Yönetimi** - Kullanıcı ekleme/çıkarma, rol değiştirme
- ✅ **İzin Kontrolü** - canEdit(), canManage(), canView() metodları
- ✅ **Bildirim Sistemi** - Playlist'e eklendiğinde otomatik bildirim
- ✅ **Real-time Sync** - Firestore ile anlık güncelleme

### Playlist Sharing (QR Kod ile Paylaşım)
- ✅ **QR Kod Oluşturma** - Playlist için otomatik QR kod
- ✅ **Paylaşım Seçenekleri** - Link kopyalama, sosyal medya paylaşımı
- ✅ **Güzel UI** - Modern paylaşım bottom sheet

### In-App Notifications (Uygulama İçi Bildirimler)
- ✅ **Bildirim Tipleri** - Collaborator, like, comment, follow, message
- ✅ **Bildirim Yönetimi** - Okundu işaretleme, silme
- ✅ **Okunmamış Sayacı** - Real-time unread count

## 🔮 Development Roadmap

> **Status:** 🎉 Phase 1 Complete - Ready for Visual Enhancements  
> **Latest Update:** 2025-11-02 13:18 - All Core Features Complete & App Running Successfully!
> **Next Phase:** Visual Enhancements & AI Features

### ✅ Recently Completed (Nov 2, 2025)
- ✅ **Queue System** - Full playback queue management with shuffle/repeat
- ✅ **Audio Effects** - Crossfade & Equalizer with 21 presets
- ✅ **Sleep Timer** - Auto-stop playback with multiple presets
- ✅ **Social Interactions** - Like system, comments, and social sharing
- ✅ **Personalized Discovery** - Daily Mix & Release Radar
- ✅ **Music Exploration** - Decade Explorer (60s-2020s) & Genre Deep Dive
- ✅ **Onboarding Flow** - 4 sayfa intro screens
- ✅ **Shimmer Loading** - Professional skeleton screens
- ✅ **Mini Player** - 30s preview playback
- ✅ **All Priority Features UI** - 18 professional pages completed and integrated
- ✅ **Complete Service Layer** - 9 backend services fully implemented
- ✅ **Group Sessions & Music Rooms** - Real-time collaboration with voting system

### 🎯 Priority Features (100% Completed! ✨)

#### 🎵 Music Features
- ✅ **Lyrics Integration** - Genius API ile şarkı sözleri (lyrics_service.dart)
- ✅ **Queue System** - Çalma kuyruğu yönetimi (queue_service.dart + queue_page.dart)
- ✅ **Crossfade & Equalizer** - Ses efektleri (audio_effects_service.dart - 21 preset)
- ✅ **Sleep Timer** - Zamanlı durdurma (sleep_timer_service.dart)
- ✅ **Last.fm Scrobbling** - Otomatik kayıt (lastfm_service.dart)

#### 🤝 Social Features
- ✅ **Follow System Enhanced** - Activity feed entegrasyonu (follow_service.dart)
- ✅ **Comments on Reviews** - Yorum sistemi (social_interactions_service.dart)
- ✅ **Like System** - Review & playlist beğeni (social_interactions_service.dart)
- ✅ **Social Media Share** - Twitter, Instagram (social_interactions_service.dart)
- ✅ **Collaborative Playlists** - Real-time işbirliği (Already completed)

#### 🔍 Discovery Features
- ✅ **Daily Mix** - Kişiselleştirilmiş mixler (personalized_discovery_service.dart)
- ✅ **Release Radar** - Yeni çıkan şarkılar (personalized_discovery_service.dart)
- ✅ **Mood Playlists** - Ruh hali bazlı (smart_playlists_page.dart - already exists)
- ✅ **Decade Explorer** - 60'lar-2020'ler keşfi (music_exploration_service.dart)
- ✅ **Genre Deep Dive** - Tür bazlı detaylı keşif (music_exploration_service.dart)

#### 📊 Analytics & Insights
- ✅ **Listening Clock** - Saatlik dinleme analizi (analytics_service.dart)
- ✅ **Music Map** - Dünya haritasında artist konumları (analytics_service.dart)
- ✅ **Taste Profile** - Detaylı müzik zevki + kişilik analizi (analytics_service.dart)
- ✅ **Yearly Wrapped** - Yıllık özet benzeri (analytics_service.dart)
- ✅ **Friends Comparison** - Arkadaş zevk karşılaştırma (analytics_service.dart)

#### 🎮 Gamification
- ✅ **Achievements/Badges** - 17 achievements with points system (gamification_service.dart)
- ✅ **Streaks** - Daily streak tracking with longest streak (gamification_service.dart)
- ✅ **Leaderboards** - Global and friends leaderboards (gamification_service.dart)
- ✅ **Music Quiz** - 6 quiz types: Guess Song/Artist/Year/Genre/Album, Finish Lyrics (music_quiz_service.dart)
- ✅ **Weekly Challenges** - Rotating challenges with rewards (music_quiz_service.dart)

#### 📴 Offline & Performance
- ✅ **Download Tracks** - Track download with progress tracking (offline_service.dart)
- ✅ **Offline Queue** - Offline playback queue management (offline_service.dart)
- ✅ **Smart Download** - Auto-download top tracks (offline_service.dart)
- ✅ **Cache Optimization** - Image & data caching with size limits (cache_optimization_service.dart)

#### 👥 Collaboration
- ✅ **Group Sessions** - Real-time listening sessions (group_session_service.dart + UI)
- ✅ **Music Rooms** - Live listening rooms with real-time sync (group_session_service.dart)
- ✅ **Vote to Skip** - Democratic skip voting (50% required)
- ✅ **Shared Queue** - Collaborative queue management

#### 🧠 AI & Smart Features (Next Priority)
- [ ] **AI Recommendations** - ML tabanlı öneriler (TensorFlow Lite)
- [ ] **Mood Detection** - Otomatik ruh hali analizi (Audio analysis)
- [ ] **Auto-Mix** - Akıllı playlist oluşturma (ML-based)
- [ ] **Similar Songs** - Benzer şarkı bulma (Vector similarity)
- [ ] **Smooth Transitions** - Playlist geçişleri (Crossfade optimization)

#### 🎨 Visual Enhancements (Immediate Next Step)
- [ ] **Now Playing Animation** - Visualizer, dalga efektleri (Audio visualization)
- [ ] **Album Color Theme** - Dinamik renk temaları (Palette extraction)
- [ ] **Canvas/Video Background** - Video arka planlar (Spotify Canvas API)
- [ ] **Synced Lyrics** - Karaoke görünümü (LRC format support)
- [ ] **Concert Info** - Yakındaki konserler (Bandsintown API)

#### 🔗 Integrations
- [ ] **Apple Music** - Apple Music entegrasyonu
- [ ] **YouTube Music** - YouTube entegrasyonu
- [ ] **SoundCloud** - SoundCloud entegrasyonu
- [ ] **Bandcamp** - Bağımsız artist keşfi
- [ ] **Instagram Stories** - "Now Playing" story

#### 🔔 Notifications & Engagement
- [ ] **Push Notifications** - FCM entegrasyonu (Android 13+ için bildirim izni gerekli)
- [ ] **Daily Digest** - Günlük özet bildirimleri
- [ ] **Friend Activity Alerts** - Arkadaş aktiviteleri
- [ ] **New Release Alerts** - Yeni çıkanlar
- [ ] **Personalized Reminders** - Akıllı hatırlatmalar

---

## 🎯 Post-1.0 Features

### Coming Soon (v1.1)
- [ ] **QR Scanner** - Kamera ile QR kod okuma ✨ (Hazır, test edilecek)
- [ ] **Deep Linking** - QR koddan playlist açma
- [ ] **Voice Search** - Sesli arama özelliği
- [ ] **Offline Mode** - Çevrimdışı kullanım desteği
- [ ] **Advanced Analytics** - Kullanıcı istatistikleri ve insights

### Future Releases (v1.2+)
- [ ] **Playlist Analytics** - Detaylı istatistikler (toplam süre, en çok eklenen)
- [ ] **Playlist Comments & Ratings** - Sosyal özellikler
- [ ] **Multi-Platform Export** - Apple Music, YouTube Music desteği
- [ ] **Version Control** - Playlist geçmişi ve geri alma
- [ ] **Collaborative Listening** - Arkadaşlarınla birlikte dinle
- [ ] **Music Quizzes** - Müzik bilgi yarışmaları
- [ ] **Concert Discovery** - Yakındaki konserler
- [ ] **Lyrics Integration** - Genius API ile senkronize şarkı sözleri

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Pull request göndermekten çekinmeyin.

1. Projeyi fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request açın

## 👥 Ekip

- **Mert** - Geliştirici
- **Furkan** - Geliştirici

## 🙏 Teşekkürler

- Letterboxd'den ilham alındı
- Spotify'ın harika API'si için
- Flutter topluluğuna mükemmel paketler için

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır.

## 📞 İletişim

- Proje Linki: https://github.com/furkankobain/tuniverse
- Issues: https://github.com/furkankobain/tuniverse/issues

---

⭐ Projeyi beğendiyseniz yıldız vermeyi unutmayın!

# 🎯 AdMob Kurulum Rehberi

## 1️⃣ AdMob Hesabı Oluştur

1. **AdMob'a git**: https://admob.google.com/
2. **Sign in with Google** ile giriş yap
3. **Get Started** butonuna tıkla

## 2️⃣ App Ekle

1. **Apps** menüsünden → **ADD APP**
2. **Select a platform**: Android seç (iOS varsa onu da ekle)
3. **Is your app listed on a supported app store?**: NO seç
4. **App name**: `Tuniverse` yaz
5. **ADD** butonuna tıkla
6. ✅ App oluşturuldu!

## 3️⃣ App ID'yi Kopyala

App oluşturulduktan sonra:
1. **App settings** (sağ üstte ⚙️ ikonu)
2. **App ID**'yi kopyala → Format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`

### App ID'yi AndroidManifest.xml'e Ekle

Dosya: `android/app/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX" />
```

**Satır 75'teki test ID'yi değiştir!**

## 4️⃣ Ad Units Oluştur

### Banner Ad Unit (Küçük Reklam)

1. **Ad units** sekmesine git
2. **ADD AD UNIT** → **Banner** seç
3. **Ad unit name**: `Tuniverse Banner`
4. **CREATE AD UNIT**
5. ✅ **Ad unit ID**'yi kopyala → Format: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`

### Interstitial Ad Unit (Tam Ekran Reklam)

1. **ADD AD UNIT** → **Interstitial** seç
2. **Ad unit name**: `Tuniverse Interstitial`
3. **CREATE AD UNIT**
4. ✅ **Ad unit ID**'yi kopyala

### Rewarded Ad Unit (Ödüllü Reklam) [Opsiyonel]

1. **ADD AD UNIT** → **Rewarded** seç
2. **Ad unit name**: `Tuniverse Rewarded`
3. **CREATE AD UNIT**
4. ✅ **Ad unit ID**'yi kopyala

## 5️⃣ Ad Unit ID'leri Koda Ekle

Dosya: `lib/shared/services/admob_service.dart`

### Banner Ad Unit ID (Satır 16):

```dart
return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Senin Banner ID'n
```

### Interstitial Ad Unit ID (Satır 29):

```dart
return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Senin Interstitial ID'n
```

## 6️⃣ Test Et

### Test ID'leri (Şu an aktif)

Kodda şu an **Google'ın test ID'leri** var. Bunlar test için çalışıyor ve para kazandırmıyor.

**Test ID'leri ile geliştirme yap**, sonra gerçek ID'leri ekle!

### Gerçek ID'leri Ne Zaman Eklemeli?

- ✅ Geliştirme sırasında → Test ID'leri kullan
- ✅ Google Play'e yüklemeden ÖNCE → Gerçek ID'leri ekle
- ❌ Test ID'leri ile PRODUCTION'a çıkma!

## 7️⃣ Reklam Türleri

### Banner Ads (Sayfa altında/üstünde)

```dart
import 'package:tuniverse/shared/widgets/banner_ad_widget.dart';

// Normal banner (320x50)
const BannerAdWidget()

// Büyük banner (320x100)
const LargeBannerAdWidget()

// Ekrana uyarlanmış banner (önerilen!)
const AdaptiveBannerAdWidget()
```

### Interstitial Ads (Quiz bitince, sayfa geçişinde)

```dart
import 'package:tuniverse/shared/services/admob_service.dart';

// Tam ekran reklam göster
await AdMobService.showInterstitialAd();
```

## 8️⃣ Önerilen Yerler

1. ✅ **Quiz Result Page** → Quiz bitince interstitial ad
2. ✅ **Leaderboard Page** → Sayfanın altında banner
3. ✅ **Profile Page** → Sayfanın altında banner
4. ✅ **Search Results** → Her 5 sonuçtan sonra banner
5. ✅ **Feed Page** → Her 10 post'tan sonra banner

## 9️⃣ PRO Kullanıcılar

**PRO kullanıcılarda reklam gösterilmez!**

Sistem otomatik kontrol ediyor:
- `ProStatusService.isProUser()` kontrolü yapılıyor
- PRO ise reklam yüklenmiyor
- FREE kullanıcılara gösteriliyor

## 🔟 AdMob Console

### Para Kazanç Takibi

1. **Home** → Günlük kazancını görebilirsin
2. **Apps** → Hangi app ne kadar kazandırıyor
3. **Reports** → Detaylı raporlar

### Ödeme Ayarları

1. **Payments** → Banka hesabı ekle
2. Minimum $100 olunca ödeme yapılıyor
3. Her ayın 21'inde ödeme

## ⚠️ Önemli Notlar

1. **Test ID'leri ile test et!** Kendi reklamlarına tıklama → ban yersin
2. **Google Play'e yüklemeden önce gerçek ID'leri ekle**
3. **AdMob politikalarına uy**: https://support.google.com/admob/answer/6128543
4. **Reklam yerleşimi**: Kullanıcı deneyimini bozma
5. **Tıklama teşviki**: "Reklama tıkla" deme → ban yersin

## 🚀 Hızlı Başlangıç

### 1. AdMob'dan ID'leri Al

- App ID → AndroidManifest.xml'e ekle
- Banner Ad Unit ID → admob_service.dart satır 16
- Interstitial Ad Unit ID → admob_service.dart satır 29

### 2. Uygulamayı Test Et

Test ID'leri ile reklamları test et:

```bash
flutter run
```

### 3. Gerçek ID'leri Ekle

Production'a çıkmadan önce gerçek ID'leri ekle!

### 4. Google Play'e Yükle

APK/AAB dosyasını oluştururken gerçek ID'lerin olduğundan emin ol:

```bash
flutter build appbundle --release
```

## 📞 Yardım

AdMob sorunları için: https://support.google.com/admob/

---

**Hazır olduğunda bana söyle, beraber reklamları ekleyelim! 🎯**

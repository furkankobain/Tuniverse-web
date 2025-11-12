# Backend Setup Guide - Tuniverse

Bu dokümanda Tuniverse uygulamasının backend tarafını (Firebase Cloud Functions) kurulumu ve deploy edilmesi anlatılmaktadır.

## 📋 Gereksinimler

- Node.js 18 veya üzeri
- Firebase CLI (`npm install -g firebase-tools`)
- Firebase projesi (Firestore, Authentication, Cloud Messaging aktif)

## 🚀 Kurulum

### 1. Firebase CLI Kurulumu

```bash
npm install -g firebase-tools
firebase login
```

### 2. Firebase Projesini Bağlama

```bash
firebase use --add
# Projenizi seçin (tuniverse veya kendi proje adınız)
```

### 3. Cloud Functions Bağımlılıklarını Kurma

```bash
cd functions
npm install
```

## 📦 Cloud Functions

Backend aşağıdaki cloud functions'ları içeriyor:

### Bildirim (Notification) Functions

#### 1. **onNewFollower**
- **Trigger**: Firestore `users/{userId}/followers/{followerId}` onCreate
- **Açıklama**: Kullanıcı yeni takipçi kazandığında bildirim gönderir
- **Bildirim**: "Yeni Takipçi 🎉 - [Kullanıcı Adı] seni takip etmeye başladı!"

#### 2. **onTrackLiked**
- **Trigger**: Firestore `tracks/{trackId}/likes/{userId}` onCreate
- **Açıklama**: Şarkı beğenildiğinde sahibine bildirim gönderir
- **Bildirim**: "Yeni Beğeni ❤️ - [Kullanıcı Adı] [Şarkı Adı] beğendi!"

### Zamanlanmış (Scheduled) Functions

#### 3. **sendDailyRecommendations**
- **Zamanlama**: Her gün saat 09:00 (Europe/Istanbul)
- **Açıklama**: Müzik önerileri için günlük bildirim gönderir
- **Hedef**: `notificationSettings.musicRecommendations = true` olan kullanıcılar

#### 4. **sendWeeklyDigest**
- **Zamanlama**: Her Pazar 20:00 (Europe/Istanbul)
- **Açıklama**: Haftalık dinleme özeti bildirimi gönderir
- **Hedef**: `notificationSettings.weeklyDigest = true` olan kullanıcılar

#### 5. **analyzeDailyMood**
- **Zamanlama**: Her gün saat 18:00 (Europe/Istanbul)
- **Açıklama**: Kullanıcının ruh hali analizi yapılmış bildirimi gönderir
- **Koşul**: Son 24 saatte en az 5 şarkı dinlemiş olmalı

#### 6. **cleanupOldHistory**
- **Zamanlama**: Her gün saat 03:00 (Europe/Istanbul)
- **Açıklama**: 90 günden eski dinleme geçmişini siler (GDPR uyumlu)
- **Limit**: Her çalıştırmada maksimum 500 kayıt

### Trigger Functions

#### 7. **updateUserStats**
- **Trigger**: Firestore `listeningHistory/{historyId}` onCreate
- **Açıklama**: Kullanıcı dinleme istatistiklerini otomatik günceller
- **Güncellenen**: `users/{userId}/stats/listening`
  - `totalTracks`: Toplam dinlenen şarkı sayısı
  - `totalListeningTime`: Toplam dinleme süresi (saniye)
  - `lastUpdated`: Son güncelleme zamanı

## 🔥 Deployment

### Test Ortamı (Emulator)

```bash
cd functions
npm run serve
```

Bu komut local emulator'u başlatır. Emulator'da test edebilirsiniz.

### Production Deployment

```bash
# Tüm functions'ları deploy et
firebase deploy --only functions

# Sadece belirli bir function deploy et
firebase deploy --only functions:sendDailyRecommendations
```

### İlk Deployment Öncesi Kontrol Listesi

- [ ] Firebase projesinde **Blaze Plan** aktif (Cloud Functions ücretli planda çalışır)
- [ ] Firestore Database oluşturulmuş
- [ ] Firebase Authentication aktif
- [ ] Cloud Messaging (FCM) aktif
- [ ] `firestore.rules` ve `firestore.indexes.json` deploy edilmiş

## 📊 Firestore Indexes

Bazı sorgular için index gereklidir. Aşağıdaki komutu çalıştırarak indexleri deploy edin:

```bash
firebase deploy --only firestore:indexes
```

Gerekli indexler:
- `listeningHistory` (userId + timestamp)
- `users` (fcmToken + notificationSettings.musicRecommendations)
- `messages` (conversationId + timestamp)
- `playlists` (userId + updatedAt)
- `reviews` (albumId + createdAt)

## 🔐 Firestore Rules

Production için güvenlik kurallarını güncelleyin:

```bash
firebase deploy --only firestore:rules
```

**ÖNEMLİ**: `firestore.rules` dosyasında test mode kapalı olmalı!

Test modunu kapatmak için `firestore.rules` dosyasındaki şu satırları yorum satırına alın:

```javascript
// REMOVE THIS FOR PRODUCTION!
match /{document=**} {
  allow read, write: if true;
}
```

## 📈 Monitoring

### Logları Görüntüleme

```bash
# Tüm loglar
firebase functions:log

# Belirli bir function
firebase functions:log --only sendDailyRecommendations
```

### Firebase Console'da İzleme

1. [Firebase Console](https://console.firebase.google.com) açın
2. Projenizi seçin
3. **Functions** sekmesine gidin
4. Execution details, logs ve metrics görüntüleyebilirsiniz

## 💰 Maliyet Tahmini

Firebase Blaze Plan'da:
- **İlk 2M invocation/ay**: Ücretsiz
- **Sonrası**: $0.40 / 1M invocation
- **Zamanlanmış Functions**: Günde ~1440 invocation (her function için)

Örnek hesaplama (günlük 1000 aktif kullanıcı):
- Bildirimler: ~5000/gün = ~150k/ay
- Zamanlanmış: ~1440/gün = ~43k/ay
- **Toplam**: ~193k/ay (ücretsiz limit içinde)

## 🔧 Troubleshooting

### Problem: Functions deploy olmuyor
**Çözüm**: Node.js versiyonunu kontrol edin (18+ olmalı)
```bash
node --version
```

### Problem: Permission denied
**Çözüm**: Firebase'e tekrar login olun
```bash
firebase logout
firebase login
```

### Problem: Index hatası
**Çözüm**: Firestore Console'da önerilen index linkine tıklayın veya `firestore.indexes.json` güncelleyin

### Problem: FCM token yok
**Çözüm**: Mobil uygulamada FCM token'ı Firestore'a kaydettiğinizden emin olun
```dart
// Flutter'da
final token = await FirebaseMessaging.instance.getToken();
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({'fcmToken': token});
```

## 🧪 Test Etme

### Manuel Test

1. Firebase Console > Cloud Messaging'e gidin
2. "Send test message" tıklayın
3. FCM token girin ve gönder

### Function Test

```bash
cd functions
npm test  # (test dosyası oluşturmanız gerekir)
```

## 📚 Ek Kaynaklar

- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

---

**Son Güncelleme**: 2025-11-02  
**Versiyon**: 1.0.0

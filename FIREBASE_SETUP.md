# Firebase Setup Instructions 🔥

Bu dosya, Firebase ayarlarının nasıl yapılacağını açıklar.

## ✅ Otomatik Yapılan İşlemler

Aşağıdaki dosyalar otomatik olarak oluşturuldu/güncellendi:

1. **firestore.rules** - Firestore güvenlik kuralları
2. **storage.rules** - Firebase Storage güvenlik kuralları  
3. **android/app/src/main/AndroidManifest.xml** - FCM ayarları eklendi
4. **lib/shared/services/notification_service.dart** - Mesaj bildirimleri eklendi

## 📋 Senin Yapman Gerekenler

### 1. Firestore Security Rules

1. [Firebase Console](https://console.firebase.google.com) → Projenizi seçin
2. **Firestore Database** → **Rules** sekmesi
3. `firestore.rules` dosyasının içeriğini kopyala ve yapıştır
4. **Publish** butonuna tıkla

### 2. Storage Security Rules

1. Firebase Console → **Storage** → **Rules** sekmesi
2. `storage.rules` dosyasının içeriğini kopyala ve yapıştır
3. **Publish** butonuna tıkla

### 3. FCM Token Kontrolü (Test)

Uygulamayı çalıştır ve debug console'da FCM token'ı kontrol et:

```
flutter run
```

Console'da şu çıktıyı görmelisin:
```
FCM Token: fxxxxxx...
```

## 🎯 Yapılan Değişiklikler

### firestore.rules
- **conversations**: Sadece katılımcılar okuyabilir/yazabilir
- **messages**: Giriş yapmış kullanıcılar okuyabilir, sadece gönderen silebilir
- **playlists**: Public olanları herkes, private olanları sadece sahibi görebilir

### storage.rules
- **playlists/{userId}/{playlistId}**: Playlist kapak resimleri
- **messages/{conversationId}**: Mesajdaki resim paylaşımları
- **users/{userId}**: Profil resimleri

### AndroidManifest.xml
- FCM notification icon ve color meta-data eklendi
- INTERNET ve RECEIVE_BOOT_COMPLETED izinleri eklendi

### notification_service.dart
- `showNewMessage()` metodu eklendi
- Mesaj bildirimleri için özel channel

## 🔔 Bildirim Test Etme

```dart
// Test mesaj bildirimi
await NotificationService.showNewMessage(
  senderName: 'Test User',
  messageContent: 'Merhaba!',
  conversationId: 'test_123',
);
```

## 📱 Sonraki Adımlar

1. ✅ Firestore & Storage rules'u Firebase Console'dan yayınla
2. ⏭️ Conversation List UI'ı test et
3. ⏭️ Chat UI'ı oluştur
4. ⏭️ Müzik paylaşımı özelliği ekle

## ⚠️ Önemli Notlar

- **Production'da**: Security rules'u mutlaka kontrol et
- **FCM Backend**: Gerçek bildirim göndermek için backend servisi gerekir
- **Test Modu**: Şimdilik auth check'li rules kullanıyoruz

## 🆘 Sorun Giderme

### "Missing or insufficient permissions" hatası
→ Firestore rules'u kontrol et ve publish et

### FCM token null geliyor
→ AndroidManifest.xml'de FCM ayarlarının doğru olduğundan emin ol

### Bildirim gelmiyor
→ FCM token alındığını console'da kontrol et
→ Foreground/background handler'ları kontrol et

---

✅ **Tamamlandı!** Firebase ayarlarını yaptıktan sonra mesajlaşma özelliği çalışmaya hazır.

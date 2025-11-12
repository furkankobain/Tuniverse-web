# Spotify API Entegrasyonu - Kurulum Rehberi

## Genel Bakış

MusicShare uygulaması artık Spotify API ile tam entegre çalışıyor. Bu rehber, uygulamayı Spotify hesabınızla bağlamak için gereken adımları açıklar.

## Yapılan Değişiklikler

### 1. **Spotify OAuth 2.0 PKCE Flow**
- ✅ Authorization Code Flow with PKCE implementasyonu
- ✅ Token yönetimi (access token, refresh token)
- ✅ Otomatik token yenileme
- ✅ Güvenli token saklama (SharedPreferences)

### 2. **Gerçek Spotify API Çağrıları**
Aşağıdaki API endpoint'leri implement edildi:
- ✅ User Profile (`/me`)
- ✅ User Playlists (`/me/playlists`)
- ✅ Playlist Tracks (`/playlists/{id}/tracks`)
- ✅ Top Tracks (`/me/top/tracks`)
- ✅ Top Artists (`/me/top/artists`)
- ✅ Recently Played (`/me/player/recently-played`)
- ✅ Album Info (`/albums/{id}`)
- ✅ Search (`/search`)

### 3. **Login Sayfası Güncellemeleri**
- ✅ "Spotify ile Giriş Yap" butonu eklendi
- ✅ "Google ile Giriş Yap" butonu eklendi (placeholder)
- ✅ Email/Password giriş korundu

### 4. **Spotify Senkronizasyon Servisi**
Otomatik senkronizasyon özellikleri:
- ✅ Profil fotoğrafı Spotify'dan alınır
- ✅ Spotify playlist'leri MusicShare listelerine dönüştürülür
- ✅ Top tracks senkronizasyonu
- ✅ Top artists senkronizasyonu
- ✅ Recently played tracks senkronizasyonu

### 5. **Deep Link Support**
- ✅ Android deep link konfigürasyonu (`musicshare://callback`)
- ✅ OAuth callback handling
- ✅ Otomatik home page yönlendirmesi

## Spotify Developer App Kurulumu

### Adım 1: Spotify Developer Dashboard'a Giriş
1. [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)'a gidin
2. Spotify hesabınızla giriş yapın
3. "Create app" butonuna tıklayın

### Adım 2: App Bilgilerini Doldurun
- **App name**: MusicShare
- **App description**: Music rating and social platform
- **Redirect URI**: `musicshare://callback` (Önemli!)
- **API/SDKs**: Web API seçin
- Kullanım şartlarını kabul edin

### Adım 3: Client Credentials
App oluşturduktan sonra:
1. "Settings" sekmesine gidin
2. **Client ID** ve **Client Secret** değerlerini kopyalayın
3. Bu değerleri `lib/core/constants/app_constants.dart` dosyasında güncelleyin:

```dart
static const String spotifyClientId = 'BURAYA_CLIENT_ID_YAZ';
static const String spotifyClientSecret = 'BURAYA_CLIENT_SECRET_YAZ';
```

### Adım 4: Redirect URI Doğrulama
Settings'te şu URI'nin eklendiğinden emin olun:
```
musicshare://callback
```

## Kullanım

### 1. Spotify ile Giriş
1. Uygulamayı açın
2. Login sayfasında "Spotify ile Giriş Yap" butonuna tıklayın
3. Tarayıcı açılacak, Spotify hesabınızla giriş yapın
4. İzinleri onaylayın
5. Otomatik olarak uygulamaya geri döneceksiniz
6. Profil bilgileri ve playlist'ler otomatik senkronize edilecek

### 2. Senkronizasyon
İlk giriş yapıldığında otomatik olarak:
- Profil fotoğrafınız güncellenir
- Spotify playlist'leriniz uygulamaya aktarılır
- En çok dinlediğiniz şarkılar kaydedilir
- En çok dinlediğiniz sanatçılar kaydedilir
- Son dinlenen şarkılar kaydedilir

### 3. Manuel Senkronizasyon
Ayarlar sayfasından "Spotify'ı Senkronize Et" butonuna basarak manuel olarak da senkronizasyon yapabilirsiniz.

## Teknik Detaylar

### Güvenlik
- PKCE (Proof Key for Code Exchange) kullanılır
- Client Secret sadece token refresh'te kullanılır
- Token'lar güvenli bir şekilde local storage'da saklanır
- State parameter ile CSRF koruması

### Token Yönetimi
- Access token: 1 saat geçerli
- Refresh token: Kalıcı
- Otomatik token yenileme (süre dolmadan 5 dakika önce)
- Token expire olduğunda otomatik disconnect

### API Rate Limiting
Spotify API limitleri:
- Standard: 180 request/minute
- Rate limit aşılırsa: 429 error (otomatik retry mekanizması)

## Sorun Giderme

### "Redirect URI Mismatch" Hatası
**Çözüm**: Spotify Dashboard'da redirect URI'nin tam olarak `musicshare://callback` olduğundan emin olun.

### "Invalid Client" Hatası
**Çözüm**: Client ID ve Client Secret değerlerini kontrol edin.

### Token Expire Hatası
**Çözüm**: Uygulamadan çıkış yapıp tekrar giriş yapın.

### Deep Link Çalışmıyor
**Çözüm**: 
1. Android Manifest dosyasını kontrol edin
2. Uygulamayı temiz build edin: `flutter clean && flutter build apk`

## Test Modunda Kullanım

Spotify Developer Mode'da:
- Sadece Dashboard'a eklediğiniz kullanıcılar test edebilir
- Production'a almak için "Quota Extension" başvurusu yapın
- Test için maksimum 25 kullanıcı ekleyebilirsiniz

### Test Kullanıcısı Ekleme
1. Spotify Dashboard > Users and Access
2. "Add User" butonuna tıklayın
3. Test edeceğiniz Spotify hesabının email'ini girin

## API Scope'ları

Uygulama şu Spotify izinlerini kullanır:
- `user-read-recently-played`: Son dinlenen şarkılar
- `user-top-read`: En çok dinlenen şarkı ve sanatçılar
- `user-library-read`: Kayıtlı şarkılar
- `user-follow-read`: Takip edilen sanatçılar
- `user-read-currently-playing`: Şu an çalan şarkı
- `user-read-playback-state`: Oynatma durumu
- `user-read-email`: Email adresi
- `user-read-private`: Profil bilgileri

## Geliştirici Notları

### Yeni API Endpoint Ekleme
`lib/shared/services/enhanced_spotify_service.dart` dosyasında yeni metodlar ekleyebilirsiniz:

```dart
static Future<Map<String, dynamic>> yeniEndpoint() async {
  await _checkAndRefreshToken();
  
  final response = await _dio.get(
    '${AppConstants.baseUrl}/endpoint',
    options: Options(
      headers: {'Authorization': 'Bearer $_accessToken'},
    ),
  );
  
  return response.data;
}
```

### Senkronizasyon Servisi Genişletme
`lib/shared/services/spotify_sync_service.dart` dosyasında yeni sync metodları ekleyebilirsiniz.

## Yardım ve Destek

Sorularınız için:
- [Spotify Web API Documentation](https://developer.spotify.com/documentation/web-api)
- [Spotify Authorization Guide](https://developer.spotify.com/documentation/general/guides/authorization/)

## Changelog

### v1.0.0 (2024)
- ✅ Spotify OAuth 2.0 PKCE implementasyonu
- ✅ Tam Spotify API entegrasyonu
- ✅ Profil ve playlist senkronizasyonu
- ✅ Login sayfası güncellemesi
- ✅ Deep link support

# biometric_auth

Aplikasi demo Flutter untuk autentikasi biometrik (sidik jari & face ID) dengan fallback password. Dibuat sebagai task tugas minggu week 8 mata kuliah Mobile Apps Lanjutan.

## Fitur

- ✅ Deteksi otomatis metode biometrik yang tersedia di perangkat
- ✅ Login dengan sidik jari
- ✅ Login dengan face ID
- ✅ Login dengan password sebagai fallback
- ✅ Structured error handling via `BiometricException`
- ✅ Animasi pulse saat menunggu verifikasi biometrik
- ✅ Pesan error yang ramah pengguna (Bahasa Indonesia)

## Struktur Proyek

    lib/
    ├── main.dart                      ← entry point & routing
    ├── pages/
    │   ├── login_page.dart            ← halaman login (3 mode tampilan)
    │   └── home_page.dart             ← halaman beranda setelah login
    └── services/
        ├── biometric_exception.dart   ← error model & enum
        └── biometric_service.dart     ← wrapper LocalAuthentication

## Cara Menjalankan

### Prasyarat
- Flutter >= 3.29.0
- Dart >= 3.7.0
- Android API >= 24
- Perangkat/emulator dengan sensor biometrik terdaftar

### Langkah"

```bash
# Clone repository
git clone https://github.com/username_lu/biometric_auth.git
cd biometric_auth

# Install dependency
flutter pub get

# Jalankan di Android
flutter run
```

## Konfigurasi Android

Permission di `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

`MainActivity.kt` menggunakan `FlutterFragmentActivity`:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity : FlutterFragmentActivity()
```

## Alur Aplikasi

    [Splash] → [Login Page]
                    │
                    ├── Pilih Face ID      → Dialog biometrik OS → [Home]
                    ├── Pilih Sidik Jari   → Dialog biometrik OS → [Home]
                    └── Pilih Password     → Form password       → [Home]

## Error Handling

| Error | Pesan ke User | Aksi UI |
|-------|--------------|---------|
| Tidak ada sensor | Perangkat tidak memiliki sensor biometrik | Otomatis pindah ke password |
| Belum terdaftar | Belum ada sidik jari tersimpan | Tombol buka Pengaturan |
| Terkunci sementara | Terlalu banyak percobaan gagal | - |
| Terkunci permanen | Biometrik terkunci, gunakan PIN | Otomatis pindah ke password |
| User batalkan | Autentikasi dibatalkan | Tombol Coba Lagi |
| Sistem batalkan | Dibatalkan oleh sistem | Tombol Coba Lagi |

## Dependencies

| Package | Versi | Kegunaan |
|---------|-------|---------|
| `local_auth` | ^3.0.1 | Autentikasi biometrik |
| `local_auth_android` | ^2.0.8 | Implementasi Android |

## Simulasi Password

Untuk testing, gunakan password berikut:

```
password123
```

---

1123150070<br>
Satria Herlambang
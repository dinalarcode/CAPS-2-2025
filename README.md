# 🥗 NutriLink x HealthyGo | Asisten Nutrisi Cerdas

NutriLink x HealthyGo adalah asisten nutrisi cerdas berbasis Flutter yang membantu pengguna mengelola diet dan tujuan kebugaran mereka dengan rekomendasi personal, panduan porsi, dan jadwal makan yang adaptif.

---

## 📱 Halaman Utama Aplikasi

### 1. 🏠 **Home (Beranda)**
Halaman utama yang menampilkan:
- **Ringkasan Harian**: Total kalori dikonsumsi, frekuensi makan, dan pengeluaran
- **Status Gizi**: Monitoring BMI dan perbandingan dengan target berat badan
- **Jadwal Makan Hari Ini**: Upcoming meals dengan status sudah/belum dikonsumsi
- **NutriAI Chatbot**: Asisten AI untuk estimasi kalori makanan dari luar

### 2. 🍽️ **Meal (Rekomendasi Makanan)**
Sistem rekomendasi makanan yang cerdas:
- **Smart Recommendation**: Rekomendasi menu berdasarkan TDEE dan target pengguna
- **Filter by Tags**: Filter makanan berdasarkan kategori (Ayam, Ikan, Vegetarian, dll)
- **Personalized Scoring**: Menu disusun berdasarkan kesesuaian dengan kebutuhan gizi
- **Shopping Cart**: Keranjang belanja untuk meal prep (maksimal 10 item)
- **Date Selection**: Pilih tanggal meal prep (besok hingga 30 hari ke depan)

### 3. 📅 **Schedule (Jadwal Makan)**
Manajemen jadwal makan harian:
- **Timeline View**: Lihat jadwal makan per waktu (Sarapan, Siang, Malam)
- **Order Status**: Status pesanan yang sudah dibuat
- **Date Navigation**: Navigasi antar tanggal untuk melihat rencana makan
- **Meal Details**: Detail nutrisi per menu (kalori, protein, karbo, lemak)

### 4. 📊 **Report (Laporan Nutrisi)**
Analisis dan tracking nutrisi:
- **Daily Log**: Catatan makanan harian dari NutriAI
- **Nutrition Breakdown**: Rincian kalori, protein, karbohidrat, dan lemak
- **Progress Tracking**: Grafik dan statistik konsumsi harian
- **Export Report**: Ekspor laporan untuk review jangka panjang

### 5. 👤 **Profile (Profil Pengguna)**
Pengaturan dan informasi pengguna:
- **Personal Info**: Nama, email, foto profil
- **Body Metrics**: Tinggi, berat, BMI, target berat badan
- **Preferences**: Alergi, aktivitas fisik, frekuensi makan
- **Settings**: Edit profil, logout, hapus akun

---

## ✨ Fitur Unggulan

### 🎯 Smart Recommendation System
- Algoritma rekomendasi berbasis **TDEE** (Total Daily Energy Expenditure)
- Personalisasi berdasarkan:
  - Target berat badan (Menurunkan/Mempertahankan/Menaikkan)
  - Alergi makanan
  - Tingkat aktivitas fisik
  - Jenis kelamin dan usia

### 🤖 NutriAI Chatbot
- **AI-powered**: Menggunakan Google Gemini API
- **Calorie Estimation**: Estimasi kalori dari deskripsi makanan
- **Food Log Saving**: Simpan hasil estimasi ke log harian
- **Conversational**: Interaksi natural seperti chat biasa
- **Edit & Resend**: Edit pesan sebelumnya dan kirim ulang

### 📦 Smart Cart System
- **Persistent Storage**: Cart tersimpan walaupun logout/restart app
- **Max 10 Items**: Validasi otomatis untuk batas cart
- **Auto-save**: Setiap perubahan cart langsung tersimpan
- **Real-time Badge**: Badge cart update otomatis tanpa refresh

### 🔄 Recommendation Cache
- **Daily Variation**: Menu berbeda setiap hari dengan deterministic shuffle
- **7-day Cache**: Cache rekomendasi selama 7 hari
- **Instant Load**: Loading cepat dari cache jika tersedia

---

## 🛠️ Teknologi yang Digunakan

| Kategori | Teknologi |
|----------|-----------|
| **Framework** | Flutter 3.x |
| **Bahasa** | Dart |
| **Backend** | Firebase (Authentication, Firestore, Storage) |
| **AI/ML** | Google Gemini API |
| **State Management** | Provider + StatefulWidget |
| **Caching** | SharedPreferences |
| **Image Caching** | CachedNetworkImage |
| **Design** | Figma |

---

## 🚀 Instalasi dan Setup

### Prasyarat
Pastikan sudah terinstall:
- **Flutter SDK** (versi 3.0 atau lebih baru)
- **Dart SDK** (bundled dengan Flutter)
- **Android Studio** atau **VS Code**
- **Git**
- **Emulator Android** atau **Perangkat Fisik**

### Langkah-Langkah Instalasi

1. **Clone Repository**
   ```bash
   git clone https://github.com/dinalarcode/CAPS-2-2025.git
   cd CAPS-2-2025
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   - Buka [Firebase Console](https://console.firebase.google.com/)
   - Buat project baru atau gunakan existing project
   - Download `google-services.json` untuk Android
   - Letakkan di folder `android/app/`

4. **Setup Gemini API**
   - Dapatkan API key dari [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Buat file `lib/config/gemini_config.dart`:
     ```dart
     class GeminiConfig {
       static const String apiKey = 'YOUR_GEMINI_API_KEY';
     }
     ```

5. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

---

## 📂 Struktur Folder

```
lib/
├── main.dart                    # Entry point aplikasi
├── config/                      # Konfigurasi
│   ├── firebaseOptions.dart    # Firebase configuration
│   ├── apiKeys.dart            # API keys (gitignored)
│   └── apiKeys.dart.example    # Template API keys
│
├── features/                    # Fitur utama aplikasi
│   ├── meal/                   # 🍽️ Fitur rekomendasi makanan
│   │   ├── mealPage.dart       # Meal recommendation screen
│   │   ├── cartPage.dart       # Shopping cart
│   │   ├── foodDetailPopup.dart # Detail popup makanan
│   │   ├── filterPopup.dart    # Filter tags popup
│   │   └── mealRecommendationEngine.dart # Recommendation algorithm
│   │
│   ├── profile/                # 👤 Fitur profil
│   │   └── profilePage.dart    # Profile management
│   │
│   ├── report/                 # 📊 Fitur laporan
│   │   └── reportPage.dart     # Nutrition reports & analytics
│   │
│   └── schedule/               # 📅 Fitur jadwal
│       └── schedulePage.dart   # Meal schedule management
│
├── pages/                       # Halaman aplikasi
│   ├── auth/                   # Authentication pages
│   │   ├── welcomePage.dart
│   │   ├── loginPage.dart
│   │   ├── registerPage.dart
│   │   ├── termsAndConditionsPage.dart
│   │   └── termsAndConditionsDetailPage.dart
│   │
│   ├── main/                   # Main app pages
│   │   └── homePage.dart       # 🏠 Home dashboard
│   │
│   └── onboarding/             # Onboarding flow (14 pages)
│       ├── onboardingHelpers.dart
│       ├── nameInputPage.dart
│       ├── sexPage.dart
│       ├── birthDatePage.dart
│       ├── heightInputPage.dart
│       ├── weightInputPage.dart
│       ├── targetSelectionPage.dart
│       ├── targetWeightInputPage.dart
│       ├── healthGoalPage.dart
│       ├── dailyActivityPage.dart
│       ├── sleepSchedulePage.dart
│       ├── eatFrequencyPage.dart
│       ├── allergyPage.dart
│       ├── challengePage.dart
│       └── summaryPage.dart
│
├── models/                      # Data models
│   ├── mealModels.dart
│   └── userProfileDraft.dart
│
├── services/                    # Business logic & API services
│   ├── geminiService.dart      # Gemini AI integration
│   ├── orderService.dart       # Order management
│   ├── scheduleService.dart    # Schedule management
│   ├── recommendationCacheService.dart  # Cache management
│   ├── imageService.dart       # Image loading service
│   └── firebaseService.dart    # Firebase operations
│
├── utils/                       # Helper utilities
│   ├── storageHelper.dart      # Firebase Storage helper
│   └── mealScheduleStorage.dart # Local storage helper
│
└── widgets/                     # Reusable widgets
    ├── customNavbar.dart       # Bottom navigation bar
    └── nutriAI.dart            # 🤖 NutriAI Chatbot
```

---

## 🗄️ Database Structure (Firestore)

### Collections

#### `users/{userId}`
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "profile": {
    "sex": "Laki-laki",
    "birthDate": Timestamp,
    "heightCm": 170,
    "weightKg": 70,
    "targetWeightKg": 65,
    "target": "Menurunkan berat badan",
    "allergies": ["Seafood", "Udang"],
    "activityLevel": "lightly_active",
    "eatFrequency": 3,
    "profilePicture": "assets/images/avatars/Male Avatar.png"
  }
}
```

#### `menus/{menuId}`
```json
{
  "id": 1001,
  "name": "Ayam Bakar Klaten...",
  "description": "Nikmati sajian...",
  "image": "1001.png",
  "calories": 469,
  "protein": 29,
  "carbohydrate": 43,
  "fat": 13,
  "price": 47000,
  "tags": ["Ayam", "Tahu", "Nasi"],
  "type": "Sarapan"
}
```

#### `food_logs/{userId}/logs/{date}`
```json
{
  "date": "2025-11-24",
  "logs": [
    {
      "timestamp": Timestamp,
      "foodDescription": "Nasi goreng + telur",
      "totalCalories": 450,
      "totalProtein": 15,
      "totalCarbohydrate": 60,
      "totalFat": 12,
      "items": [...],
      "mealType": "Sarapan"
    }
  ]
}
```

---

## 🎨 Assets Organization

```
assets/
├── fonts/                      # Custom fonts
└── images/
    ├── allergies/             # Ikon alergi makanan
    │   ├── Beef.png
    │   ├── Chicken.png
    │   ├── Fish.png
    │   ├── Seafood.png
    │   └── Shrimp.png
    │
    ├── avatars/               # Avatar default
    │   ├── Female Avatar.png
    │   └── Male Avatar.png
    │
    ├── logos/                 # Logo aplikasi
    │   ├── Logo Google.png
    │   ├── Logo HealthyGo.png
    │   └── Logo NutriLink.png
    │
    └── illustrations/         # Ilustrasi UI
        ├── Data Privacy Illustration.png
        └── Login Illustration.png
```

---

## 🔐 Keamanan dan Privacy

- **Firebase Authentication**: Login aman dengan email/password dan Google Sign-In
- **Firestore Security Rules**: Proteksi data user dengan rules yang ketat
- **Data Privacy**: Data user terenkripsi dan tersimpan aman di Firebase
- **GDPR Compliant**: User bisa hapus akun dan semua data terkait

---

## 🐛 Troubleshooting

### Build Error: Google Services
```bash
# Pastikan google-services.json sudah ada di android/app/
flutter clean
flutter pub get
flutter run
```

### Cache Issues
```bash
# Clear cache dan rebuild
flutter clean
flutter pub cache repair
flutter pub get
```

### Image Loading Issues
- Pastikan semua path image menggunakan struktur folder baru
- Check Firebase Storage rules untuk public access

---

## 👥 Tim Pengembang

- **Muhammad Iqbal Baiduri Yamani (5026221103)**
- **Dicky Febri Primadhani (5026221036)**
- **Yeremia Maydinata Narana (5026221068)**
- **Baringga Aurico De Erwada (5026221133)**
- **Airlangga Bayu Taqwa (5026221204)**


---

## 📄 Lisensi

Project ini dibuat untuk keperluan akademik (SI Capstone Project).

---

## 📞 Kontak & Support

Untuk pertanyaan atau dukungan, hubungi:
- GitHub: [@dinalarcode](https://github.com/dinalarcode)
- Repository: [CAPS-2-2025](https://github.com/dinalarcode/CAPS-2-2025)

---

**NutriLink x HealthyGo** - Smart Nutrition Assistant 🥗✨









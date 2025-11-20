# 🤖 AI Calorie Tracker - Setup Guide

## Overview
Fitur AI Calorie Tracker menggunakan **Gemini API** dari Google untuk membantu user mengestimasi kalori makanan yang dimakan di luar aplikasi.

## Features
- ✅ Estimasi kalori dengan AI (Gemini Pro)
- ✅ Support bahasa Indonesia dan makanan lokal
- ✅ Breakdown nutrisi (protein, karbohidrat, lemak)
- ✅ Auto save ke daily food logs
- ✅ Chat interface yang user-friendly
- ✅ Free tier (60 requests/minute)

## Setup Instructions

### 1. Get Gemini API Key (FREE)

1. **Buka Google AI Studio**
   - Kunjungi: https://aistudio.google.com/
   - Login dengan Google Account

2. **Generate API Key**
   - Klik "Get API Key" di sidebar
   - Klik "Create API Key"
   - Pilih project atau buat project baru
   - Copy API key yang dihasilkan

3. **Add to Project**
   - Buka file: `lib/services/gemini_service.dart`
   - Cari baris:
     ```dart
     static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
     ```
   - Replace dengan API key kamu:
     ```dart
     static const String _apiKey = 'AIzaSyC...your-actual-key...';
     ```

### 2. Install Dependencies

Sudah otomatis ditambahkan di `pubspec.yaml`:
```yaml
google_generative_ai: ^0.4.6
```

Jalankan:
```bash
flutter pub get
```

### 3. Test the Feature

1. Run aplikasi:
   ```bash
   flutter run
   ```

2. Di homepage, klik tombol **"AI Kalori"** (floating action button)

3. Test dengan input seperti:
   - "Aku makan nasi goreng + telur ceplok"
   - "2 potong ayam goreng sama es teh manis"
   - "Satu porsi soto ayam dengan nasi"

4. AI akan memberikan estimasi kalori + breakdown nutrisi

5. Klik tombol **"Simpan ke Log Harian"** untuk save ke Firestore

## How It Works

### 1. User Input
User mendeskripsikan makanan dalam bahasa Indonesia melalui chat interface.

### 2. AI Processing
Gemini AI akan:
- Identifikasi semua item makanan
- Estimasi kalori per item (menggunakan porsi standar Indonesia)
- Berikan breakdown nutrisi (protein, carbs, fats)
- Total kalori keseluruhan

### 3. Data Saving
Data disimpan ke Firestore di collection:
```
daily_food_logs/
  {uid}/
    logs/
      {date}/
        meals: [
          {
            description: "nasi goreng + telur",
            calories: 540,
            items: [...],
            time: "13:45",
            source: "ai_chatbot"
          }
        ]
        totalCalories: 540
```

### 4. Integration
Otomatis terintegrasi dengan:
- Daily calorie tracking
- Report page
- Target TDEE calculation

## API Limits (Free Tier)

- **Requests**: 60 per minute
- **Model**: gemini-pro (text-only)
- **Cost**: FREE
- **Daily limit**: Tidak ada hard limit, rate limited aja

**Note**: Untuk usage normal user (5-10 request per hari), free tier lebih dari cukup!

## Prompting Strategy

Service menggunakan smart prompting untuk:
1. **Porsi Indonesia**: Mengenali ukuran porsi standar Indonesia
   - 1 piring nasi = 175g
   - 1 potong ayam = 100g
   - Dll.

2. **Makanan Lokal**: Optimized untuk makanan Indonesia
   - Nasi goreng, soto, rendang, gado-gado, dll.

3. **Multiple Items**: Bisa detect multiple items dalam satu input
   - "nasi + ayam + sayur" → breakdown per item

4. **Range Estimates**: Jika tidak pasti, berikan range
   - "400-500 kcal" untuk porsi medium

## File Structure

```
lib/
  services/
    gemini_service.dart        # Core AI service
  widgets/
    calorie_chatbot.dart       # Chat UI widget
  homePage.dart                # Integration (FAB)
  main.dart                    # Initialization
```

## Troubleshooting

### Error: "API key not valid"
- Pastikan API key sudah di-paste dengan benar
- Jangan ada spasi atau newline
- Pastikan tidak expired

### Error: "Quota exceeded"
- Free tier: 60 requests/minute
- Tunggu 1 menit lalu coba lagi
- Atau upgrade ke paid tier (optional)

### AI Response Tidak Akurat
- Prompt engineering bisa di-improve di `gemini_service.dart`
- Tambahkan contoh makanan di prompt
- Sesuaikan porsi standar jika perlu

### Tidak Bisa Save ke Firestore
- Check Firebase rules
- Pastikan user sudah authenticated
- Check collection name: `daily_food_logs`

## Future Improvements

Potential enhancements:
1. **Photo Upload**: Upload foto makanan → AI recognize
2. **Voice Input**: Speak makanan → auto transcribe
3. **History**: Simpan riwayat estimasi per user
4. **Favorites**: Save frequent foods untuk quick add
5. **Barcode Scan**: Scan packaged food barcode

## Security Notes

⚠️ **IMPORTANT**:
- API key di-hardcode untuk development
- Untuk production, gunakan environment variables atau Firebase Functions
- JANGAN commit API key ke public repository

Recommended for production:
```dart
// Use environment variable
static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
```

Run with:
```bash
flutter run --dart-define=GEMINI_API_KEY=your-key-here
```

## Support

Jika ada masalah:
1. Check API key validity
2. Check internet connection
3. Check Firestore rules
4. Check logs di debug console

## Credits

- **AI Model**: Google Gemini Pro
- **API**: Google AI Studio (Free Tier)
- **Integration**: NutriLink Team

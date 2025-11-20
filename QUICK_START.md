# 🎯 Quick Start - AI Calorie Tracker

## ⚡ Setup (5 Menit)

### Step 1: Dapatkan API Key
1. Buka: https://aistudio.google.com/
2. Login dengan Google
3. Klik **"Get API Key"** → **"Create API Key"**
4. Copy API key yang muncul

### Step 2: Pasang API Key
1. Buka file: `lib/services/gemini_service.dart`
2. Line 10, ganti:
   ```dart
   static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```
   Menjadi:
   ```dart
   static const String _apiKey = 'AIzaSy...'; // API key kamu
   ```
3. Save file

### Step 3: Test
1. Run app: `flutter run`
2. Di homepage, klik tombol **"AI Kalori"** (kanan bawah)
3. Ketik: "aku makan nasi goreng"
4. Lihat estimasi kalori dari AI
5. Klik **"Simpan ke Log Harian"**

## ✨ Fitur

### What It Does
- 💬 Chat dengan AI untuk estimasi kalori
- 🍜 Support makanan Indonesia
- 📊 Breakdown nutrisi (protein, carbs, fats)
- 💾 Auto save ke daily logs
- 📈 Integrasi dengan report page

### Contoh Input
```
"Aku makan nasi goreng + telur ceplok"
"2 potong ayam goreng"
"Satu porsi soto ayam"
"Mie ayam + es teh manis"
```

### AI Response
```
📊 Estimasi Kalori

• Nasi goreng: 450 kcal
  P: 12g | C: 65g | F: 15g

• Telur ceplok: 90 kcal
  P: 7g | C: 1g | F: 6g

Total: 540 kcal
```

## 📂 File Changes

### New Files
- `lib/services/gemini_service.dart` - AI service
- `lib/widgets/calorie_chatbot.dart` - Chat UI
- `AI_CALORIE_TRACKER_SETUP.md` - Full documentation
- `QUICK_START.md` - This file

### Modified Files
- `pubspec.yaml` - Added google_generative_ai package
- `lib/main.dart` - Initialize GeminiService
- `lib/homePage.dart` - Added FAB button

## 🔒 Security Note

⚠️ API key di-hardcode untuk development. Untuk production:
1. Jangan commit API key ke GitHub
2. Gunakan environment variables
3. Atau simpan di Firebase Remote Config

## 📱 UI Location

**Homepage** → Floating Action Button (FAB) kanan bawah → **"AI Kalori"**

## 💡 Tips

1. **Describe dengan detail**: Semakin detail input, semakin akurat estimasi
2. **Multiple items**: Bisa input beberapa makanan sekaligus
3. **Bahasa Indonesia**: AI dioptimalkan untuk bahasa Indonesia
4. **Porsi**: Sebutkan porsi kalau bisa (1 piring, 2 potong, dll)

## ⚙️ Free Tier Info

- **Model**: Gemini Pro
- **Cost**: FREE ✅
- **Limit**: 60 requests/minute
- **Cukup untuk**: 100+ queries per hari

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| API key invalid | Re-check API key, pastikan tidak ada spasi |
| Quota exceeded | Tunggu 1 menit, free tier: 60/min |
| Tidak bisa save | Check Firebase auth & rules |
| AI tidak akurat | Edit prompt di gemini_service.dart |

## 📞 Need Help?

Read: `AI_CALORIE_TRACKER_SETUP.md` untuk dokumentasi lengkap

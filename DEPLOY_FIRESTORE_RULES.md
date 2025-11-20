# 🔒 Deploy Firestore Security Rules

## Masalah yang Diperbaiki
1. ❌ **Permission denied** untuk `ai_chat_history` dan `daily_food_logs`
2. ✅ **Judul log makanan** sekarang menggunakan AI untuk generate judul cerdas
3. ✅ **Welcome message** sekarang muncul langsung saat pertama buka chatbot

## Cara Deploy Firestore Rules

### Option 1: Via Firebase Console (RECOMMENDED)
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project: **CAPS-2-2025**
3. Klik **Firestore Database** di menu kiri
4. Klik tab **Rules**
5. Copy-paste rules dari file `firestore.rules` di folder project
6. Klik **Publish**

### Option 2: Via Firebase CLI (jika sudah install)
```bash
# Install Firebase CLI (jika belum)
npm install -g firebase-tools

# Login
firebase login

# Deploy rules
firebase deploy --only firestore:rules
```

## Rules Baru yang Ditambahkan

```javascript
// AI Chat History - allow read/write for authenticated users to their own data
match /ai_chat_history/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// Daily Food Logs - allow read/write for authenticated users to their own data
match /daily_food_logs/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// Schedule collection - allow read/write for authenticated users to their own data
match /schedule/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## Perubahan pada Kode

### 1. Judul Log Makanan Lebih Cerdas
**Sebelum:**
- Judul: "aku makan nasi goreng sama telur ceplok" (langsung input user)

**Sesudah:**
- 1 item: "Nasi goreng"
- 2 items: "Nasi goreng dan Telur ceplok"
- 3+ items: "Nasi goreng, Telur ceplok, +2 lainnya"

### 2. Welcome Message Fix
**Masalah:** Welcome message tidak muncul saat pertama buka chatbot

**Solusi:** Welcome message sekarang ditampilkan langsung, baru kemudian di-replace dengan chat history jika ada

### 3. Chat History Persistence
Chat history sekarang disimpan per hari di:
```
ai_chat_history/{userId}/chats/{yyyy-MM-dd}/
```

## Testing

### Test 1: Chat History
1. Buka chatbot
2. ✅ Welcome message langsung muncul
3. Chat dengan AI tentang makanan
4. Tutup app
5. Buka lagi chatbot
6. ✅ Chat history tetap ada

### Test 2: Food Log Title
1. Chat: "aku makan nasi goreng sama telur ceplok"
2. Klik "Simpan ke Log Harian"
3. Lihat di homepage "Log Makanan Hari Ini"
4. ✅ Judulnya: "Nasi goreng dan Telur ceplok" (bukan input user mentah)

### Test 3: Permission
1. ✅ Tidak ada error "permission-denied" lagi
2. ✅ Chat history tersimpan
3. ✅ Food logs tersimpan

## Troubleshooting

### Masih dapat "permission-denied"?
- Pastikan Firestore rules sudah di-deploy
- Coba logout dan login ulang di app
- Clear app data dan login ulang

### Welcome message masih tidak muncul?
- Hot reload: `r` di terminal
- Hot restart: `R` di terminal  
- Full rebuild: Stop app dan `flutter run` lagi

### Judul log masih menampilkan input user?
- Pastikan sudah hot reload/restart setelah perubahan code
- Check apakah `GeminiService.generateFoodTitle()` dipanggil dengan benar

## Status
- ✅ Code updated
- ⏳ Firestore rules perlu di-deploy manual via Firebase Console
- ✅ Ready untuk testing setelah rules di-deploy

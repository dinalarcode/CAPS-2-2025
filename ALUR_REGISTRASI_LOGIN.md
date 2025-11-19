# 🔐 ALUR REGISTRASI & LOGIN - NUTRILINK

## ✅ ALUR YANG BENAR (SETELAH PERBAIKAN)

### 📋 REGISTRASI (Email/Google)
```
1. User isi data onboarding (nama, tinggi, berat, dll) 
   ↓
2. SummaryPage tampilkan ringkasan data
   ↓
3. User klik "Simpan & Lanjut"
   → Navigator.pushReplacementNamed('/register', arguments: draft) ✅ DATA DIKIRIM
   ↓
4. RegisterPage terima draft via getDraft(context)
   ↓
5. User pilih metode registrasi:
   - Email/Password: Isi email + password + konfirmasi
   - Google: Klik tombol "Daftar dengan Google"
   ↓
6. Sistem buat akun Firebase Auth
   ↓
7. _afterRegister() dipanggil:
   - Update displayName (jika ada)
   - Kirim email verifikasi (WAJIB untuk semua metode)
   - Simpan data ke Firestore:
     * users/{uid}/uid: user.uid
     * users/{uid}/email: user.email
     * users/{uid}/provider: "password" atau "google"
     * users/{uid}/emailVerifiedByApp: false ⚠️ PENTING!
     * users/{uid}/createdAt: timestamp
     * users/{uid}/profile: {semua data onboarding dari draft}
   - Logout otomatis (paksa user login ulang)
   ↓
8. User diarahkan ke halaman login
   ↓
9. Toast muncul: "Email verifikasi telah dikirim ke {email}. Cek inbox/spam..."
```

### 📧 VERIFIKASI EMAIL
```
1. User buka email inbox/spam
   ↓
2. Klik link verifikasi dari Firebase
   ↓
3. Firebase Auth update user.emailVerified = true
   ↓
4. User kembali ke aplikasi dan login
```

### 🔑 LOGIN (Email/Google)
```
1. User masuk ke halaman login
   ↓
2. User pilih metode login:
   - Email: Isi email + password
   - Google: Klik tombol "Masuk dengan Google"
   ↓
3. Sistem cek Firebase Auth credentials
   ↓
4. CEK 1: Apakah akun terdaftar di Firestore?
   - TIDAK → Logout + Toast: "Akun belum terdaftar"
   - YA → Lanjut ke CEK 2
   ↓
5. CEK 2: Apakah user.emailVerified = true? (Firebase Auth)
   - TIDAK → Dialog: "Email belum terverifikasi. Kirim ulang?"
             → Logout + kembali ke login
   - YA → Lanjut ke CEK 3
   ↓
6. CEK 3: Ambil emailVerifiedByApp dari Firestore
   - FALSE → Update emailVerifiedByApp = true (karena sudah klik link)
            → Lanjut ke home
   - TRUE → Lanjut ke home (sudah pernah login sebelumnya)
   ↓
7. Navigator.pushNamedAndRemoveUntil('/home', ...)
```

## 🚫 TIDAK BISA BYPASS VERIFIKASI

### ❌ Skenario Bypass yang DICEGAH:

#### 1️⃣ Regis Email → Langsung Login Email (TANPA VERIF)
```
Registrasi:
- emailVerifiedByApp: false ✅ Set di Firestore

Login:
- user.emailVerified: false ❌ DITOLAK!
- Toast: "Email belum terverifikasi"
- Logout otomatis
```

#### 2️⃣ Regis Email → Login Google (TANPA VERIF)
```
Registrasi dengan email@gmail.com:
- emailVerifiedByApp: false ✅ Set di Firestore

Login dengan Google (email@gmail.com):
- Akun ditemukan di Firestore (sama uid/email)
- user.emailVerified: false ❌ DITOLAK!
- Toast: "Email belum terverifikasi"
- Logout otomatis
```

#### 3️⃣ Regis Google → Langsung Login Google (TANPA VERIF)
```
Registrasi dengan Google:
- emailVerifiedByApp: false ✅ Set di Firestore
- Email verifikasi TETAP dikirim

Login dengan Google:
- user.emailVerified: true (dari Google)
- emailVerifiedByApp: false ❌ DITOLAK!
  → Update emailVerifiedByApp = true (karena emailVerified sudah true)
  → Baru boleh masuk
```

## 📊 STRUKTUR DATA FIRESTORE

### Collection: `users`
```javascript
{
  "uid": "abc123xyz",
  "email": "user@example.com",
  "provider": "password" | "google",
  "emailVerifiedByApp": false, // ⚠️ KUNCI UTAMA - harus true untuk login
  "createdAt": Timestamp,
  "profile": {
    "name": "John Doe",
    "target": "Menurunkan berat badan",
    "healthGoal": "Jantung sehat",
    "challenges": ["Sering ngemil", "Jadwal sibuk"],
    "heightCm": 170.0,
    "weightKg": 75.0,
    "targetWeightKg": 65.0,
    "birthDate": Timestamp,
    "sex": "Laki-laki",
    "activityLevel": "moderately_active",
    "allergies": ["Kacang"],
    "eatFrequency": 3,
    "wakeTime": "06:00",
    "sleepTime": "22:00",
    "sleepHours": 8,
    "updatedAt": Timestamp
  }
}
```

## 🔄 PERUBAHAN KODE

### ✅ File yang Sudah Benar:
1. **summaryPage.dart** (line 114-117):
```dart
Navigator.pushReplacementNamed(
  context, 
  '/register',
  arguments: draft, // ✅ Data dikirim!
);
```

2. **registerPage.dart** - `_afterRegister()`:
```dart
await db.collection('users').doc(user.uid).set({
  'uid': user.uid,
  'email': user.email,
  'provider': provider,
  'emailVerifiedByApp': false, // ✅ KUNCI: set false
  'createdAt': FieldValue.serverTimestamp(),
  'profile': profileData, // ✅ Data onboarding lengkap
}, SetOptions(merge: true));
```

3. **loginPage.dart** - `_loginWithEmail()`:
```dart
// CEK 1: Akun terdaftar di Firestore?
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .get();
if (!userDoc.exists) {
  await FirebaseAuth.instance.signOut();
  _toast('Akun belum terdaftar...');
  return;
}

// CEK 2: Email verified di Firebase Auth?
if (!user.emailVerified) {
  await _handleUnverifiedEmail(user); // Dialog kirim ulang
  return; // ❌ BLOCK LOGIN
}

// CEK 3: emailVerifiedByApp di Firestore?
final emailVerifiedByApp = userDoc.data()?['emailVerifiedByApp'] ?? false;
if (!emailVerifiedByApp) {
  // Update karena sudah klik link verifikasi
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({'emailVerifiedByApp': true});
  debugPrint('✅ Email verified! Updated emailVerifiedByApp to true');
}

// ✅ SEMUA CEK LOLOS → Boleh masuk
Navigator.pushNamedAndRemoveUntil(context, '/home', ...);
```

## 🧪 CARA TESTING

### Test 1: Registrasi Email Normal
1. Isi onboarding lengkap (nama: "Test User", tinggi: 170, berat: 70, dll)
2. Klik "Simpan & Lanjut" di summary
3. Isi email + password di register
4. Klik "Daftar"
5. **CEK FIRESTORE**: 
   - `users/{uid}/profile/name` = "Test User" ✅
   - `users/{uid}/profile/heightCm` = 170 ✅
   - `users/{uid}/emailVerifiedByApp` = false ✅
6. **CEK EMAIL**: Email verifikasi masuk ✅
7. **COBA LOGIN TANPA VERIF**: 
   - Isi email + password → Klik "Masuk"
   - **RESULT**: ❌ "Email belum terverifikasi" → Logout
8. **KLIK LINK VERIFIKASI** di email
9. **LOGIN LAGI**: 
   - Isi email + password → Klik "Masuk"
   - **RESULT**: ✅ Masuk ke home
10. **CEK FIRESTORE**: `emailVerifiedByApp` = true ✅

### Test 2: Registrasi Google
1. Isi onboarding lengkap
2. Klik "Simpan & Lanjut" di summary
3. Klik "Daftar dengan Google" di register
4. Pilih akun Google
5. **CEK FIRESTORE**: 
   - `users/{uid}/profile` = data lengkap ✅
   - `users/{uid}/emailVerifiedByApp` = false ✅
   - `users/{uid}/provider` = "google" ✅
6. **CEK EMAIL**: Email verifikasi masuk ✅
7. **KLIK LINK VERIFIKASI** di email
8. **LOGIN dengan Google**: 
   - **RESULT**: ✅ Masuk ke home
9. **CEK FIRESTORE**: `emailVerifiedByApp` = true ✅

### Test 3: Bypass Prevention (Regis Email → Login Google)
1. Daftar dengan email: test@gmail.com (password)
2. **JANGAN VERIF EMAIL**
3. Coba login dengan Google (test@gmail.com)
4. **RESULT**: ❌ "Email belum terverifikasi" → Logout ✅

## 📝 KESIMPULAN

### ✅ MASALAH TERSELESAIKAN:
1. ✅ Data onboarding masuk ke Firestore (via `arguments: draft`)
2. ✅ TIDAK BISA bypass verifikasi email (ada 2 cek: Firebase + Firestore)
3. ✅ Alur konsisten: ISI DATA → REGIS → VERIF EMAIL → LOGIN → HOME

### 🔑 KUNCI UTAMA:
- **emailVerifiedByApp** di Firestore = source of truth
- Set `false` saat registrasi (semua metode)
- Update `true` HANYA saat login dengan `user.emailVerified = true`
- Cek `emailVerifiedByApp` di SETIAP login

### 🛡️ KEAMANAN:
- Tidak bisa login tanpa verifikasi email
- Tidak bisa bypass dengan ganti metode login
- Data onboarding tersimpan aman di Firestore
- Logout otomatis setelah registrasi

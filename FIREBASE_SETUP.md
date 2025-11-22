# 🔥 Firebase Firestore Setup Guide

## 📋 Firestore Security Rules

Buka **Firebase Console** → **Firestore Database** → **Rules**, lalu paste konfigurasi ini:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ==========================================
    // 🔐 USERS COLLECTION
    // ==========================================
    match /users/{userId} {
      // User hanya bisa akses data mereka sendiri
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Subcollection: profile
      match /profile/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Subcollection: orders (pesanan makanan)
      match /orders/{orderId} {
        allow create: if request.auth != null && request.auth.uid == userId;
        allow read: if request.auth != null && request.auth.uid == userId;
        allow update: if request.auth != null && request.auth.uid == userId;
        allow delete: if request.auth != null && request.auth.uid == userId;
      }
      
      // Subcollection: schedule (jadwal makan)
      match /schedule/{date} {
        allow create: if request.auth != null && request.auth.uid == userId;
        allow read: if request.auth != null && request.auth.uid == userId;
        allow update: if request.auth != null && request.auth.uid == userId;
        allow delete: if request.auth != null && request.auth.uid == userId;
      }
      
      // Subcollection: recommendationCache (cache hasil filtering)
      match /recommendationCache/{document} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // ==========================================
    // 📋 MENUS COLLECTION (Read-only)
    // ==========================================
    match /menus/{menuId} {
      // Semua user bisa baca menu
      allow read: if request.auth != null;
      // Hanya admin yang bisa write (via Firebase Console)
      allow write: if false;
    }
    
    // ==========================================
    // 🚫 DENY ALL OTHER ACCESS
    // ==========================================
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 🗂️ Firestore Database Structure

Struktur database akan otomatis terbuat saat user pertama kali checkout. Berikut struktur lengkapnya:

```
📦 nutrilink-5f07f (Firebase Project)
└── 🗄️ Firestore Database
    ├── 📁 users/
    │   └── {userId}/
    │       ├── 📁 profile/
    │       │   └── {profileData}
    │       │
    │       ├── 📁 orders/
    │       │   └── {orderId}/
    │       │       ├── orderId: "ORD-20251121-123456"
    │       │       ├── status: "pending" | "paid" | "preparing" | "delivered" | "cancelled"
    │       │       ├── totalPrice: 156000
    │       │       ├── createdAt: Timestamp
    │       │       ├── updatedAt: Timestamp
    │       │       ├── paymentMethod: "pending" | "gopay" | "ovo" | "bank_transfer"
    │       │       └── items: [
    │       │           {
    │       │             date: "2025-11-21",
    │       │             mealType: "Sarapan",
    │       │             name: "Nasi Goreng",
    │       │             price: 45500,
    │       │             calories: 450,
    │       │             protein: "25g",
    │       │             carbs: "55g",
    │       │             fat: "18g",
    │       │             image: "gs://...",
    │       │             clock: "06:30 - 07:00"
    │       │           },
    │       │           ...
    │       │       ]
    │       │
    │       └── 📁 schedule/
    │           └── {date}/ (format: yyyy-MM-dd)
    │               ├── meals: [
    │               │   {
    │               │     orderId: "ORD-20251121-123456",
    │               │     name: "Nasi Goreng",
    │               │     time: "Sarapan",
    │               │     clock: "06:30 - 07:00",
    │               │     calories: 450,
    │               │     protein: "25g",
    │               │     carbs: "55g",
    │               │     fat: "18g",
    │               │     image: "gs://...",
    │               │     isDone: false
    │               │   },
    │               │   ...
    │               │]
    │               └── updatedAt: Timestamp
    │
    └── 📁 menus/ (existing)
        └── {menuId}/
            └── {menuData}
```

---

## 🚀 Langkah-Langkah Setup

### 1️⃣ **Update Firestore Rules**
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project: **nutrilink-5f07f**
3. Klik **Firestore Database** di menu kiri
4. Klik tab **Rules**
5. Copy-paste rules di atas
6. Klik **Publish**

### 2️⃣ **Verifikasi Database Structure** (Opsional)
Database akan otomatis terbuat saat user checkout. Tapi kamu bisa verifikasi:

1. Buka tab **Data**
2. Pastikan collection `users` ada
3. Setelah checkout pertama, cek apakah subcollection `orders` dan `schedule` terbuat

### 3️⃣ **Testing Flow**
1. Login ke aplikasi
2. Tambah makanan ke cart dari recommendation page
3. Klik **Checkout**
4. Tunggu loading (create order + populate schedule)
5. Cek Firebase Console → Firestore Database → users/{yourUserId}/orders
6. Cek juga users/{yourUserId}/schedule/{date}

---

## ✅ Checklist Setup

- [ ] Firestore Rules sudah di-publish
- [ ] User bisa login
- [ ] User bisa checkout dari cart
- [ ] Order tercreate di Firestore (cek di Console)
- [ ] Schedule terisi otomatis setelah checkout
- [ ] Schedule page menampilkan meals yang sudah dipesan
- [ ] Checklist isDone bisa diupdate

---

## 🔍 Troubleshooting

### Error: "Missing or insufficient permissions"
**Solusi:** Pastikan Firestore Rules sudah di-publish dengan benar.

### Schedule kosong setelah checkout
**Solusi:** 
1. Cek Firebase Console apakah order tercreate
2. Cek log di debug console untuk error messages
3. Refresh schedule page dengan tombol refresh

### Image tidak muncul di schedule
**Solusi:** Pastikan Firebase Storage rules allow read:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /menus/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

---

## 📊 Monitoring

Setelah setup, kamu bisa monitor:
1. **Usage:** Firestore Database → Usage tab
2. **Requests:** Monitor jumlah read/write requests
3. **Errors:** Debug console untuk error logs

---

## 🎯 Next Steps (Future Enhancements)

1. **Payment Gateway Integration**
   - Integrate Midtrans/Xendit untuk real payment
   - Update order status berdasarkan payment callback

2. **Order History Page**
   - Tampilkan semua order user
   - Filter by status (pending, paid, delivered)

3. **Push Notifications**
   - Notif saat order confirmed
   - Reminder untuk makan sesuai schedule

4. **Admin Dashboard**
   - Monitor semua orders
   - Update order status (preparing, delivered)

---

**✨ Setup Complete! Database siap digunakan.**

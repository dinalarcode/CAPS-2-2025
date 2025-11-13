import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrilink/models/user_profile_draft.dart'; // Pastikan ini diimpor

class RegisterPage extends StatefulWidget {
  // Tambahkan properti draft ke constructor
  final UserProfileDraft? draft;
  const RegisterPage({super.key, this.draft});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // Helper untuk mengkonversi UserProfileDraft ke Map
  Map<String, dynamic> _getProfileDataFromDraft(UserProfileDraft draft) {
    // Pastikan konversi ini sama dengan yang dilakukan di SummaryPage
    Timestamp? birthDateTimestamp = draft.birthDate != null 
        ? Timestamp.fromDate(draft.birthDate!) 
        : null;

    return {
      'name': draft.name ?? '',
      'target': draft.target ?? '',
      'healthGoal': draft.healthGoal ?? '',
      'challenges': draft.challenges ?? [], 
      'heightCm': draft.heightCm,
      'weightKg': draft.weightKg,
      'targetWeightKg': draft.targetWeightKg,
      'birthDate': birthDateTimestamp, 
      'sex': draft.sex ?? '',
      'activityLevel': draft.activityLevel ?? '',
      'allergies': draft.allergies ?? [],
      'eatFrequency': draft.eatFrequency,
      'sleepHours': draft.sleepHours,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isProfileComplete': true, // Tandai bahwa onboarding selesai
    };
  }
  
  // Fungsi utama untuk melakukan registrasi dan menyimpan data
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    UserCredential? userCredential;
    try {
      // 1. AUTENTIKASI: Buat akun di Firebase Auth
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // --- TAMBAHAN PENTING ---
        // A. Kirim email verifikasi
        await user.sendEmailVerification(); 
        
        // B. Simpan data profil hanya jika draft ada
        if (widget.draft != null) {
          // 2. FIRESTORE: Simpan data profil menggunakan UID pengguna
          final profileData = _getProfileDataFromDraft(widget.draft!);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              // Simpan profile data dalam sub-field 'profile'
              .set({'profile': profileData, 'uid': user.uid}, SetOptions(merge: true));
        }
      }

      if (!mounted) return;
      
      // Mengubah pesan sukses untuk mencakup informasi verifikasi email
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Email verifikasi telah dikirim. Silakan Masuk.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Setelah sukses, arahkan pengguna ke halaman Login
      Navigator.pushReplacementNamed(context, '/login');

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      if (e.code == 'weak-password') {
        message = 'Password terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Akun sudah terdaftar untuk email ini.';
      } else {
        message = 'Gagal mendaftar: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      debugPrint('Error registrasi: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan yang tidak diketahui saat menyimpan data.')),
      );
      // Opsional: Anda dapat mencoba menghapus user yang baru dibuat 
      // jika penyimpanan data ke Firestore gagal, tetapi ini rumit.
      
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigasi ke halaman Login
  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A994E); 
    const grayButtonColor = Color(0xFFC0C0C0);

    // Cek apakah data draft diterima
    if (widget.draft == null) {
       // Tampilkan pesan error jika data onboarding hilang
       return Scaffold(
         appBar: AppBar(title: const Text('Error')),
         body: const Center(
           child: Text(
             'Data onboarding hilang. Harap mulai proses dari awal.',
             textAlign: TextAlign.center,
             style: TextStyle(color: Colors.red),
           ),
         ),
       );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        automaticallyImplyLeading: false, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), 
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 18, color: Colors.black),
                  children: [
                    TextSpan(text: 'Silahkan daftar dengan '),
                    TextSpan(
                      text: 'akunmu.',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Input Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan email kamu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!value.contains('@')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Input Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Masukkan password kamu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Input Konfirmasi Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Masukkan password konfirmasi kamu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Teks "Sudah punya akun? Masuk"
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text.rich(
                    TextSpan(
                      text: 'Sudah punya akun? ',
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: 'Masuk',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48), // Spasi sebelum tombol

              // Tombol Utama
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: grayButtonColor, 
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Daftar', 
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
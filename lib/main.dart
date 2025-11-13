// lib/main.dart

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

// ── PAGES (pastikan file & class-nya ada) ─────────────────────────────────────
import 'package:nutrilink/welcomePage.dart' as welcome;
import 'package:nutrilink/homePage.dart' as home;
import 'package:nutrilink/loginPage.dart' as login;
import 'package:nutrilink/termsAndConditionsPage.dart' as terms;
import 'package:nutrilink/firestore_test.dart';

// Onboarding sequence (16 files total: 1 terms + 14 step + register + login)
import 'package:nutrilink/nameInputPage.dart' as name_input;
import 'package:nutrilink/targetSelectionPage.dart' as target_sel;
import 'package:nutrilink/healthGoalPage.dart' as health_goal;
import 'package:nutrilink/challengePage.dart' as challenge;
import 'package:nutrilink/heightInputPage.dart' as height_input;
import 'package:nutrilink/weightInputPage.dart' as weight_input;
import 'package:nutrilink/targetWeightInputPage.dart' as target_weight;
import 'package:nutrilink/birthDatePage.dart' as birth_date;
import 'package:nutrilink/sexPage.dart' as sex_page;
import 'package:nutrilink/dailyActivityPage.dart' as daily_activity;
import 'package:nutrilink/allergyPage.dart' as allergy_page;
import 'package:nutrilink/eatFrequencyPage.dart' as eat_freq;
import 'package:nutrilink/sleepSchedulePage.dart' as sleep_sched;
import 'package:nutrilink/registerPage.dart' as register_page;

// ── reCAPTCHA v3 (Web) ───────────────────────────────────────────────────────
const String kRecaptchaV3SiteKey = '6Lf2pQMsAAAAALiEdH2KdQ3ThKzZ2IlJQAw7HJxG';

// ── Switch App Check provider (DEV=Debug, PROD=Play Integrity) ───────────────
const bool useDebugAppCheck =
    bool.fromEnvironment('USE_DEBUG_APPCHECK', defaultValue: !kReleaseMode);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2) App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        useDebugAppCheck ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    webProvider: ReCaptchaV3Provider(kRecaptchaV3SiteKey),
  );

  // 3) Auto-refresh token
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  // 4) Warm-up token (non-fatal) — kompatibel versi lama/baru
  try {
    final dynamic t = await FirebaseAppCheck.instance.getToken(); // String? (lama) / AppCheckToken? (baru)
    String? value;
    if (t is String) {
      value = t;
    } else if (t != null) {
      try {
        // ignore: avoid_dynamic_calls
        value = (t as dynamic).token as String?;
      } catch (_) {
        value = null;
      }
    }
    if (value != null && value.isNotEmpty) {
      final preview = value.substring(0, value.length < 10 ? value.length : 10);
      debugPrint('AppCheck token preview: $preview...');
    } else {
      debugPrint('AppCheck token: null/empty (akan dicoba ulang saat request)');
    }
  } catch (e) {
    debugPrint('AppCheck warmup error: $e');
  }

  // 5) Global error handler
  FlutterError.onError = (details) => FlutterError.presentError(details);
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('UNCAUGHT PLATFORM ERROR: $error\n$stack');
    return true;
  };

  // 6) Sembunyikan system UI di mobile
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // 7) Run
  runZonedGuarded(() => runApp(const NutriLinkApp()), (e, s) {
    debugPrint('UNCAUGHT ZONE ERROR: $e\n$s');
  });
}

class NutriLinkApp extends StatelessWidget {
  const NutriLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLink x HealthyGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Funnel Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          centerTitle: true,
        ),
      ),
      // Awal aplikasi
      initialRoute: '/welcome',

      // Semua named routes
      routes: {
        '/welcome'        : (_) => const welcome.WelcomePage(),
        '/terms'          : (_) => const terms.TermsAndConditionsPage(),

        // ── Onboarding steps (sesuai urutan Figma) ──
        '/name-input'     : (_) => const name_input.NameInputPage(),
        '/target-selection': (_) => const target_sel.TargetSelectionPage(),
        '/health-goal'    : (_) => const health_goal.HealthGoalPage(),
        '/challenge'      : (_) => const challenge.ChallengePage(),
        '/height-input'   : (_) => const height_input.HeightInputPage(),
        '/weight-input'   : (_) => const weight_input.WeightInputPage(),
        '/target-weight'  : (_) => const target_weight.TargetWeightInputPage(),
        '/birth-date'     : (_) => const birth_date.BirthDatePage(),
        '/sex'            : (_) => const sex_page.SexPage(),
        '/daily-activity' : (_) => const daily_activity.DailyActivityPage(),
        '/allergy'        : (_) => const allergy_page.AllergyPage(),
        '/eat-frequency'  : (_) => const eat_freq.EatFrequencyPage(),
        '/sleep-schedule' : (_) => const sleep_sched.SleepSchedulePage(),

        // ── Auth & app ──
        '/register'       : (_) => const register_page.RegisterPage(),
        '/login'          : (_) => const login.LoginPage(),
        '/home'           : (_) => const home.HomeScreen(),

        // opsional
        '/firestore-test' : (_) => const FirestoreTestPage(),
      },
    );
  }
}

// ============== Google Sign-In util ==============
Future<UserCredential> signInWithGoogle() async {
  if (kIsWeb) {
    final provider = GoogleAuthProvider();
    return FirebaseAuth.instance.signInWithPopup(provider);
  }
  final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    throw Exception('Login dibatalkan pengguna.');
  }
  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return FirebaseAuth.instance.signInWithCredential(credential);
}

Future<void> signOutGoogle() async {
  if (!kIsWeb) {
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
  }
  await FirebaseAuth.instance.signOut();
}

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_sign_in/google_sign_in.dart'; 
import 'package:intl/date_symbol_data_local.dart'; // Import ini sudah benar

import 'firebase_options.dart';

// ── PAGES (pastikan file & class-nya ada) ─────────────────────────────────────
import 'package:nutrilink/welcomePage.dart' as welcome;
import 'package:nutrilink/homePage.dart' as home;
import 'package:nutrilink/loginPage.dart' as login;
import 'package:nutrilink/termsAndConditionsPage.dart' as terms;
import 'package:nutrilink/firestore_test.dart';

// Onboarding sequence
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
import 'package:nutrilink/summaryPage.dart' as summary_page; 
import 'package:nutrilink/registerPage.dart' as register; 

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

  // 2) App Check Activation
  await FirebaseAppCheck.instance.activate(
    // KODE ANDROID (gunakan salah satu tergantung kebutuhan)
    // providerAndroid: 
    //     useDebugAppCheck ? AndroidAppCheckProvider.debug : AndroidAppCheckProvider.playIntegrity,
    
    // PERBAIKAN NAMA PROPERTI: webProvider -> providerWeb
    providerWeb: ReCaptchaV3Provider(kRecaptchaV3SiteKey),
  );

  // 3) Auto-refresh token
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  // 4) Warm-up token (Logika dipertahankan)
  try {
    final dynamic t = await FirebaseAppCheck.instance.getToken();
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

  // 5) Global error handler (dipertahankan)
  FlutterError.onError = (details) => FlutterError.presentError(details);
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('UNCAUGHT PLATFORM ERROR: $error\n$stack');
    return true;
  };

  // 6) Sembunyikan system UI di mobile (dipertahankan)
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // ──────────────────────────────────────────────────────────────────
  // 7) PERBAIKAN UTAMA: Inisialisasi data lokal untuk DateFormat
  // Error di SummaryPage karena DateFormat('...', 'id') belum siap.
  await initializeDateFormatting('id', null);
  // ──────────────────────────────────────────────────────────────────
  

  // 8) Run App dengan zone guarding
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

      // Semua named routes (dipertahankan)
      routes: {
        '/welcome': (_) => const welcome.WelcomePage(),
        '/terms': (_) => const terms.TermsAndConditionsPage(),

        // ── Onboarding steps ──
        '/name-input': (_) => const name_input.NameInputPage(),
        '/target-selection': (_) => const target_sel.TargetSelectionPage(),
        '/health-goal': (_) => const health_goal.HealthGoalPage(),
        '/challenge': (_) => const challenge.ChallengePage(),
        '/height-input': (_) => const height_input.HeightInputPage(),
        '/weight-input': (_) => const weight_input.WeightInputPage(),
        '/target-weight': (_) => const target_weight.TargetWeightInputPage(),
        '/birth-date': (_) => const birth_date.BirthDatePage(),
        '/sex': (_) => const sex_page.SexPage(),
        '/daily-activity': (_) => const daily_activity.DailyActivityPage(),
        '/allergy': (_) => const allergy_page.AllergyPage(),
        '/eat-frequency': (_) => const eat_freq.EatFrequencyPage(),
        '/sleep-schedule': (_) => const sleep_sched.SleepSchedulePage(), 
        
        // Rute untuk Summary Page
        '/summary': (_) => const summary_page.SummaryPage(), 

        // ── Auth & app ──
        '/register': (_) => const register.RegisterPage(), 
        '/login': (_) => const login.LoginPage(),
        '/home': (_) => const home.HomePage(),

        // opsional
        '/firestore-test': (_) => const FirestoreTestPage(),
      },
    );
  }
}
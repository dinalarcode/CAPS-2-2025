import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// PAGES
import 'package:nutrilink/welcomePage.dart' as welcome;
import 'package:nutrilink/homePage.dart' as home;
import 'package:nutrilink/loginPage.dart' as login;
import 'package:nutrilink/registerPage.dart' as register;
import 'package:nutrilink/termsAndConditionsPage.dart' as terms;
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
import 'package:nutrilink/reportPage.dart' as report_page;
import 'package:nutrilink/meal/recomendation.dart' as recomendation;
import 'package:nutrilink/firestore_test.dart';

// import 'package:firebase_app_check/firebase_app_check.dart'; // Package not installed

// reCAPTCHA web
const String kRecaptchaV3SiteKey = '6Lf2pQMsAAAAALiEdH2KdQ3ThKzZ2IlJQAw7HJxG';

const bool useDebugAppCheck =
    bool.fromEnvironment('USE_DEBUG_APPCHECK', defaultValue: !kReleaseMode);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Global error handler
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('UNCAUGHT PLATFORM ERROR: $error\n$stack');
    return true;
  };

  // Sembunyikan system UI (fullscreen) di mobile
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // Firebase App Check - Commented out (package not installed)
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.playIntegrity,
  // );

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
      
      // Localization delegates untuk DatePicker Indonesia
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesia
        Locale('en', 'US'), // English
      ],
      
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

      home: const AuthGate(), // Changed: Use AuthGate instead of initialRoute

      // Semua named routes
      routes: {
        '/welcome': (_) => const welcome.WelcomePage(),
        '/terms': (_) => const terms.TermsAndConditionsPage(),
        '/login': (_) => const login.LoginPage(),
        '/register': (_) => const register.RegisterPage(),
        '/home': (_) => const home.HomePage(),

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
        '/summary': (_) => const summary_page.SummaryPage(),
        '/recommendation': (_) => const recomendation.RecommendationScreen(),
        '/report': (_) => const report_page.ReportScreen(),

        '/firestore-test': (_) => const FirestoreTestPage(),
      },
    );
  }
}

// AuthGate: Cek status login user
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF75C778),
              ),
            ),
          );
        }

        // If user is logged in, go to home
        if (snapshot.hasData && snapshot.data != null) {
          return const home.HomePage();
        }

        // If user is not logged in, go to welcome page
        return const welcome.WelcomePage();
      },
    );
  }
}
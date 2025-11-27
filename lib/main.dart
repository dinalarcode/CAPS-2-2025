// Dart
import 'dart:ui';
import 'dart:async';

// Flutter
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Config
import 'package:nutrilink/config/firebaseOptions.dart';

// Services
import 'package:nutrilink/services/geminiService.dart';
import 'package:nutrilink/services/notificationService.dart';

// Features - Meal
import 'package:nutrilink/features/meal/mealPage.dart' as meal_page;
import 'package:nutrilink/features/meal/cartPage.dart';

// Features - Report
import 'package:nutrilink/features/report/reportPage.dart' as report_page;

// Features - Profile
import 'package:nutrilink/features/profile/viewProfilePage.dart'
    as profile_view;
import 'package:nutrilink/features/profile/editProfilePage.dart'
    as profile_edit;
import 'package:nutrilink/features/profile/nutritionNeedsPage.dart'
    as profile_nutrition;
import 'package:nutrilink/features/profile/bmrCalculationPage.dart'
    as profile_bmr;

// Pages - Auth
import 'package:nutrilink/pages/auth/welcomePage.dart' as welcome;
import 'package:nutrilink/pages/auth/loginPage.dart' as login;
import 'package:nutrilink/pages/auth/registerPage.dart' as register;
import 'package:nutrilink/pages/auth/termsAndConditionsPage.dart' as terms;

// Pages - Main
import 'package:nutrilink/pages/main/homePage.dart' as home;

// Pages - Onboarding
import 'package:nutrilink/pages/onboarding/nameInputPage.dart' as name_input;
import 'package:nutrilink/pages/onboarding/sexPage.dart' as sex_page;
import 'package:nutrilink/pages/onboarding/birthDatePage.dart' as birth_date;
import 'package:nutrilink/pages/onboarding/heightInputPage.dart'
    as height_input;
import 'package:nutrilink/pages/onboarding/weightInputPage.dart'
    as weight_input;
import 'package:nutrilink/pages/onboarding/targetSelectionPage.dart'
    as target_sel;
import 'package:nutrilink/pages/onboarding/targetWeightInputPage.dart'
    as target_weight;
import 'package:nutrilink/pages/onboarding/healthGoalPage.dart' as health_goal;
import 'package:nutrilink/pages/onboarding/dailyActivityPage.dart'
    as daily_activity;
import 'package:nutrilink/pages/onboarding/sleepSchedulePage.dart'
    as sleep_sched;
import 'package:nutrilink/pages/onboarding/eatFrequencyPage.dart' as eat_freq;
import 'package:nutrilink/pages/onboarding/allergyPage.dart' as allergy_page;
import 'package:nutrilink/pages/onboarding/challengePage.dart' as challenge;
import 'package:nutrilink/pages/onboarding/summaryPage.dart' as summary_page;

const bool useDebugAppCheck =
    bool.fromEnvironment('USE_DEBUG_APPCHECK', defaultValue: !kReleaseMode);

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final storage = FirebaseStorage.instance;
      storage.setMaxUploadRetryTime(const Duration(seconds: 10));
      storage.setMaxDownloadRetryTime(const Duration(seconds: 10));
      storage.setMaxOperationRetryTime(const Duration(seconds: 10));
      debugPrint('✅ Firebase Storage configured with 10s timeout');
    } catch (e) {
      debugPrint('⚠️ Could not configure Firebase Storage: $e');
    }

    GeminiService.initialize();
    await NotificationService.initialize();

    await CartManager.loadCart();
    debugPrint('✅ Cart loaded');

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('UNCAUGHT PLATFORM ERROR: $error\n$stack');
      return true;
    };

    if (!kIsWeb) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    runApp(const NutriLinkApp());
  }, (e, s) {
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
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
      home: const AuthGate(),
      routes: {
        '/welcome': (_) => const welcome.WelcomePage(),
        '/login': (_) => const login.LoginPage(),
        '/register': (_) => const register.RegisterPage(),
        '/terms': (_) => const terms.TermsAndConditionsPage(),
        '/home': (_) => const home.HomePage(),
        '/recommendation': (_) => const meal_page.RecommendationScreen(),
        '/report': (_) => const report_page.ReportScreen(),
        '/name-input': (_) => const name_input.NameInputPage(),
        '/sex': (_) => const sex_page.SexPage(),
        '/birth-date': (_) => const birth_date.BirthDatePage(),
        '/height-input': (_) => const height_input.HeightInputPage(),
        '/weight-input': (_) => const weight_input.WeightInputPage(),
        '/target-selection': (_) => const target_sel.TargetSelectionPage(),
        '/target-weight': (_) => const target_weight.TargetWeightInputPage(),
        '/health-goal': (_) => const health_goal.HealthGoalPage(),
        '/daily-activity': (_) => const daily_activity.DailyActivityPage(),
        '/sleep-schedule': (_) => const sleep_sched.SleepSchedulePage(),
        '/eat-frequency': (_) => const eat_freq.EatFrequencyPage(),
        '/allergy': (_) => const allergy_page.AllergyPage(),
        '/challenge': (_) => const challenge.ChallengePage(),
        '/summary': (_) => const summary_page.SummaryPage(),
        // Profile feature routes
        '/profile/view': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments;
          return profile_view.ViewProfilePage(
              userData: args as Map<String, dynamic>);
        },
        '/profile/edit': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments;
          return profile_edit.EditProfilePage(
              userData: args as Map<String, dynamic>);
        },
        '/profile/nutrition': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments;
          return profile_nutrition.NutritionNeedsPage(
              userData: args as Map<String, dynamic>);
        },
        '/profile/bmr': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments;
          return profile_bmr.BmrCalculationPage(
              userData: args as Map<String, dynamic>);
        },
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF75C778),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const home.HomePage();
        }

        return const welcome.WelcomePage();
      },
    );
  }
}

// lib/config/appTheme.dart
// Design System NutriLink x HealthyGo
// Extracted from homePage.dart untuk konsistensi styling di seluruh aplikasi

import 'package:flutter/material.dart';

// ==========================================
// COLOR PALETTE
// ==========================================
class AppColors {
  // Primary Colors
  static const Color green = Colors.green;
  static const Color greenLight = Color(0xFF7BB662);
  
  // Text Colors
  static const Color greyText = Color(0xFF494949);
  static const Color lightGreyText = Color(0xFF888888);
  static const Color disabledGrey = Color(0xFFBDBDBD);
  
  // Border Colors
  static const Color mutedBorderGrey = Color(0xFFA9ABAD);
  
  // Status Colors
  static const Color yellow = Color(0xFFFFA726);
  static const Color orange = Color(0xFFFF7043);
  static const Color red = Color(0xFFE53935);
  static const Color blue = Color(0xFF42A5F5);
  
  // Background Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [greenLight, green],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient bmiGradient = LinearGradient(
    colors: [blue, green, orange, red],
    stops: [0.0, 0.25, 0.50, 0.75],
  );
}

// ==========================================
// TEXT STYLES
// ==========================================
class AppTextStyles {
  static const String fontFamily = 'Funnel Display';
  
  // Headers
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: AppColors.black87,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black87,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.black87,
  );
  
  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.black87,
  );
  
  static const TextStyle h5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.black87,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.greyText,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.greyText,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.lightGreyText,
  );
  
  // Button Text
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  
  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.lightGreyText,
  );
  
  // AppBar Title
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
  
  static const TextStyle appBarSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: AppColors.white,
  );
}

// ==========================================
// DECORATIONS
// ==========================================
class AppDecorations {
  // Card Decorations
  static BoxDecoration card({Color? color}) => BoxDecoration(
    color: color ?? AppColors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.06),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  static BoxDecoration cardWithBorder({Color? color}) => BoxDecoration(
    color: color ?? AppColors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.mutedBorderGrey, width: 1.4),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.06),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  // Button Decorations
  static BoxDecoration gradientButton = BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration roundedButton({required Color color}) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Input Decorations
  static InputDecoration textField({
    required String hint,
    String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.mutedBorderGrey, width: 1.4),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.mutedBorderGrey, width: 1.4),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.green, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.red, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
  
  // AppBar Decoration
  static BoxDecoration appBar = BoxDecoration(
    gradient: AppColors.primaryGradient,
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );
  
  // Image Container
  static BoxDecoration imageContainer = BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

// ==========================================
// BORDER RADIUS
// ==========================================
class AppRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xlarge = 20.0;
  static const double xxlarge = 28.0;
  
  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get xlargeRadius => BorderRadius.circular(xlarge);
  static BorderRadius get xxlargeRadius => BorderRadius.circular(xxlarge);
}

// ==========================================
// SPACING
// ==========================================
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

// ==========================================
// SHADOWS
// ==========================================
class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.06),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
  
  static List<BoxShadow> get large => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}

// ==========================================
// REUSABLE WIDGETS
// ==========================================
class AppWidgets {
  // Gradient Button
  static Widget gradientButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool enabled = true,
  }) {
    return Container(
      decoration: AppDecorations.gradientButton,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.xxlargeRadius,
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.white),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(text, style: AppTextStyles.button),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Loading Indicator
  static Widget loading({Color? color}) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? AppColors.green,
      ),
    );
  }
  
  // Empty State
  static Widget emptyState({
    required String message,
    IconData? icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 64,
              color: AppColors.lightGreyText,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            message,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// APP BAR
// ==========================================
class AppBarBuilder {
  static PreferredSizeWidget build({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    Widget? leading,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 14.0),
      child: Container(
        decoration: AppDecorations.appBar,
        child: Padding(
          padding: const EdgeInsets.only(top: 7.0, bottom: 7.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: leading,
            title: subtitle != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AppTextStyles.appBarTitle),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.appBarSubtitle.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  )
                : Text(title, style: AppTextStyles.appBarTitle),
            actions: actions,
          ),
        ),
      ),
    );
  }
}

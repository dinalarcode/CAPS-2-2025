# Onboarding Files AppTheme Update Status

## ✅ Completed Files (3/14):
1. ✅ onboardingHelpers.dart - Updated with AppColors, AppShadows, AppTextStyles, AppRadius
2. ✅ nameInputPage.dart - Full appTheme styling applied
3. ✅ sexPage.dart - Full appTheme styling applied

## 🔄 Files Requiring Updates (11/14):

### Pattern for Each File:

#### 1. Import Block
```dart
// REMOVE:
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);
final Color kBaseGreyFill = const Color(0xFF000000).withValues(alpha: 0.04);

// ADD:
import 'package:nutrilink/config/appTheme.dart';
```

#### 2. Color Replacements:
- `kGreen` → `AppColors.green`
- `kGreenLight` → `AppColors.greenLight`
- `kGreyText` → `AppColors.greyText`
- `kLightGreyText` → `AppColors.lightGreyText`
- `kDisabledGrey` → `AppColors.disabledGrey`
- `kMutedBorderGrey` → `AppColors.mutedBorderGrey`
- `Colors.white` → `AppColors.white`
- `Colors.black87` → `AppColors.black87`

#### 3. TextStyle Replacements:
- Heading (fontSize: 22, bold) → `AppTextStyles.h2`
- Body (fontSize: 12) → `AppTextStyles.bodySmall`
- Label (fontSize: 16) → `AppTextStyles.bodyLarge`
- Caption (fontSize: 10) → `AppTextStyles.caption`
- Button (fontSize: 15, bold, white) → `AppTextStyles.button`

#### 4. BorderRadius Replacements:
- `BorderRadius.circular(10)` → `AppRadius.smallRadius` (for cards)
- `BorderRadius.circular(16)` → `AppRadius.largeRadius` (for info boxes)
- `BorderRadius.circular(24)` → `AppRadius.xxlargeRadius` (for buttons)
- `BorderRadius.circular(28)` → `AppRadius.xxlargeRadius` (for buttons)

#### 5. BoxShadow Replacements:
- Small shadows → `AppShadows.small`
- Button shadows → `AppShadows.button`

#### 6. Gradient Replacements:
- Gradient `LinearGradient(colors: [kGreenLight, kGreen], ...)` → `AppColors.primaryGradient`

#### 7. Spacing Replacements:
- `SizedBox(height: 8)` → `SizedBox(height: AppSpacing.sm)`
- `SizedBox(height: 12)` → `SizedBox(height: AppSpacing.md)`
- `SizedBox(height: 16)` → `SizedBox(height: AppSpacing.lg)`
- `SizedBox(height: 24)` → `SizedBox(height: AppSpacing.xxl)`
- `SizedBox(height: 32)` → `SizedBox(height: AppSpacing.xxxl)`

#### 8. GradientButton Class Update:
```dart
@override
Widget build(BuildContext context) {
  final active = widget.enabled && (hover || press);

  final gradient = widget.enabled
      ? LinearGradient(
          colors: active
              ? const [AppColors.green, AppColors.greenLight]
              : const [AppColors.greenLight, AppColors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : null;

  return MouseRegion(
    onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() {
      hover = false;
      press = false;
    }),
    child: GestureDetector(
      onTapDown: (_) {
        if (widget.enabled) setState(() => press = true);
      },
      onTapUp: (_) {
        if (widget.enabled) setState(() => press = false);
      },
      onTapCancel: () {
        if (widget.enabled) setState(() => press = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          color: widget.enabled ? null : const Color(0xFFE0E0E0),
          borderRadius: AppRadius.xxlargeRadius,
          border: Border.all(
            color: widget.enabled ? AppColors.green : AppColors.disabledGrey,
            width: 2,
          ),
          boxShadow: widget.enabled ? AppShadows.button : null,
        ),
        child: TextButton(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.xxlargeRadius,
            ),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: AppTextStyles.button.copyWith(
                fontSize: 15,
                color: widget.enabled ? AppColors.white : AppColors.black.withValues(alpha: 0.54),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
```

## Files to Update:

### 4. birthDatePage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _inputBoxDecoration()
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

### 5. heightInputPage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _inputBoxDecoration()
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

### 6. weightInputPage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _inputBoxDecoration()
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

### 7. targetSelectionPage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _ChoiceRow card decorations
- [ ] Update back button
- [ ] Update GradientButton class

### 8. targetWeightInputPage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _inputBoxDecoration()
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

### 9. healthGoalPage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _ChoiceTile card decorations
- [ ] Update TextFormField decoration
- [ ] Update back button
- [ ] Update GradientButton class

### 10. dailyActivityPage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _cardDecoration()
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

### 11. sleepSchedulePage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

### 12. eatFrequencyPage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _cardDecoration()
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

### 13. allergyPage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _cardDecoration()
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

### 14. challengePage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update _ChallengeOptionTile card decorations
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

### 15. summaryPage.dart
- [ ] Add appTheme import, remove color constants
- [ ] Update heading RichText styles
- [ ] Update section titles
- [ ] Update _buildInfoCard()
- [ ] Update info box styling
- [ ] Update back button
- [ ] Update GradientButton class

## Key Benefits After Full Update:
1. ✅ Konsistensi warna di seluruh onboarding flow
2. ✅ Mudah maintenance - single source of truth (appTheme.dart)
3. ✅ Gradient hijau consistent (AppColors.primaryGradient)
4. ✅ Typography consistent (AppTextStyles)
5. ✅ Spacing consistent (AppSpacing)
6. ✅ Shadows consistent (AppShadows)
7. ✅ Border radius consistent (AppRadius)
8. ✅ Easy theming updates in future

## Next Steps:
Continue applying the pattern above to each remaining file systematically.

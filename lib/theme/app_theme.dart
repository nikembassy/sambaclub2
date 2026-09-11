import 'package:flutter/material.dart';

/// Sambaclub design tokens (black & gold).
///
/// Every screen/widget in the app pulls its colors from here so the theme stays
/// consistent. Use [AppColors] for raw values and [AppTheme.dark] for the
/// app-wide [ThemeData].
class AppColors {
  AppColors._();

  // Backgrounds / surfaces
  static const Color sambaBlack = Color(0xFF0A0A0C);
  static const Color sambaSurface = Color(0xFF17171D);
  static const Color sambaSurface2 = Color(0xFF1F1F27);
  static const Color sambaLines = Color(0xFF2A2A34);

  // Gold
  static const Color sambaGold = Color(0xFFD4AF37);
  static const Color sambaGoldLight = Color(0xFFF5D67B);
  static const Color sambaGoldDeep = Color(0xFFA67C1A);

  // Text / status
  static const Color sambaText = Color(0xFFF2F2F5);
  static const Color sambaMuted = Color(0xFF8E8E9A);
  static const Color sambaLive = Color(0xFFFF2D55);
  static const Color sambaOk = Color(0xFF39D98A);

  /// Signature gold gradient used for buttons, badges and logo accents.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFF5D67B),
      Color(0xFFD4AF37),
      Color(0xFFA67C1A),
    ],
  );
}

/// The single dark theme used by Sambaclub.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final ColorScheme scheme = const ColorScheme.dark().copyWith(
      primary: AppColors.sambaGold,
      onPrimary: AppColors.sambaBlack,
      secondary: AppColors.sambaGoldLight,
      onSecondary: AppColors.sambaBlack,
      surface: AppColors.sambaSurface,
      onSurface: AppColors.sambaText,
      error: AppColors.sambaLive,
      onError: AppColors.sambaText,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.sambaBlack,
      canvasColor: AppColors.sambaBlack,
      splashColor: AppColors.sambaGold.withOpacity(0.12),
      highlightColor: AppColors.sambaGold.withOpacity(0.06),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.sambaBlack,
        foregroundColor: AppColors.sambaText,
        elevation: 0,
        centerTitle: false,
      ),
      cardColor: AppColors.sambaSurface,
      dividerColor: AppColors.sambaLines,
      iconTheme: const IconThemeData(color: AppColors.sambaText),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.sambaText,
        displayColor: AppColors.sambaText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.sambaSurface2,
        hintStyle: const TextStyle(color: AppColors.sambaMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sambaLines),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sambaLines),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sambaGold, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sambaGold,
          foregroundColor: AppColors.sambaBlack,
          disabledBackgroundColor: AppColors.sambaSurface2,
          disabledForegroundColor: AppColors.sambaMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sambaGold,
          side: const BorderSide(color: AppColors.sambaGold),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.sambaSurface,
        selectedItemColor: AppColors.sambaGold,
        unselectedItemColor: AppColors.sambaMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.sambaSurface2,
        selectedColor: AppColors.sambaGold,
        labelStyle: const TextStyle(color: AppColors.sambaText),
        secondaryLabelStyle: const TextStyle(color: AppColors.sambaBlack),
        side: const BorderSide(color: AppColors.sambaLines),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.sambaSurface,
        modalBackgroundColor: AppColors.sambaSurface,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.sambaSurface2,
        contentTextStyle: TextStyle(color: AppColors.sambaText),
      ),
    );
  }
}

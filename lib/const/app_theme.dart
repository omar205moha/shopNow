import 'package:flutter/material.dart';

class AppColors {
  static const whiteColor = Color(0xFFFFFFFF);
  static const orangeColor = Color(0xFFFC6011);
  static const blackColor = Color(0xFF000000);
  static const darkGreyColor = Color(0xFF4A4B4D);
  static const greyColor = Color(0xFF7C7D7E);
  static const lightGreyColor = Color(0xFFA8A8A8);
  static const extraLightGreyColor = Color(0xFFF2F2F2);
  static const errorColor = Color(0xFFD32F2F);
  static const successColor = Color(0xFF388E3C);

  // Orange color variants
  static const orangeLightColor = Color(0xFFFF9D6C);
  static const orangeDarkColor = Color(0xFFD44700);
  static const orangeAccentColor = Color(0xFFFFAB91);
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      // Base colors
      primaryColor: AppColors.orangeColor,
      colorScheme: const ColorScheme.light(
        primary: AppColors.orangeColor,
        onPrimary: AppColors.whiteColor,
        secondary: AppColors.orangeDarkColor,
        onSecondary: AppColors.whiteColor,
        surface: AppColors.whiteColor,
        onSurface: AppColors.blackColor,
        error: AppColors.errorColor,
        onError: AppColors.whiteColor,
      ),

      // Material 3 features (enable if using Material 3)
      useMaterial3: true,

      // Typography
      fontFamily: 'Poppins', // Replace with preferred font
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkGreyColor),
        displayMedium:
            TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkGreyColor),
        displaySmall:
            TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkGreyColor),
        headlineLarge:
            TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.darkGreyColor),
        headlineMedium:
            TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkGreyColor),
        headlineSmall:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkGreyColor),
        titleLarge:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGreyColor),
        titleMedium:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkGreyColor),
        titleSmall:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkGreyColor),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkGreyColor),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkGreyColor),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.greyColor),
        labelLarge:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.orangeColor),
        labelMedium:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.orangeColor),
        labelSmall:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.orangeColor),
      ),

      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orangeColor,
          foregroundColor: AppColors.whiteColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orangeColor,
          side: const BorderSide(color: AppColors.orangeColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.orangeColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.whiteColor,
        foregroundColor: AppColors.orangeColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkGreyColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: AppColors.orangeColor,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.extraLightGreyColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.orangeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.lightGreyColor),
        errorStyle: const TextStyle(color: AppColors.errorColor),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: AppColors.whiteColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        shadowColor: AppColors.blackColor.withOpacity(0.1),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.whiteColor,
        selectedItemColor: AppColors.orangeColor,
        unselectedItemColor: AppColors.greyColor,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orangeColor,
        foregroundColor: AppColors.whiteColor,
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(AppColors.whiteColor),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orangeColor;
          }
          return AppColors.lightGreyColor;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orangeColor;
          }
          return AppColors.lightGreyColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orangeLightColor;
          }
          return AppColors.extraLightGreyColor;
        }),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orangeColor;
          }
          return AppColors.lightGreyColor;
        }),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.extraLightGreyColor,
        thickness: 0,
        space: 1,
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.whiteColor,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      // Base colors
      primaryColor: AppColors.orangeColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.orangeColor,
        onPrimary: AppColors.blackColor,
        secondary: AppColors.orangeLightColor,
        onSecondary: AppColors.blackColor,
        surface: Color(0xFF1E1E1E),
        onSurface: AppColors.whiteColor,
        error: AppColors.errorColor,
        onError: AppColors.whiteColor,
      ),

      // Material 3 features (enable if using Material 3)
      useMaterial3: true,

      // Typography
      fontFamily: 'Poppins', // Replace with  preferred font
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.whiteColor),
        displayMedium:
            TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.whiteColor),
        displaySmall:
            TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.whiteColor),
        headlineLarge:
            TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.whiteColor),
        headlineMedium:
            TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.whiteColor),
        headlineSmall:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor),
        titleLarge:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor),
        titleMedium:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.whiteColor),
        titleSmall:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.whiteColor),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.extraLightGreyColor),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.extraLightGreyColor),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.lightGreyColor),
        labelLarge:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.orangeColor),
        labelMedium:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.orangeColor),
        labelSmall:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.orangeColor),
      ),

      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orangeColor,
          foregroundColor: AppColors.blackColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orangeColor,
          side: const BorderSide(color: AppColors.orangeColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.orangeColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: AppColors.orangeColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.whiteColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: AppColors.orangeColor,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.orangeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.greyColor),
        errorStyle: const TextStyle(color: AppColors.errorColor),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        shadowColor: AppColors.blackColor.withOpacity(0.3),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.orangeColor,
        unselectedItemColor: AppColors.lightGreyColor,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orangeColor,
        foregroundColor: AppColors.blackColor,
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(AppColors.blackColor),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orangeColor;
          }
          return AppColors.greyColor;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orangeColor;
          }
          return AppColors.greyColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orangeLightColor;
          }
          return const Color(0xFF2C2C2C);
        }),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.orangeColor;
          }
          return AppColors.greyColor;
        }),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2C),
        thickness: 1,
        space: 1,
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// How to use the theme in your main.dart file:
/*
import 'package:flutter/material.dart';
import 'path_to_theme_file/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Orange App',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system, // Use system theme by default
      home: const HomePage(),
    );
  }
}
*/

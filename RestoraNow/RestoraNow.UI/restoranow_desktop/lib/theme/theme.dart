import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A237E); // Indigo[900]
  static const Color secondaryColor = Color(0xFF673AB7); // DeepPurple
  static const Color backgroundColor = Color(
    0xFFF9F5FC,
  ); // light purple-ish background
  static const Color cardColor = Color(0xFFE8EAF6); // Indigo[50]
  static const Color borderColor = Color(0xFFCED4DA);

  static const Color activeColor = Color(0xFFA5D6A7); // Green[200]
  static const Color inactiveColor = Color(0xFFEF9A9A); // Red[200]

  static const Color activeTextColor = Color(0xFF2E7D32); // Green[800]
  static const Color inactiveTextColor = Color(0xFFC62828); // Red[800]

  static ThemeData get lightTheme {
    return ThemeData(
      splashFactory: InkRipple.splashFactory,
      splashColor: primaryColor.withOpacity(0.1),
      highlightColor: Colors.transparent,
      hoverColor: primaryColor.withOpacity(0.05),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dialogBackgroundColor: Colors.white,
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        contentTextStyle: const TextStyle(fontSize: 14),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(fontSize: 14),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade300,
        disabledColor: Colors.grey.shade100,
        selectedColor: primaryColor.withOpacity(0.1),
        secondarySelectedColor: secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
      ),
      iconTheme: const IconThemeData(color: Colors.grey, size: 20),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  // Status Chip Style
  static Chip statusChip({required bool isActive}) {
    return Chip(
      label: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? activeTextColor : inactiveTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isActive ? activeColor : inactiveColor,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Role Chip Style
  static Chip roleChip(String role) {
    Color roleColor;

    switch (role.toLowerCase()) {
      case 'admin':
        roleColor = Colors.redAccent;
        break;
      case 'manager':
        roleColor = Colors.orangeAccent;
        break;
      case 'staff':
        roleColor = Colors.blueAccent;
        break;
      case 'customer':
        roleColor = Colors.green;
        break;
      default:
        roleColor = Colors.grey;
    }

    return Chip(
      label: Text(
        role,
        style: TextStyle(color: roleColor, fontWeight: FontWeight.w500),
      ),
      backgroundColor: roleColor.withOpacity(0.15),
      side: BorderSide(color: roleColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

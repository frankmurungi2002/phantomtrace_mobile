import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor:
        const Color(0xFF0B0F19),

    colorScheme:
        const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
    ),

    textTheme: TextTheme(
      displayLarge:
          GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),

      displayMedium:
          GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),

      headlineLarge:
          GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),

      headlineMedium:
          GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),

      titleLarge:
          GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),

      titleMedium:
          GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),

      bodyLarge:
          GoogleFonts.inter(
        color: Colors.white,
      ),

      bodyMedium:
          GoogleFonts.inter(
        color: Colors.white,
      ),

      bodySmall:
          GoogleFonts.inter(
        color: const Color(
          0xFF9CA3AF,
        ),
      ),
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor:
          const Color(0xFF0B0F19),
      titleTextStyle:
          GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
    ),

    cardTheme: CardThemeData(
      color: const Color(
        0xFF111827,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
    ),

    elevatedButtonTheme:
        ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            const Color(0xFF3B82F6),
        foregroundColor:
            Colors.white,
        minimumSize:
            const Size.fromHeight(
          56,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        textStyle:
            GoogleFonts.inter(
          fontWeight:
              FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),

    inputDecorationTheme:
        InputDecorationTheme(
      filled: true,
      fillColor:
          const Color(0xFF111827),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        borderSide:
            BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        borderSide:
            BorderSide.none,
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        borderSide:
            const BorderSide(
          color: Color(
            0xFF3B82F6,
          ),
        ),
      ),
      labelStyle:
          const TextStyle(
        color: Color(
          0xFF9CA3AF,
        ),
      ),
    ),

    dividerColor:
        const Color(0xFF1F2937),
  );
}

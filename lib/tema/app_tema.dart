import 'package:flutter/material.dart';
import 'app_cores.dart';

/// Monta o ThemeData do aplicativo a partir da paleta de AppCores.
///
/// Configurar o tema aqui evita repetir cor, borda e espaçamento em cada
/// widget: um TextField criado em qualquer tela já nasce com o visual certo.
class AppTema {
  static ThemeData montar() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppCores.fundo,

      colorScheme: const ColorScheme.light(
        primary: AppCores.laranja,
        secondary: AppCores.escuro,
        surface: AppCores.superficie,
        onSurface: AppCores.texto,
      ),

      // Barra superior escura, como no protótipo.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppCores.escuro,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppCores.superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppCores.borda),
        ),
      ),

      // Botão principal: laranja suave, cantos arredondados, altura confortável.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppCores.laranja,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppCores.borda,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppCores.laranja,
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: AppCores.laranja),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppCores.laranja),
      ),

      // Campos de digitação: fundo claro, borda fina, foco em laranja.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppCores.superficie,
        hintStyle: const TextStyle(color: AppCores.textoClaro, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppCores.borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppCores.borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppCores.laranja, width: 1.6),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppCores.escuro,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppCores.borda,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

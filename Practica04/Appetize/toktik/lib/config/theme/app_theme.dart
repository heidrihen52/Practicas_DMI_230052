import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/season.dart';

class SeasonStyle {
  final String label;
  final Color color;
  final IconData icon;
  final String font;
  final List<double> melody;
  const SeasonStyle(this.label, this.color, this.icon, this.font, this.melody);
  static SeasonStyle forSeason(Season season) => switch (season) {
    Season.normal => const SeasonStyle(
      'Normal',
      Color(0xFF42D6CB),
      Icons.music_note,
      'Roboto',
      [523, 659, 784],
    ),
    Season.halloween => const SeasonStyle(
      'Halloween',
      Color(0xFFFF8B32),
      Icons.nightlight_round,
      'Creepster',
      [220, 233, 330, 233],
    ),
    Season.christmas => const SeasonStyle(
      'Navidad',
      Color(0xFF66BB6A),
      Icons.ac_unit,
      'Mountains of Christmas',
      [659, 659, 659, 659, 784, 523],
    ),
    Season.valentines => const SeasonStyle(
      'San Valentín',
      Color(0xFFFF80AB),
      Icons.favorite,
      'Dancing Script',
      [523, 659, 784, 659, 523],
    ),
  };
}

class AppTheme {
  final Season season;
  AppTheme({this.season = Season.normal});
  ThemeData getTheme() {
    final style = SeasonStyle.forSeason(season);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: style.color,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF101015),
    );
    return base.copyWith(
      textTheme: GoogleFonts.getTextTheme(style.font, base.textTheme),
    );
  }
}

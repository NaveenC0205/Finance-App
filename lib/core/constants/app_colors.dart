import 'package:flutter/material.dart';

class AppColors {
  // ── Dark background layers ────────────────────────────────────
  static const Color background    = Color(0xFF070B14);
  static const Color surface       = Color(0xFF0F1724);
  static const Color card          = Color(0xFF141C2E);
  static const Color cardHighlight = Color(0xFF1A2438);
  static const Color surfaceVariant = Color(0xFF1E2A3B);

  // ── Primary purple accent ─────────────────────────────────────
  static const Color primary      = Color(0xFF7C5CF6);
  static const Color primaryDark  = Color(0xFF5B3FD4);
  static const Color primaryLight = Color(0xFF9B7EFF);
  static const Color primaryGlow  = Color(0x337C5CF6);

  // ── Status colors ─────────────────────────────────────────────
  static const Color success  = Color(0xFF06D6A0); // mint green
  static const Color danger   = Color(0xFFFF4D6D); // rose red
  static const Color warning  = Color(0xFFFFB800); // amber gold
  static const Color info     = Color(0xFF38BDF8); // sky blue

  // ── Text colors ───────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textTertiary  = Color(0xFF4A5568);

  // ── Border / divider ─────────────────────────────────────────
  static const Color border  = Color(0xFF1E2A3B);
  static const Color divider = Color(0xFF141C2E);

  // ── Drawer (keeps using surface dark) ────────────────────────
  static const Color drawerBg         = Color(0xFF0A0F1E);
  static const Color drawerItem       = Color(0xFF8892A4);
  static const Color drawerItemActive = Color(0xFFF0F4FF);

  // ── Chart colors ─────────────────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF7C5CF6),
    Color(0xFF06D6A0),
    Color(0xFFFFB800),
    Color(0xFFFF4D6D),
    Color(0xFF38BDF8),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFA78BFA),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFF8892A4),
  ];

  // ── Category colors ───────────────────────────────────────────
  static const Map<String, Color> categoryColors = {
    'food_dining':   Color(0xFFF97316),
    'groceries':     Color(0xFF06D6A0),
    'fuel':          Color(0xFFFFB800),
    'shopping':      Color(0xFFEC4899),
    'travel':        Color(0xFF38BDF8),
    'rent':          Color(0xFF7C5CF6),
    'emi':           Color(0xFFFF4D6D),
    'utilities':     Color(0xFF14B8A6),
    'entertainment': Color(0xFFF43F5E),
    'healthcare':    Color(0xFF06D6A0),
    'investment':    Color(0xFF34D399),
    'others':        Color(0xFF8892A4),
  };
}

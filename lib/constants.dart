import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const Color primaryGreen = Color(0xFF08914D); // unified alias (was 0xFF008853)
const Color appGreen = Color(0xFF08914D);
const Color appGreenLight = Color(0xFFE6F7EF);
const Color appGreenDark = Color(0xFF006A38);
const Color lightGreen = Color(0xFFC5E7DF);
const Color searchBg = Color(0xFFE8F5EE);
const Color inputBg = Color(0xFFF4F7FA);
const Color borderGray = Color(0xFFCBD5E1);
const Color textDark = Color(0xFF0F172A);
const Color textGray = Color(0xFF64748B);
const Color textLight = Color(0xFF94A3B8);
const Color resendLinkBlue = Color(0xFF0E4C92);
const Color darkBg = Color(0xFF0F172A);
const Color surfaceColor = Color(0xFFF8FAFC);
const Color cardColor = Colors.white;

// Status colors
const Color statusPending = Color(0xFFF59E0B);
const Color statusActive = Color(0xFF08914D);
const Color statusCompleted = Color(0xFF1E293B);
const Color statusCancelled = Color(0xFFEF4444);
const Color statusDeclined = Color(0xFFEF4444);

// ─── Spacing ──────────────────────────────────────────────────────────────────
const double borderRadius = 14.0;
const double cardBorderRadius = 16.0;
const double buttonBorderRadius = 14.0;
const double inputBorderRadius = 14.0;
const double smallRadius = 8.0;

const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20.0);
const EdgeInsets defaultMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

// ─── Typography ───────────────────────────────────────────────────────────────
const TextStyle titleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: textDark,
  letterSpacing: -0.3,
);

const TextStyle sectionTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: textDark,
  letterSpacing: -0.2,
);

const TextStyle subtitleStyle = TextStyle(
  fontSize: 14,
  color: textGray,
  height: 1.5,
);

const TextStyle captionStyle = TextStyle(
  fontSize: 12,
  color: textGray,
  fontWeight: FontWeight.w500,
);

const TextStyle buttonTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  letterSpacing: 0.6,
);

const TextStyle verifyTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: textDark,
);

const TextStyle welcomeTitleStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: textDark,
  letterSpacing: -0.5,
  height: 1.2,
);

const TextStyle welcomeSubtitleStyle = TextStyle(
  color: textGray,
  fontSize: 15,
  height: 1.6,
);

// ─── Button Styles ────────────────────────────────────────────────────────────
final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: appGreen,
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 52),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(buttonBorderRadius),
  ),
  elevation: 0,
  shadowColor: Colors.transparent,
  textStyle: const TextStyle(
    fontFamily: 'Lexend',
    fontWeight: FontWeight.bold,
    fontSize: 14,
    letterSpacing: 0.6,
  ),
);

final ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: appGreen,
  minimumSize: const Size(double.infinity, 52),
  side: const BorderSide(color: appGreen, width: 1.5),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(buttonBorderRadius),
  ),
  textStyle: const TextStyle(
    fontFamily: 'Lexend',
    fontWeight: FontWeight.bold,
    fontSize: 14,
    letterSpacing: 0.6,
  ),
);

// ─── Container Decorations ────────────────────────────────────────────────────
final BoxDecoration cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(cardBorderRadius),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ],
);

final BoxDecoration subtleCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(cardBorderRadius),
  border: Border.all(color: borderGray.withOpacity(0.4)),
);

final BoxDecoration searchBarDecoration = BoxDecoration(
  color: searchBg,
  borderRadius: BorderRadius.circular(cardBorderRadius),
);

final BoxDecoration vehicleCardDecoration = BoxDecoration(
  color: searchBg,
  borderRadius: BorderRadius.circular(cardBorderRadius),
  border: Border.all(color: appGreen, width: 1),
);

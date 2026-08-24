# Design System Specification — KiranaOS

**Document Version**: 1.0.0 (Phase 01 Production Architecture)  
**Foundation**: Material 3 (M3) + Kirana Retail Optimized Palette  

---

## 1. Design Principles for Indian Retail POS

1. **High Sunlight & Neon Visibility**: Maximum contrast for bright indoor fluorescent and harsh outdoor sunlight counter environments.
2. **Fat-Finger Touch Targets**: Minimum interactive dimension of `48 x 48 dp` (recommended `56 dp` for billing buttons and keypad keys).
3. **Information Density with Zero Clutter**: Essential price, weight, quantity, and total bill amounts are legible from a 1-meter viewing distance.
4. **Color Psychology**:
   - **Kirana Emerald (#0F766E)**: Primary brand color representing trust, commerce, and stability.
   - **Amber Gold (#D97706)**: Warning & Udhaar alert color representing credit reminders and attention states.
   - **Signal Red (#DC2626)**: Destructive actions, low stock, and bad debts.
   - **Slate Navy (#0F172A)**: Crisp, high-contrast dark typography and background hierarchy.

---

## 2. Color Palette & Token Hierarchy

```dart
abstract final class KiranaColors {
  // Brand Primary (Emerald)
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryContainer = Color(0xFFCCFBF1);
  static const Color onPrimaryContainer = Color(0xFF134E4A);

  // Brand Secondary (Amber / Udhaar Accent)
  static const Color secondary = Color(0xFFD97706);
  static const Color secondaryContainer = Color(0xFFFEF3C7);
  static const Color onSecondaryContainer = Color(0xFF78350F);

  // Semantic Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Neutral Backgrounds & Surfaces (Light POS Theme)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
}
```

---

## 3. Typography System

Using clean modern sans-serif type (Inter / Roboto) with strict proportional tabular figures for numeric prices:

| Token | Size | Weight | Line Height | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `displayTotal` | 32sp | Bold (700) | 40sp | POS Grand Total Display |
| `headlineLarge` | 24sp | SemiBold (600) | 32sp | Screen Titles |
| `headlineMedium` | 20sp | SemiBold (600) | 28sp | Card Headers & Section Titles |
| `titleLarge` | 18sp | Medium (500) | 24sp | Product Item Names |
| `bodyLarge` | 16sp | Regular (400) | 24sp | Standard Content & Input Text |
| `bodyMedium` | 14sp | Regular (400) | 20sp | Subtitles & Metadata |
| `labelLarge` | 15sp | SemiBold (600) | 20sp | Button Labels & Status Badges |
| `labelSmall` | 11sp | Medium (500) | 16sp | Timestamps & Unit Badges |

---

## 4. Spacing & Corner Radius Tokens

```dart
abstract final class KiranaSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

abstract final class KiranaRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double pill = 999.0;
}
```

---

## 5. Responsive Breakpoint Standards

```dart
abstract final class KiranaBreakpoints {
  static const double mobileMax = 599.0;
  static const double tabletMin = 600.0;
  static const double desktopMin = 1024.0;
}
```
- **Phone (<600dp)**: Single column stacked layout. Full screen cart with bottom checkout drawer.
- **Tablet (600–1023dp)**: Split 2-column POS. Left column (55%) Cart + Total; Right column (45%) Category Quick-Pills + Product Grid / NumPad.
- **Desktop (>=1024dp)**: Full 3-column Management Console with sidebar navigation.

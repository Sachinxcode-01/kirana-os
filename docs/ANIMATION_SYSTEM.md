# Animation System Specification & Performance Rules — KiranaOS

**Document Version**: 1.0.0 (Phase 01 Production Architecture)  
**Standard**: Fast, Purposeful, 60fps-Safe Motion  

---

## 1. Core Philosophy: Speed Over Flash

KiranaOS is an ultra-fast commercial Point of Sale. Animations must provide **instant sensory feedback** and **spatial orientation** without introducing any perceptual latency into checkout.

### Golden Rules:
1. **Never Block Billing**: No animation may delay barcode scanning, item addition, keyboard input, or receipt printing.
2. **Strict Duration Ceilings**: All micro-interactions must execute in **100ms – 180ms**. Page transitions must complete in **180ms – 280ms**.
3. **No Heavy Packages**: Avoid Rive or continuous 3D/particle loops. Use native Flutter motion primitives + `flutter_animate` for declarative chaining + `shimmer` for skeleton loading.

---

## 2. Animation Token Catalog

```dart
abstract final class KiranaDurations {
  /// Instant micro-interaction (Button press, checkbox tick, cart quantity bounce)
  static const Duration micro = Duration(milliseconds: 120);

  /// Small UI transition (Accordion expand, bottom sheet slide, toast entry)
  static const Duration quick = Duration(milliseconds: 180);

  /// Standard screen transition & modal dialog presentation
  static const Duration standard = Duration(milliseconds: 240);

  /// Celebratory success checkmark animation
  static const Duration success = Duration(milliseconds: 320);
}

abstract final class KiranaCurves {
  /// Standard easing for entrances (decelerating)
  static const Curve enter = Curves.easeOutCubic;

  /// Standard easing for exits (accelerating)
  static const Curve exit = Curves.easeInCubic;

  /// Snappy spring for button taps and badge increments
  static const Curve bounce = Curves.easeInOutBack;
}
```

---

## 3. Allowed Animation Use-Cases

| UI Event | Implementation Technique | Max Duration | Purpose |
| :--- | :--- | :--- | :--- |
| **Barcode Scanned** | Subtle Scale/Bounce on cart badge (`1.0 -> 1.15 -> 1.0`) | `120ms` | Confirms item registration without popup interruption. |
| **Cart Row Append** | `FadeTransition` + `SlideTransition` (`offset: [0, 0.1] -> [0, 0]`) | `150ms` | Clarifies where the new item landed in the list. |
| **Payment Success** | Animated SVG Checkmark morph + Scale In | `280ms` | Emotional reassurance that money was received. |
| **Loading Data** | Shimmer gradient sweep over placeholder skeleton | Loop `1200ms` | Perceived latency reduction during initial catalog fetch. |
| **Offline Toast** | Slide down from top app bar | `180ms` | Clear connectivity state awareness. |

---

## 4. Forbidden Animation Anti-Patterns (Strictly Enforced)

- ❌ **No Staggered List Animations on Cart Items**: Staggering animations (e.g. 50ms per item) freezes the frame rate when a 30-item bill is loaded.
- ❌ **No Continuous Animated Backgrounds**: No moving gradient or particle canvases that consume GPU battery on affordable retail tablets.
- ❌ **No Heavy Lottie on Transactional Screens**: Lottie is strictly banned from the Billing and Barcode screens. Lottie is permitted ONLY on the first-time Onboarding welcome screen and empty search state screens.
- ❌ **No Modal Entrance Animations >250ms**: Cashiers opening the Payment Dialog need it rendered immediately.

---

## 5. Accessibility & Reduced Motion Support

KiranaOS respects the system `disable-animations` / `reduce-motion` accessibility flag:

```dart
extension AnimationSafetyExtension on BuildContext {
  /// Checks if reduced motion is requested by Android/iOS system settings.
  bool get prefersReducedMotion => MediaQuery.of(this).disableAnimations;

  /// Returns [duration] or [Duration.zero] if reduced motion is enabled.
  Duration safeDuration(Duration duration) =>
      prefersReducedMotion ? Duration.zero : duration;
}
```
When reduced motion is enabled, all transitions become instantaneous cuts.

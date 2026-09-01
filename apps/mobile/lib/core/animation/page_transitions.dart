import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'animation_curves.dart';
import 'animation_durations.dart';

/// Centralized route transition builder for KiranaOS.
/// The Router is the single owner of all page-to-page navigation transitions.
abstract final class AppPageTransitions {
  /// Subtle fade + horizontal slide for primary navigation (Dashboard <-> Products <-> Bills <-> Customers)
  static CustomTransitionPage<T> fadeSlide<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration duration = AnimationDurations.standard,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AnimationCurves.enter,
          reverseCurve: AnimationCurves.exit,
        );

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.04, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Forward slide + fade for detail navigation (Products -> Details, Customers -> CustomerDetails)
  static CustomTransitionPage<T> slideForward<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration duration = AnimationDurations.standard,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AnimationCurves.enter,
          reverseCurve: AnimationCurves.exit,
        );

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.08, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Bottom-up slide + fade for modal-like full screen routes (Barcode Scanner, Add forms, Receipt Preview)
  static CustomTransitionPage<T> modalSlideUp<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration duration = AnimationDurations.standard,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AnimationCurves.enter,
          reverseCurve: AnimationCurves.exit,
        );

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.06),
          end: Offset.zero,
        ).animate(curvedAnimation);

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Smooth pure crossfade for auth and onboarding screens (Login <-> Register <-> Onboarding)
  static CustomTransitionPage<T> fade<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration duration = AnimationDurations.quick,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      },
    );
  }
}

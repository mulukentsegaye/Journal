import 'package:flutter/material.dart';

/// A flowing, natural page route that gently carries the user
/// from one screen to the next — like turning a page in a book.
///
/// The new page glides in from the right with a soft fade,
/// while the current page drifts slightly left and dims.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  SmoothPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );

            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );

            // New page slides in from 25% right, fading in
            final slideIn = Tween<Offset>(
              begin: const Offset(0.25, 0.0),
              end: Offset.zero,
            ).animate(curved);

            final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

            // Current page drifts left 8% and dims slightly
            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.08, 0.0),
            ).animate(secondaryCurved);

            final fadeOut =
                Tween<double>(begin: 1.0, end: 0.7).animate(secondaryCurved);

            return Stack(
              children: [
                // Departing page — drifts left and dims
                SlideTransition(
                  position: slideOut,
                  child: FadeTransition(
                    opacity: fadeOut,
                    child: child,
                  ),
                ),
                // Arriving page — glides in from right with fade
                SlideTransition(
                  position: slideIn,
                  child: FadeTransition(
                    opacity: fadeIn,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}

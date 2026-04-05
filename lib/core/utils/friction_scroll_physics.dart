import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom scroll physics that prevents flick-scrolling multiple pages
/// Used in Zen Carousel to enforce one-post-at-a-time navigation
class FrictionScrollPhysics extends ScrollPhysics {
  final double frictionFactor;

  const FrictionScrollPhysics({super.parent, this.frictionFactor = 0.5});

  @override
  FrictionScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FrictionScrollPhysics(
      parent: buildParent(ancestor),
      frictionFactor: frictionFactor,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Reduce the offset to prevent fast scrolling
    return offset * frictionFactor;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Apply stronger resistance at boundaries
    assert(() {
      if (value == position.pixels) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            '$runtimeType.applyBoundaryConditions() was called redundantly.',
          ),
          ErrorDescription(
            'The proposed new position, $value, is exactly equal to the current position of the '
            'given ${position.runtimeType}, ${position.pixels}.\n'
            'The applyBoundaryConditions method should only be called when the value is '
            'going to actually change the pixels, otherwise it is redundant.',
          ),
          DiagnosticsProperty<ScrollPhysics>(
            'The physics object in question was',
            this,
          ),
          DiagnosticsProperty<ScrollMetrics>(
            'The position object in question was',
            position,
          ),
        ]);
      }
      return true;
    }());

    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (position.maxScrollExtent <= position.pixels &&
        position.pixels < value) {
      return value - position.pixels;
    }
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels) {
      return value - position.minScrollExtent;
    }
    if (position.pixels < position.maxScrollExtent &&
        position.maxScrollExtent < value) {
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Clamp velocity to prevent multi-page flings
    const double maxVelocity = 800.0; // Adjust for desired friction
    final clampedVelocity = velocity.clamp(-maxVelocity, maxVelocity);

    // Use parent's simulation with clamped velocity
    final tolerance = toleranceFor(position);

    if (clampedVelocity.abs() < tolerance.velocity) {
      return null;
    }

    if (clampedVelocity.abs() < 50.0) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      position.pixels + clampedVelocity.sign * 100,
      clampedVelocity * 0.3, // Reduce initial velocity
      tolerance: tolerance,
    );
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 80, stiffness: 100, damping: 1.0);
}

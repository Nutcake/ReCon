import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:recon/color_palette.dart';
import 'package:recon/device_info.dart';
import 'package:recon/widgets/marquee.dart';
import 'package:smooth_corner/smooth_corner.dart';

class TranslucentGlass extends StatelessWidget {
  const TranslucentGlass({
    super.key,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.shape,
    this.border = const Border.fromBorderSide(BorderSide(color: Colors.white54, width: 1)),
    this.borderRadius,
    this.color,
    this.gradient,
    required this.child,
  });

  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final ShapeBorder? shape;
  final Border border;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final Gradient? gradient;
  final Widget child;

  factory TranslucentGlass.edgeToEdge(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Color? color,
    Gradient? gradient,
    bool top = true,
  }) {
    final BorderSide borderSide = defaultBorderSide(context);

    return TranslucentGlass(
      padding: padding,
      border: Border(
        top: !top ? borderSide : BorderSide.none,
        bottom: top ? borderSide : BorderSide.none,
      ),
      color: color,
      gradient: gradient,
      child: child,
    );
  }

  factory TranslucentGlass.island(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    ShapeBorder? shape,
    BorderRadiusGeometry? borderRadius,
    Color? color,
    Gradient? gradient,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final side = defaultBorderSide(context);

    return TranslucentGlass(
      padding: padding,
      shape: shape ?? RoundedRectangleBorder(side: side, borderRadius: radius),
      border: Border.fromBorderSide(side),
      borderRadius: radius,
      color: color,
      gradient: gradient,
      child: child,
    );
  }

  static Widget bottomNavBar(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Color? color,
    Gradient? gradient,
  }) {
    final BorderSide side = defaultBorderSide(context);
    final Radius? bezelRadius = DeviceInfo.bezelRadius;
    final bool floating = bezelRadius != null;
    final double margin = floating ? 12 : 0;
    final Radius calculatedRadius = floating ? bezelRadius - Radius.circular(margin - 1) : Radius.zero;
    final BorderRadius? borderRadius = floating
        ? BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: calculatedRadius,
            bottomRight: calculatedRadius,
          )
        : null;

    return TranslucentGlass(
      margin: EdgeInsets.only(left: margin, right: margin, bottom: margin),
      padding: padding,
      borderRadius: borderRadius,
      border: floating ? Border.fromBorderSide(side) : Border(top: side),
      color: color,
      gradient: gradient,
      child: child,
    );
  }

  factory TranslucentGlass.card(BuildContext context,
      {required Widget child,
      EdgeInsetsGeometry padding = EdgeInsets.zero,
      ShapeBorder? shape,
      BorderRadiusGeometry? borderRadius,
      Color? color,
      Gradient? gradient}) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    final side = defaultBorderSide(context);

    return TranslucentGlass(
      padding: padding,
      shape: shape ?? RoundedRectangleBorder(side: side, borderRadius: radius),
      borderRadius: radius,
      border: Border.fromBorderSide(side),
      color: color,
      gradient: gradient,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shapeBorder = shape ??
        SmoothRectangleBorder(
          smoothness: 0.6,
          borderRadius: borderRadius ?? BorderRadius.zero,
          side: border.isUniform ? border.top : BorderSide.none,
        );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: margin,
        child: ClipPath(
          clipper: ShapeBorderClipper(
            shape: shapeBorder,
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Stack(
              children: [
                if (kDebugMode) // Debugging
                  UnconstrainedBox(
                    constrainedAxis: Axis.horizontal,
                    alignment: AlignmentDirectional.center,
                    child: Marquee(
                      direction: Axis.horizontal,
                      animationDuration: const Duration(milliseconds: 500 * 18),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: List.filled(
                          18,
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'owo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: palette.neutrals.light.withOpacity(0.1),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: padding.add(border.dimensions),
                  decoration: border.isUniform
                      ? ShapeDecoration(
                          color: color,
                          gradient: gradient,
                          shape: shapeBorder,
                        )
                      : BoxDecoration(
                          borderRadius: borderRadius,
                          border: border,
                          color: color,
                          gradient: gradient,
                        ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static LinearGradient defaultTopGradient(BuildContext context) {
    final theme = Theme.of(context);

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.colorScheme.background,
        theme.colorScheme.surface,
      ],
    );
  }

  static LinearGradient defaultBottomGradient(BuildContext context) {
    final theme = Theme.of(context);

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.colorScheme.surface,
        theme.colorScheme.background,
      ],
    );
  }

  static BorderSide defaultBorderSide(BuildContext context) {
    final theme = Theme.of(context);

    return BorderSide(
      color: theme.colorScheme.outline,
      width: 1,
    );
  }
}

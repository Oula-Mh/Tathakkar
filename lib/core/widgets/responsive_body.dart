import 'package:flutter/material.dart';

/// Keeps content readable on tablets: centered with a max width.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 560});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

abstract final class Breakpoints {
  static bool isTablet(BuildContext c) => MediaQuery.sizeOf(c).shortestSide >= 600;
}

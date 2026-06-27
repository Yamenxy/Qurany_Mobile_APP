import 'package:flutter/material.dart';

/// RTL-aware icons and navigation controls for the Arabic-first app.
///
/// Directional Material icons mirror when [TextDirection] is RTL (horizontal
/// flip). Pick the LTR glyph so that, after mirroring, it points the way we
/// want on screen.
class AppIcons {
  AppIcons._();

  /// App bar / screen back control (leading edge in RTL = top-right).
  static Widget backButton({
    required BuildContext context,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return IconButton(
      tooltip: 'رجوع',
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: backIcon(color: color),
    );
  }

  /// Back / pop — points toward the start edge (right in RTL).
  static Widget backIcon({Color? color, double size = 24}) {
    return Icon(
      Icons.arrow_back_rounded,
      color: color,
      size: size,
    );
  }

  /// Trailing list chevron — points toward the end edge (left in RTL).
  static Widget forwardChevron({Color? color, double size = 16}) {
    return Icon(
      Icons.chevron_right_rounded,
      color: color,
      size: size,
    );
  }

  /// Forward / continue action — points toward the end edge (left in RTL).
  static Widget actionForward({Color? color, double size = 20}) {
    return Icon(
      Icons.arrow_forward_rounded,
      color: color,
      size: size,
    );
  }

  /// Previous item (placed on the start / right in RTL) — points start (→).
  static Widget navPrevious({Color? color, double size = 22}) {
    return Icon(
      Icons.chevron_left_rounded,
      color: color,
      size: size,
    );
  }

  /// Next item (placed on the end / left in RTL) — points end (←).
  static Widget navNext({Color? color, double size = 22}) {
    return Icon(
      Icons.chevron_right_rounded,
      color: color,
      size: size,
    );
  }
}

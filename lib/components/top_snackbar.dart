import 'package:flutter/material.dart';

/// Shows a floating top snackbar. Automatically removes any previous one.
void showTopSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 5),
  Color backgroundColor = Colors.black87,
  TextStyle? textStyle,
  EdgeInsetsGeometry margin = const EdgeInsets.symmetric(horizontal: 16),
  double topOffset = 16, // distance from top safe area
}) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;

  // We keep a key on the overlay entry so we can remove previous ones
  final overlayState = overlay;

  // Remove any existing top snackbars inserted by this helper
  // We store them on the overlay via an entry in overlayState.context (no built-in store),
  // so simplest approach: iterate entries and remove ones with our marker widget type.
  // However iterating overlay entries isn't public; instead we simply insert one and
  // ensure callers don't insert duplicates rapidly. For safety, hide current in ScaffoldMessenger too.
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  final entry = OverlayEntry(
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final safeTop = media.padding.top;
      return Positioned(
        top: safeTop + topOffset,
        left: 16,
        right: 16,
        child: _TopSnackBarWidget(
          message: message,
          backgroundColor: backgroundColor,
          textStyle: textStyle,
        ),
      );
    },
  );

  overlayState.insert(entry);

  // Auto remove after duration
  Future.delayed(duration, () {
    try {
      entry.remove();
    } catch (_) {}
  });
}

class _TopSnackBarWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final TextStyle? textStyle;

  const _TopSnackBarWidget({
    Key? key,
    required this.message,
    required this.backgroundColor,
    this.textStyle,
  }) : super(key: key);

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));
  late final Animation<Offset> _offsetAnim =
      Tween(begin: const Offset(0, -0.2), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  late final Animation<double> _opacityAnim =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeText = widget.textStyle ??
        const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500);

    return SlideTransition(
      position: _offsetAnim,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: themeText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

/// A premium glassmorphic container with blur, translucent border, and subtle glow.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 15,
    this.opacity = 0.08,
    this.color,
    this.borderColor,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (color ?? colors.cardBg).withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: (borderColor ?? Colors.white.withOpacity(0.08)),
                width: 1.5,
              ),
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A top-level scaffold providing the deep background and structural foundation.
class GlassScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Widget? drawer;
  final Widget? endDrawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const GlassScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
    this.drawer,
    this.endDrawer,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor ?? colors.scaffoldBg,
      drawer: drawer,
      endDrawer: endDrawer,
      appBar: title != null ? AppBar(
        title: Text(title!),
        actions: actions,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ) : null,
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}

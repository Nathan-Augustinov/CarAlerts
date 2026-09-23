import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.border,
    required this.divider,
    required this.selected,
    required this.error,
    required this.warning,
    required this.banner,
    required this.onBanner,
    required this.bannerMuted,
    required this.bannerAccent,
  });
  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color border;
  final Color divider;
  final Color selected;
  final Color error;
  final Color warning;
  final Color banner;
  final Color onBanner;
  final Color bannerMuted;
  final Color bannerAccent;
  static const light = AppPalette(
    background: Color(0xFFF3F6F7),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF172D38),
    muted: Color(0xFF60717C),
    accent: Color(0xFF15766D),
    onAccent: Color(0xFFFFFFFF),
    border: Color(0xFFE0E7EA),
    divider: Color(0xFFEAF0F2),
    selected: Color(0xFFDDEEEA),
    error: Color(0xFFAD3939),
    warning: Color(0xFF94600E),
    banner: Color(0xFF172D38),
    onBanner: Color(0xFFFFFFFF),
    bannerMuted: Color(0xFFC3D0D6),
    bannerAccent: Color(0xFF9EDBD0),
  );
  static const dark = AppPalette(
    background: Color(0xFF101C23),
    surface: Color(0xFF172D38),
    ink: Color(0xFFEDF3F5),
    muted: Color(0xFFA6B7BF),
    accent: Color(0xFF70CDBE),
    onAccent: Color(0xFF102D28),
    border: Color(0xFF304650),
    divider: Color(0xFF304650),
    selected: Color(0xFF24483F),
    error: Color(0xFFFFAAA3),
    warning: Color(0xFFEBC078),
    banner: Color(0xFF1B3541),
    onBanner: Color(0xFFEDF3F5),
    bannerMuted: Color(0xFFC3D0D6),
    bannerAccent: Color(0xFF9EDBD0),
  );
  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? accent,
    Color? onAccent,
    Color? border,
    Color? divider,
    Color? selected,
    Color? error,
    Color? warning,
    Color? banner,
    Color? onBanner,
    Color? bannerMuted,
    Color? bannerAccent,
  }) =>
      AppPalette(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        border: border ?? this.border,
        divider: divider ?? this.divider,
        selected: selected ?? this.selected,
        error: error ?? this.error,
        warning: warning ?? this.warning,
        banner: banner ?? this.banner,
        onBanner: onBanner ?? this.onBanner,
        bannerMuted: bannerMuted ?? this.bannerMuted,
        bannerAccent: bannerAccent ?? this.bannerAccent,
      );
  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      banner: Color.lerp(banner, other.banner, t)!,
      onBanner: Color.lerp(onBanner, other.onBanner, t)!,
      bannerMuted: Color.lerp(bannerMuted, other.bannerMuted, t)!,
      bannerAccent: Color.lerp(bannerAccent, other.bannerAccent, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class AppTheme {
  static final light = _build(Brightness.light, AppPalette.light);
  static final dark = _build(Brightness.dark, AppPalette.dark);

  static SystemUiOverlayStyle systemBars(Brightness brightness) =>
      (brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      );

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
    ).copyWith(
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.selected,
      onPrimaryContainer: p.ink,
      secondary: p.accent,
      onSecondary: p.onAccent,
      secondaryContainer: p.selected,
      onSecondaryContainer: p.accent,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.muted,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.selected,
      outline: p.muted,
      outlineVariant: p.border,
      error: p.error,
      onError: brightness == Brightness.dark ? p.background : Colors.white,
      surfaceTint: Colors.transparent,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
      scaffoldBackgroundColor: p.background,
      dividerColor: p.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemBars(brightness),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: TextStyle(color: p.muted),
        helperStyle: TextStyle(color: p.muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

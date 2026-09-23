import 'package:flutter/material.dart';
import '../services/appearance_controller.dart';
import '../theme/app_theme.dart';

class AppearanceSetting extends StatelessWidget {
  const AppearanceSetting({super.key, required this.controller});
  final AppearanceController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final effective = Theme.of(context).brightness == Brightness.dark
              ? 'Dark'
              : 'Light';
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            leading:
                Icon(Icons.palette_outlined, color: context.palette.accent),
            title: Text('Appearance',
                style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            subtitle: Text(
                controller.mode == ThemeMode.system
                    ? 'System · $effective'
                    : controller.mode.label,
                style: TextStyle(color: context.palette.muted, fontSize: 12)),
            trailing: Icon(Icons.chevron_right, color: context.palette.muted),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _AppearanceSelector(controller: controller),
            ),
          );
        },
      );
}

class _AppearanceSelector extends StatefulWidget {
  const _AppearanceSelector({required this.controller});
  final AppearanceController controller;

  @override
  State<_AppearanceSelector> createState() => _AppearanceSelectorState();
}

class _AppearanceSelectorState extends State<_AppearanceSelector> {
  String? _error;
  AppearanceController get controller => widget.controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text('Appearance',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(_error!,
                            style: TextStyle(color: context.palette.error)),
                      ),
                    ),
                  RadioGroup<ThemeMode>(
                    groupValue: controller.mode,
                    onChanged: (value) async {
                      if (value == null || controller.saving) return;
                      setState(() => _error = null);
                      try {
                        await controller.select(value);
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (_) {
                        if (context.mounted) {
                          setState(() => _error =
                              'Could not save appearance. Please try again.');
                        }
                      }
                    },
                    child: Column(
                      children: [
                        for (final mode in ThemeMode.values)
                          RadioListTile<ThemeMode>(
                            value: mode,
                            enabled: !controller.saving,
                            title: Text(mode.label),
                            subtitle: Text(switch (mode) {
                              ThemeMode.system => 'Follow your device settings',
                              ThemeMode.light => 'Always use light appearance',
                              ThemeMode.dark => 'Always use dark appearance',
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

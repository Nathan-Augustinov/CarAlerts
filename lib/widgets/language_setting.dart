import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/language_controller.dart';
import '../theme/app_theme.dart';

class LanguageSetting extends StatelessWidget {
  const LanguageSetting({super.key, required this.controller});
  final LanguageController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          leading: Icon(Icons.language, color: context.palette.accent),
          title: Text(AppLocalizations.of(context)!.language,
              style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          subtitle: Text(
              controller.locale.languageCode == 'ro'
                  ? AppLocalizations.of(context)!.languageRomanian
                  : AppLocalizations.of(context)!.languageEnglish,
              style: TextStyle(color: context.palette.muted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: context.palette.muted),
          onTap: () => showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              builder: (_) => _LanguageSelector(controller: controller)),
        ),
      );
}

class _LanguageSelector extends StatefulWidget {
  const _LanguageSelector({required this.controller});
  final LanguageController controller;
  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
  bool _failed = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => SafeArea(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(AppLocalizations.of(context)!.language,
                        style: Theme.of(context).textTheme.headlineSmall)),
                if (_failed)
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Semantics(
                          liveRegion: true,
                          child: Text(
                              AppLocalizations.of(context)!.languageSaveError,
                              style: TextStyle(color: context.palette.error)))),
                RadioGroup<String>(
                    groupValue: widget.controller.locale.languageCode,
                    onChanged: (value) async {
                      if (value == null || widget.controller.saving) return;
                      setState(() => _failed = false);
                      try {
                        await widget.controller.select(value);
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (_) {
                        if (mounted) setState(() => _failed = true);
                      }
                    },
                    child: Column(children: [
                      for (final entry in {
                        'en': AppLocalizations.of(context)!.languageEnglish,
                        'ro': AppLocalizations.of(context)!.languageRomanian
                      }.entries)
                        RadioListTile<String>(
                            value: entry.key,
                            title: Text(entry.value),
                            enabled: !widget.controller.saving),
                    ])),
              ]),
        )),
      );
}

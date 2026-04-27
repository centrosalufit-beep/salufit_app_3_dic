import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/locale_provider.dart';

class LanguageFlagPicker extends ConsumerWidget {
  const LanguageFlagPicker({
    this.compact = false,
    this.onChanged,
    super.key,
  });

  final bool compact;
  final ValueChanged<Locale>? onChanged;

  static const _flags = <String, String>{
    'es': '🇪🇸',
    'en': '🇬🇧',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'nl': '🇳🇱',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider);
    final size = compact ? 28.0 : 36.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final loc in kSupportedLocales)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _FlagButton(
              flag: _flags[loc.languageCode] ?? '🏳️',
              languageCode: loc.languageCode,
              selected: current.languageCode == loc.languageCode,
              size: size,
              onTap: () async {
                await ref
                    .read(localeControllerProvider.notifier)
                    .setLocale(loc);
                onChanged?.call(loc);
              },
            ),
          ),
      ],
    );
  }
}

class _FlagButton extends StatelessWidget {
  const _FlagButton({
    required this.flag,
    required this.languageCode,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final String flag;
  final String languageCode;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'language_flag_$languageCode',
      label: 'language_flag_$languageCode',
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(selected ? 6 : 4),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF009688)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            flag,
            style: TextStyle(fontSize: size, height: 1),
          ),
        ),
      ),
    );
  }
}

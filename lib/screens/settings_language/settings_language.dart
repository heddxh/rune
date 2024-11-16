import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../utils/settings_manager.dart';
import '../../utils/settings_page_padding.dart';
import '../../config/theme.dart';
import '../../widgets/unavailable_page_on_band.dart';
import '../../widgets/navigation_bar/page_content_frame.dart';
import '../../utils/l10n.dart';

import '../settings_library/widgets/settings_button.dart';

import 'constants/supported_languages.dart';

const localeKey = 'locale';

final _settingsManager = SettingsManager();

class SettingsLanguage extends StatefulWidget {
  const SettingsLanguage({super.key});

  @override
  State<SettingsLanguage> createState() => _SettingsLanguageState();
}

class _SettingsLanguageState extends State<SettingsLanguage> {
  Locale? locale;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final String? storedLocale =
        await _settingsManager.getValue<String>(localeKey);

    setState(() {
      if (storedLocale != null) {
        final parts = storedLocale.split('_');
        if (parts.length == 2) {
          locale = Locale(parts[0], parts[1]);
        }
      }
    });
  }

  Future<void> _updateLocale(Locale? newLocale) async {
    setState(() {
      locale = newLocale;
      appTheme.locale = newLocale;
    });

    if (newLocale != null) {
      final serializedLocale =
          '${newLocale.languageCode}_${newLocale.countryCode}';
      await _settingsManager.setValue(localeKey, serializedLocale);
    } else {
      await _settingsManager.removeValue(localeKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageContentFrame(
      child: UnavailablePageOnBand(
        child: SingleChildScrollView(
          padding: getScrollContainerPadding(context),
          child: SettingsPagePadding(
            child: Column(
              children: [
                SettingsButton(
                  icon: Symbols.emoji_language,
                  title: S.of(context).followSystemLanguage,
                  subtitle: S.of(context).followSystemLanguageSubtitle,
                  onPressed: () async {
                    await _updateLocale(null);
                  },
                ),
                ...supportedLanguages.map((language) => SettingsButton(
                      icon: Symbols.language,
                      title: language.title,
                      subtitle: language.sampleText,
                      onPressed: () {
                        _updateLocale(language.locale);
                      },
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
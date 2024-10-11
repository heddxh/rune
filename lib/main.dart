import 'dart:io';

import 'package:rinf/rinf.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:system_theme/system_theme.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:window_manager/window_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;

import 'utils/platform.dart';
import 'utils/file_storage/mac_secure_manager.dart';

import 'config/theme.dart';
import 'config/app_title.dart';
import 'config/navigation.dart';

import 'config/shortcuts.dart';
import 'utils/navigation/navigation_action.dart';

import 'messages/generated.dart';

import 'providers/volume.dart';
import 'providers/status.dart';
import 'providers/playlist.dart';
import 'providers/full_screen.dart';
import 'providers/library_path.dart';
import 'providers/library_manager.dart';
import 'providers/playback_controller.dart';
import 'providers/responsive_providers.dart';
import 'providers/transition_calculation.dart';

import 'theme.dart';
import 'router.dart';
import 'utils/navigation/navigation_intent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await FullScreen.ensureInitialized();
  await GetStorage.init();
  await GetStorage.init(MacSecureManager.storageName);
  await MacSecureManager.shared.loadBookmark();
  await initializeRust(assignRustSignal);

  try {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final isWindows10 = (await deviceInfo.windowsInfo).majorVersion == 10;
    if (isWindows10 &&
        appTheme.windowEffect == flutter_acrylic.WindowEffect.mica) {
      appTheme.windowEffect = flutter_acrylic.WindowEffect.solid;
    }
  } catch (e) {
    debugPrint('Device is not Windows 10, skip the patch');
  }

  final storage = GetStorage();
  bool? storedFullScreen = storage.read<bool>('fullscreen_state');
  if (storedFullScreen != null) {
    FullScreen.setFullScreen(storedFullScreen);
  }

  WidgetsFlutterBinding.ensureInitialized();

  // if it's not on the web, windows or android, load the accent color
  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(
        defaultTargetPlatform,
      )) {
    SystemTheme.accentColor.load();
  }

  if (isDesktop && !Platform.isLinux) {
    await flutter_acrylic.Window.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => LibraryPathProvider(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => VolumeProvider(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => ResponsiveProvider(),
        ),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackControllerProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackStatusProvider()),
        ChangeNotifierProvider(create: (_) => LibraryManagerProvider()),
        ChangeNotifierProvider(create: (_) => FullScreenProvider()),
        ChangeNotifierProvider(
            create: (_) =>
                TransitionCalculationProvider(navigationItems: navigationItems))
      ],
      child: const Rune(),
    ),
  );
}

class Rune extends StatelessWidget {
  const Rune({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appTheme,
      builder: (context, child) {
        final appTheme = context.watch<AppTheme>();

        return FluentApp.router(
          title: appTitle,
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          shortcuts: shortcuts,
          actions: <Type, Action<Intent>>{
            NavigationIntent: NavigationAction(context),
          },
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          theme: FluentThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          locale: appTheme.locale,
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
          builder: (context, child) {
            final theme = FluentTheme.of(context);

            return Container(
              color: appTheme.windowEffect == flutter_acrylic.WindowEffect.solid
                  ? theme.micaBackgroundColor
                  : Colors.transparent,
              child: Directionality(
                textDirection: appTheme.textDirection,
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}

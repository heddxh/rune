import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../utils/router/navigation.dart';
import '../screens/settings_library/widgets/progress_button.dart';
import '../messages/library_manage.pbenum.dart';
import '../providers/library_manager.dart';
import '../providers/library_path.dart';
import '../utils/l10n.dart';

Future<bool?> showCancelDialog(BuildContext context) {
  return $showModal<bool>(
    context,
    (context, $close) => ContentDialog(
      title: Text(S.of(context).cancelTaskTitle),
      content: Text(S.of(context).cancelTaskSubtitle),
      actions: [
        FilledButton(
          child: Text(S.of(context).cancelTask),
          onPressed: () {
            $close(true);
          },
        ),
        Button(
          child: Text(S.of(context).continueTask),
          onPressed: () => $close(false),
        ),
      ],
    ),
    dismissWithEsc: true,
    barrierDismissible: true,
  );
}

class LibraryTaskButton extends StatelessWidget {
  final String title;
  final String progressTitle;
  final Future<void> Function(LibraryManagerProvider, String) onPressedStart;
  final void Function(LibraryManagerProvider, String) onPressedCancel;
  final bool Function(bool, bool) isTaskWorking;
  final double? progress;

  const LibraryTaskButton({
    required this.title,
    required this.progressTitle,
    required this.onPressedStart,
    required this.onPressedCancel,
    required this.isTaskWorking,
    required this.progress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final libraryPath = Provider.of<LibraryPathProvider>(context, listen: true);
    final itemPath = libraryPath.currentPath;

    if (itemPath == null) {
      return Container();
    }

    final libraryManager =
        Provider.of<LibraryManagerProvider>(context, listen: true);

    final scanProgress = libraryManager.getScanTaskProgress(itemPath);
    final analyzeProgress = libraryManager.getAnalyzeTaskProgress(itemPath);

    final scanWorking = scanProgress?.status == TaskStatus.working;
    final analyzeWorking = analyzeProgress?.status == TaskStatus.working;

    final isWorking = scanWorking || analyzeWorking;

    return isWorking && isTaskWorking(scanWorking, analyzeWorking)
        ? ProgressButton(
            title: progressTitle,
            onPressed: () => onPressedCancel(libraryManager, itemPath),
            progress: progress,
            filled: false,
          )
        : Button(
            onPressed: isWorking
                ? null
                : () => onPressedStart(libraryManager, itemPath),
            child: Text(title),
          );
  }
}

class ScanLibraryButton extends StatelessWidget {
  final String? title;
  final void Function()? onFinished;

  const ScanLibraryButton({
    super.key,
    this.title,
    this.onFinished,
  });

  @override
  Widget build(BuildContext context) {
    return LibraryTaskButton(
      title: title ?? S.of(context).scan,
      progressTitle: S.of(context).scanning,
      progress: null,
      onPressedCancel: (libraryManager, itemPath) async {
        final confirm = await showCancelDialog(context);

        if (confirm == true) {
          libraryManager.cancelTask(itemPath, CancelTaskType.ScanAudioLibrary);
        }
      },
      onPressedStart: (libraryManager, itemPath) async {
        libraryManager.scanLibrary(itemPath, false);
        await libraryManager.waitForScanToComplete(itemPath);

        if (onFinished != null) {
          onFinished!();
        }
      },
      isTaskWorking: (scanWorking, analyzeWorking) => scanWorking,
    );
  }
}

class AnalyzeLibraryButton extends StatelessWidget {
  final String? title;
  final void Function()? onFinished;

  const AnalyzeLibraryButton({
    super.key,
    this.title,
    this.onFinished,
  });

  @override
  Widget build(BuildContext context) {
    final libraryPath = Provider.of<LibraryPathProvider>(context, listen: true);
    final itemPath = libraryPath.currentPath;

    if (itemPath == null) return Container();

    final libraryManager =
        Provider.of<LibraryManagerProvider>(context, listen: true);

    final analyzeProgress = libraryManager.getAnalyzeTaskProgress(itemPath);

    final progress = analyzeProgress == null
        ? null
        : analyzeProgress.progress / analyzeProgress.total;

    return LibraryTaskButton(
      title: title ?? S.of(context).analyze,
      progressTitle: S.of(context).analyzing,
      onPressedCancel: (libraryManager, itemPath) async {
        final confirm = await showCancelDialog(context);

        if (confirm == true) {
          libraryManager.cancelTask(
            itemPath,
            CancelTaskType.AnalyzeAudioLibrary,
          );
        }
      },
      onPressedStart: (libraryManager, itemPath) async {
        libraryManager.analyzeLibrary(itemPath, false);
        await libraryManager.waitForAnalyzeToComplete(itemPath);

        if (onFinished != null) {
          onFinished!();
        }
      },
      isTaskWorking: (scanWorking, analyzeWorking) => analyzeWorking,
      progress: progress,
    );
  }
}

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

#include <bitsdojo_window_windows/bitsdojo_window_plugin.h>
auto bdw = bitsdojo_window_configure(BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP);

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Create a mutex
  HANDLE hMutex = CreateMutex(NULL, TRUE, L"Rune_SingleInstance_Mutex");
  DWORD dwError = GetLastError();
  
  // If the mutex already exists, it means another instance is running
  if (dwError == ERROR_ALREADY_EXISTS) {
    // Find the existing window
    HWND hwnd = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Rune");
    if (hwnd != NULL) {
      // If the window is minimized, restore it
      if (::IsIconic(hwnd)) {
        ::ShowWindow(hwnd, SW_RESTORE);
      }
      // Bring the window to the foreground
      ::SetForegroundWindow(hwnd);
    }
    // Release the mutex handle
    ReleaseMutex(hMutex);
    CloseHandle(hMutex);
    return EXIT_FAILURE;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Rune", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();

  ReleaseMutex(hMutex);
  CloseHandle(hMutex);
  return EXIT_SUCCESS;
}

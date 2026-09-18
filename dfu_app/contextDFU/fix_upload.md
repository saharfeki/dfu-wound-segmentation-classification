# File Upload Fix Log

## Problem

In Flutter Web running on Edge, clicking **Upload from files** did not reliably open or report the picker failure. The app could appear to do nothing because the picker invocation was asynchronous and only had a Future-level error handler.

## Root Cause

Browser file dialogs must be opened synchronously from the original click event. A synchronous exception from `FilePicker.platform` or `pickFiles()` can happen before a Future exists, so `.catchError()` cannot catch it. The previous implementation also hid Future errors behind a generic snackbar.

## Fix Applied

- Kept `FilePicker.platform.pickFiles()` directly inside the upload tile click path, with no `await` before it.
- Wrapped the entire picker call in `try/catch` for synchronous plugin errors.
- Kept `.catchError()` for asynchronous picker failures and added `debugPrint` stack traces.
- Made both failure types visible through a snackbar instead of failing silently.
- Preserved JPEG/PNG filtering and in-memory byte loading.

## Clean Restart Steps

After adding or upgrading a Flutter plugin, hot reload is insufficient because web plugin registration occurs during application bootstrap. From the project directory:

```powershell
flutter clean
flutter pub get
flutter run -d edge
```

Stop any existing Flutter process before running the final command. In Edge DevTools, check the Console if the picker still fails; the snackbar now identifies whether the failure is synchronous or Future-based.

## Verification

- `flutter test test/widget_test.dart` passes.
- `flutter analyze` reports no issues.
- The connected Flutter app hot reloaded successfully before the clean restart.
- `flutter clean` completed successfully.
- `flutter pub get` restored the Dart dependencies but reported that Windows plugin builds require symlink support.
- A fresh `flutter run -d edge` reached the clean Edge debug launch; enable Windows Developer Mode if plugin bootstrap remains blocked.

## Windows Prerequisite

If Flutter reports `Building with plugins requires symlink support`, enable Developer Mode in Windows Settings, then rerun:

```powershell
start ms-settings:developers
flutter clean
flutter pub get
flutter run -d edge
```

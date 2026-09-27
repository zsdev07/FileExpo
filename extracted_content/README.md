# FileExpo

A lightweight, free, ad-free Android file explorer built with Flutter,
aiming to match (and beat) apps like Solid Explorer / MiXplorer.

## Status: Step 2 — Real storage access + folder navigation

This drop replaces the mock data from Step 1 with **real device storage**.

What's new in this step:

- **`StorageAccessService`** (`lib/services/`): requests and checks real
  storage permissions.
  - Android 11+ (API 30+): "All files access" (`MANAGE_EXTERNAL_STORAGE`),
    granted through Settings via a small Kotlin bridge
    (`MainActivity.kt`) since there's no stable path_provider API for the
    true shared-storage root or for that settings screen.
  - Android 10 and below: the classic `READ/WRITE_EXTERNAL_STORAGE`
    runtime permission, via `permission_handler`.
- **`PermissionGateScreen`** (`lib/screens/`): the "Let's show your files /
  Grant access" screen from the reference screenshots. `StorageGate`
  shows it until access is granted, and re-checks automatically when the
  app resumes (covers the Settings round-trip on Android 11+).
- **`RealFileRepository`** (`lib/data/`): lists actual folders/files with
  `dart:io`, sorted folders-first then alphabetically, hidden dotfiles
  skipped, with real sizes/item counts/modified dates and per-extension
  icons (`FileIconResolver`).
- **Real navigation in `HomeScreen`**: tapping a folder goes into it,
  the breadcrumb bar reflects the real path and jumps back up when
  tapped, and the Android back button goes up one folder at a time
  (only exits the app once you're back at the storage root).
- Tapping a *file* just shows a placeholder snackbar for now — built-in
  viewers are a later step.

## Project layout

```
lib/
  main.dart
  theme/                        # (Step 1) Purple/Black + Material You theme
  models/
    storage_entry.dart
  services/
    storage_access_service.dart # Permission checks + native bridge calls
  data/
    file_repository.dart        # Abstract interface
    real_file_repository.dart   # dart:io backed implementation (live)
    mock_file_repository.dart   # Step-1 sample data, kept for reference/tests
  utils/
    file_size_formatter.dart
    file_icon_resolver.dart
  widgets/
    app_top_bar.dart
    breadcrumb_bar.dart
    storage_entry_tile.dart
  screens/
    storage_gate.dart           # Permission screen <-> Home screen switch
    permission_gate_screen.dart
    home_screen.dart

android/app/src/main/kotlin/zx/offical/fexpo/MainActivity.kt
  # MethodChannel "zx.offical.fexpo/storage":
  #   getRootPath, isManageStorageGranted, openManageStorageSettings
```

## Before you run it

`flutter pub get` needs network access that this sandbox doesn't have, so
this hasn't been build-verified end to end — please run it on a real
device/emulator and send me any errors so I can fix them fast:

```
flutter pub get
flutter run
```

On first launch you'll hit the "Grant access" screen — accept it, and on
Android 11+ you'll be sent to the system "All files access" settings page
for FileExpo specifically.

## Next steps (not in this drop)

1. Smart search (type/extension/size/date filters).
2. Batch operations (rename/move/copy/delete) + selection mode.
3. Storage analyzer, archive support.
4. Vault, share sheet integration, home screen widgets.
5. Network client (SMB/FTP/SFTP/WebDAV) -> Nearby Share -> FTP server mode.
6. Root explorer, app manager/APK installer, USB OTG, junk cleaner.

# FileExpo Project Instructions

## Project Overview
FileExpo is a Flutter-based Android file explorer with a built-in text editor, image gallery, and audio player.

## Architectural Conventions
- **Framework:** Flutter (Android only).
- **UI:** Material 3.
- **State Management:** Simple `setState` or `ChangeNotifier` with `Provider`.
- **Directory Structure:**
  - `lib/screens/`: UI screens (Explorer, Editor, Gallery, Player).
  - `lib/services/`: Logic for file system, permissions, and media.
  - `lib/widgets/`: Reusable UI components.
  - `lib/models/`: Data models (if needed).
- **Naming Conventions:** Follow standard Flutter/Dart guidelines (PascalCase for classes, camelCase for variables/methods).

## Implementation Rules
- **Permissions:** Always handle `MANAGE_EXTERNAL_STORAGE` and `READ_EXTERNAL_STORAGE` gracefully.
- **Error Handling:** Use `try-catch` for all file operations and show user-friendly `SnackBar` messages.
- **Performance:** Use `ListView.builder` for directory listings to ensure smooth scrolling with many files.

## Dependencies
- `path_provider`: For accessing system directories.
- `permission_handler`: For managing Android permissions.
- `path`: For file path manipulations.
- `intl`: For date formatting.
- `photo_view`: For image zooming.
- `audioplayers`: For audio playback.
- `shared_preferences`: For favorites and settings.
- `share_plus`: For system-wide file sharing.
- `archive`: For ZIP/TAR compression and extraction.

## New Features (v1.1)
- **Batch Operations:** Long-press any file to enter selection mode. Select multiple files for bulk Delete, Share, Copy, or Move.
- **Clipboard:** Copy/Move files across directories using the global "Paste Here" button.
- **Archive Support:** Build-in ZIP creation (for multiple selected items) and extraction (single-click on a ZIP file).
- **Sharing:** Integration with Android's native share sheet.

## Media & Viewing Capabilities (v1.3)
- **Built-in Media Viewer/Player:** Integrated viewers for images, videos, audio, and PDF documents to avoid switching apps.
- **Text Editor:** A robust built-in editor for editing text and configuration files.

## Privacy & Security (v1.2)
- **Safe Folder (Vault):** A hidden, biometric-protected folder for sensitive files.
- **AES Encryption:** Military-grade AES-256 encryption for individual files.
- **Strictly Ad-Free:** FileExpo is committed to a zero-ad policy. No ad SDKs, no tracking, and no analytics.

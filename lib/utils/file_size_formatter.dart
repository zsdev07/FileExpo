/// Formats a raw byte count the way the reference screenshots do
/// ("142 KB", "40.1 MB", "9.6 MB", ...).
class FileSizeFormatter {
  FileSizeFormatter._();

  static String format(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    double size = bytes / 1024;
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final decimals = size < 10 ? 1 : 0;
    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }
}

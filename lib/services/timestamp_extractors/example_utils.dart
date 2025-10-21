
/// max file size to read for exif/hash/anything
const maxFileSize = 64 * 1024 * 1024;

extension Z on String {
  /// Returns same string if pattern not found
  String replaceLast(String from, String to) {
    final lastIndex = lastIndexOf(from);
    if (lastIndex == -1) return this;
    return replaceRange(lastIndex, lastIndex + from.length, to);
  }
}

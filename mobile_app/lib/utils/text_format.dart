/// Text-formatting helpers to keep displayed strings consistent and
/// professional, regardless of how the data was originally entered
/// (e.g. medicine forms stored as `face_wash` or names typed in all
/// lowercase by a user).
extension TitleCaseX on String {
  /// Converts `hello world` / `HELLO WORLD` / `hello_world` into
  /// `Hello World`.
  String get toTitleCase {
    if (isEmpty) return this;
    final normalized = replaceAll('_', ' ').replaceAll('-', ' ');
    return normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Capitalizes only the first letter, leaving the rest untouched.
  /// Useful for free-text fields where the user's own casing should be
  /// respected apart from the leading letter.
  String get toSentenceCase {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}


class SemVer {
  static final RegExp _versionMatcher = RegExp(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$");
  static final RegExp _characterFilter = RegExp(r"^[a-zA-Z]+");
  final int major;
  final int minor;
  final int patch;
  final String? label;

  SemVer({required this.major, required this.minor, required this.patch, this.label});

  factory SemVer.fromString(String str) {
    str = str.replaceAll(_characterFilter, "");
    final match = _versionMatcher.firstMatch(str);
    if (match == null || match.group(1) == null) {
      throw "Invalid version format";
    }

    return SemVer(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2) ?? "0"),
      patch: int.parse(match.group(3) ?? "0"),
      label: match.group(4),
    );
  }

  factory SemVer.zero() {
    return SemVer(major: 0, minor: 0, patch: 0);
  }
  
  factory SemVer.max() {
    //Chosen because it is larger than any version this app will ever see but small enough to not look bad when displayed as text
    const max = 999;
    return SemVer(major: max, minor: max, patch: max);
  }

  bool get isZero => major == 0 && minor == 0 && patch == 0;

  bool get isNotZero => !isZero;

  @override
  String toString() {
    return "$major.$minor.$patch${label == null ? "" : "-$label"}";
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SemVer &&
              runtimeType == other.runtimeType &&
              major == other.major &&
              minor == other.minor &&
              patch == other.patch &&
              label == other.label;

  @override
  int get hashCode => major.hashCode ^ minor.hashCode ^ patch.hashCode ^ label.hashCode;

  bool operator >(SemVer other) {
    if (major > other.major || (major == other.major && minor > other.minor) || (major == other.major && minor == other.minor && patch > other.patch)) {
      return true;
    }
    return false;
  }

  bool operator >=(SemVer other) {
    if (this == other) return true;
    return this > other;
  }

  bool operator <(SemVer other) {
    return !(this > other);
  }

  bool operator <=(SemVer other) {
    if (this == other) return true;
    return this < other;
  }
}

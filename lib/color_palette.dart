import 'dart:ui';

class NeutralColors {
  const NeutralColors({required this.dark, required this.mid, required this.light});

  final Color dark;
  final Color mid;
  final Color light;

  Color operator [](String key) {
    switch (key) {
      case "dark":
        return dark;
      case "mid":
        return mid;
      case "light":
        return light;
      default:
        return mid;
    }
  }

  Color getColor(String? key) {
    if (key == null) return mid;
    switch (key) {
      case "dark":
        return dark;
      case "mid":
        return mid;
      case "light":
        return light;
      default:
        return mid;
    }
  }

  Map<String, Color> toMap() {
    return {
      "dark": dark,
      "mid": mid,
      "light": light,
    };
  }
}

class ColorSet {
  const ColorSet({
    required this.yellow,
    required this.green,
    required this.red,
    required this.purple,
    required this.cyan,
    required this.orange,
  });

  final Color yellow;
  final Color green;
  final Color red;
  final Color purple;
  final Color cyan;
  final Color orange;

  Color operator [](String key) {
    switch (key) {
      case "yellow":
        return yellow;
      case "green":
        return green;
      case "red":
        return red;
      case "purple":
        return purple;
      case "cyan":
        return cyan;
      case "orange":
        return orange;
      default:
        return yellow;
    }
  }

  Color getColor(String? key) {
    if (key == null) return yellow;
    switch (key) {
      case "yellow":
        return yellow;
      case "green":
        return green;
      case "red":
        return red;
      case "purple":
        return purple;
      case "cyan":
        return cyan;
      case "orange":
        return orange;
      default:
        return yellow;
    }
  }

  Map<String, Color> toMap() {
    return {
      "yellow": yellow,
      "green": green,
      "red": red,
      "purple": purple,
      "cyan": cyan,
      "orange": orange,
    };
  }
}

class ColorPalette {
  const ColorPalette({
    required this.neutrals,
    required this.hero,
    required this.mid,
    required this.sub,
    required this.dark,
  });

  final NeutralColors neutrals;
  final ColorSet hero;
  final ColorSet mid;
  final ColorSet sub;
  final ColorSet dark;

  Map<String, Color> toMap() {
    return {
      "neutrals": neutrals.toMap(),
      "hero": hero.toMap(),
      "mid": mid.toMap(),
      "sub": sub.toMap(),
      "dark": dark.toMap(),
    }.entries.where((e) => e.key != "mid").fold(
      {},
      (acc, e) => acc..addAll(e.value.map((key, value) => MapEntry("${e.key}.$key", value))),
    );
  }
}

const ColorPalette palette = ColorPalette(
  neutrals: NeutralColors(
    dark: Color(0xFF11151D),
    mid: Color(0xFF86888B),
    light: Color(0xFFE1E1E0),
  ),
  hero: ColorSet(
    yellow: Color(0xFFF8F770),
    green: Color(0xFF59EB5C),
    red: Color(0xFFFF7676),
    purple: Color(0xFFBA64F2),
    cyan: Color(0xFF61D1FA),
    orange: Color(0xFFE69E50),
  ),
  mid: ColorSet(
    yellow: Color(0xFFA0A14E),
    green: Color(0xFF3F9E44),
    red: Color(0xFFAE5458),
    purple: Color(0xFF824AAB),
    cyan: Color(0xFF458FAB),
    orange: Color(0xFF976C3D),
  ),
  sub: ColorSet(
    yellow: Color(0xFF484A2C),
    green: Color(0xFF24512C),
    red: Color(0xFF5D323A),
    purple: Color(0xFF492F64),
    cyan: Color(0xFF284C5D),
    orange: Color(0xFF48392A),
  ),
  dark: ColorSet(
    yellow: Color(0xFF2B2E26),
    green: Color(0xFF192D24),
    red: Color(0xFF1A1318),
    purple: Color(0xFF241E35),
    cyan: Color(0xFF1A2A36),
    orange: Color(0xFF292423),
  ),
);

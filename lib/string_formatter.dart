import 'package:color/color.dart' as cc;
import 'package:flutter/material.dart';

class FormatNode {
  String? text;
  final FormatData format;
  final List<FormatNode> children;

  FormatNode({this.text, required this.format, required this.children});

  TextSpan toTextSpan({required TextStyle baseStyle}) {
    return TextSpan(
        text: text,
        style: format.isUnformatted ? baseStyle : format.style(baseStyle),
        children: children.map((e) => e.toTextSpan(baseStyle: baseStyle)).toList()
    );
  }

  static FormatNode buildFromStyles(List<FormatData> styles, String text) {
    if (styles.isEmpty) return FormatNode(format: FormatData.unformatted(), children: [], text: text);
    final root = FormatNode(format: styles.first, children: []);
    var current = root;
    for (final style in styles.sublist(1)) {
      final next = FormatNode(format: style, children: []);
      current.children.add(next);
      current = next;
    }
    current.text = text;
    return root;
  }
}

class StringFormatter {
  static TextSpan? tryFormat(String text, {TextStyle? baseStyle}) {
    try {
      final content = StringFormatter.format(text, baseStyle: baseStyle);
      if ((content.children?.isEmpty ?? true) && content.style == null) {
        return null;
      }
      return content;
    } catch (e) {
      rethrow;
    }
  }

  static TextSpan format(String text, {TextStyle? baseStyle}) {
    baseStyle ??= const TextStyle();
    var tags = parseTags(text);
    if (tags.isEmpty) return TextSpan(text: text, style: null, children: const []);
    final root = FormatNode(
      format: FormatData.unformatted(),
      text: text.substring(0, tags.first.startIndex),
      children: [],
    );

    final activeTags = <FormatData>[];

    for (int i = 0; i < tags.length; i++) {
      final tag = tags[i];
      final substr = text.substring(tag.endIndex, (i + 1 < tags.length) ? tags[i + 1].startIndex : null);
      if (tag.format.isAdditive) {
        activeTags.add(tag.format);
      } else {
        final idx = activeTags.lastIndexWhere((element) => element.name == tag.format.name);
        if (idx != -1) {
          activeTags.removeAt(idx);
        }
      }
      if (substr.isNotEmpty) {
        root.children.add(
            FormatNode.buildFromStyles(activeTags, substr)
        );
      }
    }
    return root.toTextSpan(baseStyle: baseStyle);
  }

  static List<FormatTag> parseTags(String text) {
    final startMatches = RegExp(r"<(.+?)>").allMatches(text);

    final spans = <FormatTag>[];

    for (final startMatch in startMatches) {
      final fullTag = startMatch.group(1);
      if (fullTag == null) continue;
      final tag = FormatData.parse(fullTag);
      spans.add(
          FormatTag(
            startIndex: startMatch.start,
            endIndex: startMatch.end,
            format: tag,
          )
      );
    }
    return spans;
  }
}

class FormatTag {
  final int startIndex;
  final int endIndex;
  final FormatData format;

  const FormatTag({
    required this.startIndex,
    required this.endIndex,
    required this.format,
  });
}

class FormatAction {
  final String Function(String input, String parameter)? transform;
  final TextStyle Function(String? parameter, TextStyle baseStyle)? style;

  FormatAction({this.transform, this.style});
}

class FormatData {
  static Color? tryParseColor(String? text) {
    if (text == null) return null;
    var color = cc.RgbColor.namedColors[text];
    if (color != null) {
      return Color.fromARGB(255, color.r.round(), color.g.round(), color.b.round());
    }
    try {
      color = cc.HexColor(text);
      return Color.fromARGB(255, color.r.round(), color.g.round(), color.b.round());
    } catch (_) {
      return null;
    }
  }

  static final Map<String, FormatAction> _richTextTags = {
    "align": FormatAction(),
    "alpha": FormatAction(style: (param, baseStyle) {
      if (param == null || !param.startsWith("#")) return baseStyle;
      final alpha = int.tryParse(param.substring(1), radix: 16);
      if (alpha == null) return baseStyle;
      return baseStyle.copyWith(color: baseStyle.color?.withAlpha(alpha));
    }),
    "color": FormatAction(style: (param, baseStyle) {
      if (param == null) return baseStyle;
      final color = tryParseColor(param);
      if (color == null) return baseStyle;
      return baseStyle.copyWith(color: color);
    }),
    "b": FormatAction(style: (param, baseStyle) => baseStyle.copyWith(fontWeight: FontWeight.bold)),
    "br": FormatAction(transform: (text, param) => "\n$text"),
    "i": FormatAction(style: (param, baseStyle) => baseStyle.copyWith(fontStyle: FontStyle.italic)),
    "cspace": FormatAction(),
    "font": FormatAction(),
    "indent": FormatAction(),
    "line-height": FormatAction(),
    "line-indent": FormatAction(),
    "link": FormatAction(),
    "lowercase": FormatAction(),
    "uppercase": FormatAction(),
    "smallcaps": FormatAction(),
    "margin": FormatAction(),
    "mark": FormatAction(style: (param, baseStyle) {
      if (param == null) return baseStyle;
      final color = tryParseColor(param);
      if (color == null) return baseStyle;
      return baseStyle.copyWith(backgroundColor: color);
    }),
    "mspace": FormatAction(),
    "noparse": FormatAction(),
    "nobr": FormatAction(),
    "page": FormatAction(),
    "pos": FormatAction(),
    "size": FormatAction(),
    "space": FormatAction(),
    "sprite": FormatAction(),
    "s": FormatAction(style: (param, baseStyle) => baseStyle.copyWith(decoration: TextDecoration.lineThrough)),
    "u": FormatAction(style: (param, baseStyle) => baseStyle.copyWith(decoration: TextDecoration.underline)),
    "style": FormatAction(),
    "sub": FormatAction(),
    "sup": FormatAction(),
    "voffset": FormatAction(),
    "width": FormatAction(),
  };

  final String name;
  final String parameter;
  final bool isAdditive;

  const FormatData({required this.name, required this.parameter, required this.isAdditive});

  factory FormatData.parse(String text) {
    if (text.contains("/")) return FormatData(name: text.replaceAll("/", ""), parameter: "", isAdditive: false);
    final sepIdx = text.indexOf("=");
    if (sepIdx == -1) {
      return FormatData(name: text, parameter: "", isAdditive: true);
    } else {
      return FormatData(
        name: text.substring(0, sepIdx).trim().toLowerCase(),
        parameter: text.substring(sepIdx + 1, text.length).trim().toLowerCase(),
        isAdditive: true,
      );
    }
  }

  factory FormatData.unformatted() => const FormatData(name: "", parameter: "", isAdditive: false);

  bool get isUnformatted => name.isEmpty && parameter.isEmpty && !isAdditive;

  bool get isValid => _richTextTags.containsKey(name);

  String? apply(String? text) => text == null ? null : _richTextTags[name]?.transform?.call(text, parameter);

  TextStyle style(TextStyle baseStyle) => _richTextTags[name]?.style?.call(parameter, baseStyle) ?? baseStyle;
}
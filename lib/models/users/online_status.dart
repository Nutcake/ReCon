import 'package:material_ui/material_ui.dart';

enum OnlineStatus {
  offline,
  invisible,
  away,
  busy,
  online,
  sociable;

  static final List<Color> _colors = [
    Colors.transparent,
    Colors.transparent,
    Colors.yellow,
    Colors.red,
    Colors.green,
    Colors.blue,
  ];

  Color color(BuildContext context) => this == OnlineStatus.offline || this == OnlineStatus.invisible
      ? Theme.of(context).colorScheme.onSecondaryContainer.withAlpha(150)
      : _colors[index];

  factory OnlineStatus.parse(Object? value) => switch (value) {
    int i when i >= 0 && i < OnlineStatus.values.length => OnlineStatus.values[i],
    String s => OnlineStatus.values.firstWhere((e) => e.name.toLowerCase() == s.toLowerCase(), orElse: () => OnlineStatus.offline),
    _ => OnlineStatus.offline,
  };


  int compareTo(OnlineStatus other) {
    if (this == other) return 0;
    if (this == OnlineStatus.sociable) return -1;
    if (other == OnlineStatus.sociable) return 1;
    if (this == OnlineStatus.online) return -1;
    if (other == OnlineStatus.online) return 1;
    if (this == OnlineStatus.away) return -1;
    if (other == OnlineStatus.away) return 1;
    if (this == OnlineStatus.busy) return -1;
    if (other == OnlineStatus.busy) return 1;
    return 0;
  }
}

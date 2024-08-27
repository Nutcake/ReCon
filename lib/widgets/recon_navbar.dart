import 'package:flutter/material.dart';
import 'package:recon/color_palette.dart';
import 'package:recon/widgets/blend_mask.dart';
import 'package:recon/widgets/translucent_glass.dart';

class _ReConNavigationContext extends InheritedWidget {
  const _ReConNavigationContext({
    required this.index,
    required this.selectedIndex,
    required this.animationController,
    required this.onTap,
    required super.child,
  });

  final int index;
  final int selectedIndex;
  final AnimationController animationController;
  final VoidCallback onTap;

  static _ReConNavigationContext of(BuildContext context) {
    final _ReConNavigationContext? result = context.dependOnInheritedWidgetOfExactType<_ReConNavigationContext>();
    assert(
      result != null,
      'ReCon navigation destinations need a ReConNavigationContext parent, '
      'which must be accounted for by you.',
    );
    result?.initContext();
    return result!;
  }

  void initContext() {
    if (selectedIndex == index) {
      animationController.forward(from: 0);
    }
  }

  Animation<double> get selectedAnimation {
    return index == selectedIndex
        ? Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: animationController,
              curve: Curves.easeOut,
            ),
          )
        : kAlwaysDismissedAnimation;
  }

  @override
  bool updateShouldNotify(_ReConNavigationContext oldWidget) {
    return selectedIndex != oldWidget.selectedIndex || animationController != oldWidget.animationController;
  }
}

class ReConNavigationDestination extends StatelessWidget {
  final String label;
  final Widget icon;
  final String color;

  const ReConNavigationDestination({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final _ReConNavigationContext navContext = _ReConNavigationContext.of(context);
    final ThemeData theme = Theme.of(context);

    final Animation<double> animation = navContext.selectedAnimation;
    final DecorationTween iconBoxDecoration = DecorationTween(
      begin: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            theme.colorScheme.onSurface.withOpacity(0.1),
          ],
        ),
      ),
      end: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.hero[color].withOpacity(0),
            palette.hero[color].withOpacity(0.8),
          ],
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 48,
        child: InkWell(
          onTap: navContext.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BlendMask(
                blendMode: BlendMode.srcOver,
                child: SizedBox(
                  width: 58,
                  height: 31,
                  child: DecoratedBoxTransition(
                    decoration: iconBoxDecoration.animate(animation),
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(
                          color: palette.hero[color],
                          size: 24,
                        ),
                        child: icon,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 68,
                decoration: BoxDecoration(
                  color: palette.mid[color],
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                ),
                child: AnimatedDefaultTextStyle(
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  duration: const Duration(milliseconds: 100),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReConNavigationBar extends StatelessWidget {
  const ReConNavigationBar({
    super.key,
    required this.animationController,
    required this.selectedIndex,
    required this.destinations,
    this.onDestinationSelected,
  });

  final AnimationController animationController;
  final int selectedIndex;
  final List<ReConNavigationDestination> destinations;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return TranslucentGlass.bottomNavBar(
      context,
      gradient: TranslucentGlass.defaultBottomGradient(context),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(top: 8, bottom: 16, left: 8, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: destinations
              .map(
                (e) => _ReConNavigationContext(
                    index: destinations.indexOf(e),
                    selectedIndex: selectedIndex,
                    animationController: animationController,
                    onTap: () {
                      if (onDestinationSelected != null) onDestinationSelected!(destinations.indexOf(e));
                    },
                    child: e),
              )
              .toList(),
        ),
      ),
    );
  }
}

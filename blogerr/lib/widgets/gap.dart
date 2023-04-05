import 'package:flutter/widgets.dart';

class Gap extends StatelessWidget {
  const Gap(
    this.size, {
    super.key,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    bool isParentVertical = false;

    final scrollableState = Scrollable.maybeOf(context);
    final AxisDirection? axisDirection = scrollableState?.axisDirection;
    if (axisDirection != null) {
      isParentVertical = axisDirection == AxisDirection.down ||
          axisDirection == AxisDirection.up;
    } else {
      context.visitAncestorElements((element) {
        isParentVertical = (element.widget is Column);
        return false; // stop visiting
      });
    }

    return SizedBox.fromSize(
        size: Size(isParentVertical ? 0 : size, isParentVertical ? size : 0));
  }
}

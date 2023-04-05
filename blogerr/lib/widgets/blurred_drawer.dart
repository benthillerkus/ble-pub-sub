import 'dart:math';
import 'dart:ui';

import 'package:blogerr/widgets/gap.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../main.dart';

class BlurredDrawer extends HookConsumerWidget {
  const BlurredDrawer({
    super.key,
    this.radius = kExtremeRadius,
  });

  final Radius radius;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderRadius = Directionality.of(context) == TextDirection.ltr
        ? BorderRadius.only(topRight: radius, bottomRight: radius)
        : BorderRadius.only(topLeft: radius, bottomLeft: radius);

    return Padding(
      padding: EdgeInsets.only(
          top: Theme.of(context).appBarTheme.toolbarHeight ?? 56.0, bottom: 16),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: 10, sigmaY: 10, tileMode: TileMode.clamp),
            child: Drawer(
                // shape: RoundedRectangleBorder(borderRadius: borderRadius),
                backgroundColor:
                    Theme.of(context).colorScheme.background.withOpacity(0.8),
                elevation: 4,
                width:
                    MediaQuery.of(context).orientation == Orientation.landscape
                        ? 500
                        : MediaQuery.of(context).size.width * 0.9,
                child: Padding(
                    padding: EdgeInsets.all(max(radius.x, radius.y)),
                    child: Column(
                      children: [
                        Text("HAMBURGERS",
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground)),
                        const Gap(16),
                        const Expanded(
                            child: FlutterLogo(
                          size: 500,
                        )),
                      ],
                    )))),
      ),
    );
  }
}

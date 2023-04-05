import 'package:flutter/material.dart';

class PhantomIcon extends StatelessWidget {
  const PhantomIcon({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
      size: Size.fromRadius(Theme.of(context).iconTheme.size ?? 24.0));
}

class PhantomIconButton extends StatelessWidget {
  const PhantomIconButton({super.key});

  static Size size(BuildContext context) => Size.fromRadius(Theme.of(context)
          .iconButtonTheme
          .style
          ?.iconSize
          ?.resolve(<MaterialState>{}) ??
      20.0);

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(size: size(context));
}

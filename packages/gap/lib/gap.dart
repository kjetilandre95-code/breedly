import 'package:flutter/widgets.dart';

class Gap extends StatelessWidget {
  final double mainAxisExtent;

  const Gap(this.mainAxisExtent, {super.key});

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable?.axis == Axis.horizontal) {
      return SizedBox(width: mainAxisExtent);
    }
    return SizedBox(height: mainAxisExtent);
  }
}

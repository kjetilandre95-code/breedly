import 'package:flutter/widgets.dart';

class Gap extends StatelessWidget {
  final double mainAxisExtent;

  const Gap(this.mainAxisExtent, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: mainAxisExtent,
      height: mainAxisExtent,
    );
  }
}

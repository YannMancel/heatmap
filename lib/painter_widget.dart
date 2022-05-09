import 'package:flutter/material.dart';

class PainterWidget extends StatelessWidget {
  const PainterWidget({
    Key? key,
    this.size = const Size(300.0, 150.0),
  }) : super(key: key);

  final Size size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: const HeatMapPainter(),
    );
  }
}

class HeatMapPainter extends CustomPainter {
  const HeatMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    late Rect rect;

    const widthItemsNumber = 50;
    const heightItemsNumber = 40;

    final itemWidth = size.width / widthItemsNumber.toDouble();
    final itemHeight = size.height / heightItemsNumber.toDouble();

    for (int i = 0; i < widthItemsNumber; i++) {
      for (int j = 0; j < heightItemsNumber; j++) {
        rect = Rect.fromLTWH(
          i * itemWidth,
          j * itemHeight,
          itemWidth,
          itemHeight,
        );

        canvas
          ..drawRect(rect, Paint()..color = Colors.red)
          ..drawRect(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0,
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

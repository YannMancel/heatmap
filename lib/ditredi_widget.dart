import 'package:ditredi/ditredi.dart' as ditredi;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

const kCountX = 50;
const kCountY = 30;

class DitrediWidget extends StatefulWidget {
  const DitrediWidget({
    Key? key,
    this.size = const Size(300.0, 150.0),
  }) : super(key: key);

  final Size size;

  @override
  State<DitrediWidget> createState() => _DitrediWidgetState();
}

class _DitrediWidgetState extends State<DitrediWidget> {
  final _points = _generatePoints().toList();
  final _triangles = _generateTriangles().toList();
  final _lines = _generateLines().toList();

  final _controller = ditredi.DiTreDiController(
    rotationX: 0.0,
    rotationY: 0.0,
    userScale: 3,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: widget.size,
      child: ditredi.DiTreDi(
        controller: _controller,
        figures: <ditredi.Model3D>[
          ..._points,
          ..._triangles,
          ..._lines,
        ],
        // disable z index to boost drawing performance
        // for wireframes and points
        config: const ditredi.DiTreDiConfig(
          supportZIndex: false,
          perspective: false,
        ),
      ),
    );
  }
}

Iterable<ditredi.Point3D> _generatePoints({
  int countX = kCountX,
  int countY = kCountY,
  double factorX = 1.0,
  double factorY = 1.0,
}) sync* {
  for (var x = 0; x < countX; x++) {
    for (var y = 0; y < countY; y++) {
      yield ditredi.Point3D(
        vector.Vector3(
          x.toDouble() * factorX,
          y.toDouble() * factorY,
          0.0,
        ),
        color: Colors.red,
      );
    }
  }
}

Iterable<ditredi.Face3D> _generateTriangles() sync* {
  yield ditredi.Face3D(
    vector.Triangle.points(
      vector.Vector3(0.0, 0.0, 0.0),
      vector.Vector3((kCountX / 2.0).ceil().toDouble(), 0.0, 0.0),
      vector.Vector3(0.0, (kCountY / 2.0).ceil().toDouble(), 0.0),
    ),
    color: Colors.green,
  );
}

Iterable<ditredi.Line3D> _generateLines() sync* {
  late ditredi.Line3D line;

  for (var x = 0; x < 4; x++) {
    switch (x) {
      case 0:
        line = ditredi.Line3D(
          vector.Vector3(0.0, 0.0, 0.0),
          vector.Vector3(kCountX - 1, 0.0, 0.0),
          width: 1.0,
          color: Colors.blue,
        );
        break;

      case 1:
        line = ditredi.Line3D(
          vector.Vector3(kCountX - 1, 0.0, 0.0),
          vector.Vector3(kCountX - 1, kCountY - 1, 0.0),
          width: 1.0,
          color: Colors.blue,
        );
        break;

      case 2:
        line = ditredi.Line3D(
          vector.Vector3(kCountX - 1, kCountY - 1, 0.0),
          vector.Vector3(0.0, kCountY - 1, 0.0),
          width: 1.0,
          color: Colors.blue,
        );
        break;

      case 3:
        line = ditredi.Line3D(
          vector.Vector3(0.0, kCountY - 1, 0.0),
          vector.Vector3(0.0, 0.0, 0.0),
          width: 1.0,
          color: Colors.blue,
        );
        break;
    }

    yield line;
  }
}

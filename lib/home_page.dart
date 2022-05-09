import 'package:flutter/material.dart';
import 'package:heatmap/heatmap.dart';
import 'package:heatmap/painter_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const <Widget>[
            PainterWidget(),
            HeatMap(),
          ],
        ),
      ),
    );
  }
}

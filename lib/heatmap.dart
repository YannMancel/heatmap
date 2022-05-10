import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart' as GL;
import 'package:three_dart/three_dart.dart' as THREE;

class Heatmap extends StatefulWidget {
  const Heatmap({
    Key? key,
    this.size = const Size(300.0, 200.0),
  }) : super(key: key);

  final Size size;

  @override
  State<Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<Heatmap> {
  late bool _isCompletedSetup;
  late GL.FlutterGlPlugin _three3dRender;
  late double _devicePixelRatio;
  THREE.WebGLRenderer? _renderer;
  late THREE.Camera _camera;
  late THREE.Scene _scene;
  late THREE.WebGLMultisampleRenderTarget _renderTarget;
  dynamic _sourceTexture;

  void _initOpenGl(BuildContext context) {
    if (_isCompletedSetup) return;

    _devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    _isCompletedSetup = true;

    _initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initPlatformState() async {
    _three3dRender = GL.FlutterGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": false,
      "width": widget.size.width.toInt(),
      "height": widget.size.height.toInt(),
      "dpr": _devicePixelRatio
    };

    await _three3dRender.initialize(options: _options);

    setState(() {});

    // Web must wait DOM
    Future.delayed(const Duration(milliseconds: 100), () async {
      await _three3dRender.prepareContext();
      await _initScene();
    });
  }

  Future<void> _initScene() async {
    _initRenderer();
    await _initPage();
  }

  void _initRenderer() {
    Map<String, dynamic> _options = {
      "width": widget.size.width,
      "height": widget.size.height,
      "gl": _three3dRender.gl,
      "antialias": true,
      "canvas": _three3dRender.element
    };

    _renderer = THREE.WebGLRenderer(_options);
    _renderer!.setPixelRatio(_devicePixelRatio);
    _renderer!.setSize(widget.size.width, widget.size.height, false);
    _renderer!.shadowMap.enabled = true;

    if (!kIsWeb) {
      final parser = THREE.WebGLRenderTargetOptions(
        <String, dynamic>{"format": THREE.RGBAFormat},
      );
      _renderTarget = THREE.WebGLMultisampleRenderTarget(
        (widget.size.width * _devicePixelRatio).toInt(),
        (widget.size.height * _devicePixelRatio).toInt(),
        parser,
      );
      _renderTarget.samples = 4;
      _renderer!.setRenderTarget(_renderTarget);
      _sourceTexture = _renderer!.getRenderTargetGLTexture(_renderTarget);
    }
  }

  Future<void> _initPage() async {
    _camera = THREE.PerspectiveCamera(
      20,
      widget.size.width / widget.size.height,
      1,
      10000,
    );
    _camera.position.z = 1800.0;

    _scene = THREE.Scene();
    _scene.background = THREE.Color.fromHex(0xffffff);

    final light = THREE.DirectionalLight(0xffffff);
    light.position.set(0, 0, 1);
    _scene.add(light);

    final shadowMaterial = THREE.MeshBasicMaterial({});
    final shadowGeo = THREE.PlaneGeometry(300, 300, 1, 1);

    THREE.Mesh shadowMesh;

    shadowMesh = THREE.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.rotation.x = -THREE.Math.PI / 2;
    _scene.add(shadowMesh);

    const _kRadius = 200;
    var geometry1 = THREE.IcosahedronGeometry(_kRadius, 1);

    final count = geometry1.attributes["position"].count;
    geometry1.setAttribute(
        'color', THREE.Float32BufferAttribute(GL.Float32Array(count * 3), 3));

    final geometry2 = geometry1.clone();
    final geometry3 = geometry1.clone();

    final color = THREE.Color(1, 1, 1);
    final positions1 = geometry1.attributes["position"];
    final positions2 = geometry2.attributes["position"];
    final positions3 = geometry3.attributes["position"];
    final colors1 = geometry1.attributes["color"];
    final colors2 = geometry2.attributes["color"];
    final colors3 = geometry3.attributes["color"];

    for (var i = 0; i < count; i++) {
      color.setHSL((positions1.getY(i) / _kRadius + 1) / 2, 1.0, 0.5);
      colors1.setXYZ(i, color.r, color.g, color.b);

      color.setHSL(0, (positions2.getY(i) / _kRadius + 1) / 2, 0.5);
      colors2.setXYZ(i, color.r, color.g, color.b);

      color.setRGB(1, 0.8 - (positions3.getY(i) / _kRadius + 1) / 2, 0);
      colors3.setXYZ(i, color.r, color.g, color.b);
    }

    final material = THREE.MeshPhongMaterial({
      "color": 0xffffff,
      "flatShading": true,
      "vertexColors": true,
      "shininess": 0
    });

    final wireframeMaterial = THREE.MeshBasicMaterial({
      "color": 0x000000,
      "wireframe": true,
      "transparent": true,
    });

    var mesh = THREE.Mesh(geometry1, material);
    var wireframe = THREE.Mesh(geometry1, wireframeMaterial);
    mesh.add(wireframe);
    mesh.position.x = -400;
    mesh.rotation.x = -1.87;
    _scene.add(mesh);

    mesh = THREE.Mesh(geometry2, material);
    wireframe = THREE.Mesh(geometry2, wireframeMaterial);
    mesh.add(wireframe);
    mesh.position.x = 400;
    _scene.add(mesh);

    mesh = THREE.Mesh(geometry3, material);
    wireframe = THREE.Mesh(geometry3, wireframeMaterial);
    mesh.add(wireframe);
    _scene.add(mesh);

    _render();
  }

  void _render() {
    _renderer!.render(_scene, _camera);
    _three3dRender.gl.flush();

    if (!kIsWeb) _three3dRender.updateTexture(_sourceTexture);
  }

  @override
  void initState() {
    super.initState();
    _isCompletedSetup = false;
    _devicePixelRatio = 1.0;
  }

  @override
  void dispose() {
    _three3dRender.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: widget.size,
      child: Builder(
        builder: (context) {
          _initOpenGl(context);

          return _three3dRender.isInitialized
              ? kIsWeb
                  ? HtmlElementView(
                      viewType: _three3dRender.textureId!.toString(),
                    )
                  : Texture(textureId: _three3dRender.textureId!)
              : const ColoredBox(color: Colors.black);
        },
      ),
    );
  }
}

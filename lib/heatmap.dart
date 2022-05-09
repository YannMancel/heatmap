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

  int? fboId;
  late THREE.Scene scene;
  late THREE.Camera camera;
  late THREE.Mesh mesh;
  late THREE.PointLight pointLight;
  var objects = [], materials = [];

  var AMOUNT = 4;
  bool verbose = true;
  late THREE.Object3D object;
  late THREE.Texture texture;
  late THREE.WebGLMultisampleRenderTarget renderTarget;
  THREE.AnimationMixer? mixer;
  dynamic sourceTexture;

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
      renderTarget = THREE.WebGLMultisampleRenderTarget(
        (widget.size.width * _devicePixelRatio).toInt(),
        (widget.size.height * _devicePixelRatio).toInt(),
        parser,
      );
      renderTarget.samples = 4;
      _renderer!.setRenderTarget(renderTarget);
      sourceTexture = _renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  Future<void> _initPage() async {
    camera = THREE.PerspectiveCamera(
      20,
      widget.size.width / widget.size.height,
      1,
      10000,
    );
    camera.position.z = 1800;

    scene = THREE.Scene();
    scene.background = THREE.Color.fromHex(0xffffff);

    var light = THREE.DirectionalLight(0xffffff);
    light.position.set(0, 0, 1);
    scene.add(light);

    // shadow

    // var canvas = document.createElement( 'canvas' );
    // canvas.width = 128;
    // canvas.height = 128;

    // var context = canvas.getContext( '2d' );
    // var gradient = context.createRadialGradient( canvas.width / 2, canvas.height / 2, 0, canvas.width / 2, canvas.height / 2, canvas.width / 2 );
    // gradient.addColorStop( 0.1, 'rgba(210,210,210,1)' );
    // gradient.addColorStop( 1, 'rgba(255,255,255,1)' );

    // context.fillStyle = gradient;
    // context.fillRect( 0, 0, canvas.width, canvas.height );

    // var shadowTexture = new THREE.CanvasTexture( canvas );

    var shadowMaterial = THREE.MeshBasicMaterial({});
    var shadowGeo = THREE.PlaneGeometry(300, 300, 1, 1);

    THREE.Mesh shadowMesh;

    shadowMesh = THREE.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.rotation.x = -THREE.Math.PI / 2;
    scene.add(shadowMesh);

    shadowMesh = THREE.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.position.x = -400;
    shadowMesh.rotation.x = -THREE.Math.PI / 2;
    scene.add(shadowMesh);

    shadowMesh = THREE.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.position.x = 400;
    shadowMesh.rotation.x = -THREE.Math.PI / 2;
    scene.add(shadowMesh);

    var radius = 200;

    var geometry1 = THREE.IcosahedronGeometry(radius, 1);

    var count = geometry1.attributes["position"].count;
    geometry1.setAttribute(
        'color', THREE.Float32BufferAttribute(GL.Float32Array(count * 3), 3));

    var geometry2 = geometry1.clone();
    var geometry3 = geometry1.clone();

    var color = THREE.Color(1, 1, 1);
    var positions1 = geometry1.attributes["position"];
    var positions2 = geometry2.attributes["position"];
    var positions3 = geometry3.attributes["position"];
    var colors1 = geometry1.attributes["color"];
    var colors2 = geometry2.attributes["color"];
    var colors3 = geometry3.attributes["color"];

    for (var i = 0; i < count; i++) {
      color.setHSL((positions1.getY(i) / radius + 1) / 2, 1.0, 0.5);
      colors1.setXYZ(i, color.r, color.g, color.b);

      color.setHSL(0, (positions2.getY(i) / radius + 1) / 2, 0.5);
      colors2.setXYZ(i, color.r, color.g, color.b);

      color.setRGB(1, 0.8 - (positions3.getY(i) / radius + 1) / 2, 0);
      colors3.setXYZ(i, color.r, color.g, color.b);
    }

    var material = THREE.MeshPhongMaterial({
      "color": 0xffffff,
      "flatShading": true,
      "vertexColors": true,
      "shininess": 0
    });

    var wireframeMaterial = THREE.MeshBasicMaterial(
        {"color": 0x000000, "wireframe": true, "transparent": true});

    var mesh = THREE.Mesh(geometry1, material);
    var wireframe = THREE.Mesh(geometry1, wireframeMaterial);
    mesh.add(wireframe);
    mesh.position.x = -400;
    mesh.rotation.x = -1.87;
    scene.add(mesh);

    mesh = THREE.Mesh(geometry2, material);
    wireframe = THREE.Mesh(geometry2, wireframeMaterial);
    mesh.add(wireframe);
    mesh.position.x = 400;
    scene.add(mesh);

    mesh = THREE.Mesh(geometry3, material);
    wireframe = THREE.Mesh(geometry3, wireframeMaterial);
    mesh.add(wireframe);
    scene.add(mesh);

    // scene.overrideMaterial = new THREE.MeshBasicMaterial();

    _render();
  }

  void _render() {
    int _t = DateTime.now().millisecondsSinceEpoch;

    final _gl = _three3dRender.gl;

    _renderer!.render(scene, camera);

    int _t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${_t1 - _t} ");
      print(_renderer!.info.memory);
      print(_renderer!.info.render);
    }

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
    _gl.flush();

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      _three3dRender.updateTexture(sourceTexture);
    }
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

  generateTexture() {
    var pixels = GL.Uint8Array(256 * 256 * 4);

    var x = 0, y = 0, l = pixels.length;

    for (var i = 0, j = 0; i < l; i += 4, j++) {
      x = j % 256;
      y = (x == 0) ? y + 1 : y;

      pixels[i] = 255;
      pixels[i + 1] = 255;
      pixels[i + 2] = 255;
      pixels[i + 3] = THREE.Math.floor(x ^ y);
    }

    return THREE.ImageElement(data: pixels, width: 256, height: 256);
  }

  addMesh(geometry, material) {
    var mesh = THREE.Mesh(geometry, material);

    mesh.position.x = (objects.length % 4) * 200 - 400;
    mesh.position.z = THREE.Math.floor(objects.length / 4) * 200 - 200;

    mesh.rotation.x = THREE.Math.random() * 200 - 100;
    mesh.rotation.y = THREE.Math.random() * 200 - 100;
    mesh.rotation.z = THREE.Math.random() * 200 - 100;

    objects.add(mesh);

    scene.add(mesh);
  }
}

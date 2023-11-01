import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'Home.dart';


class YoloVideo extends StatefulWidget {
  const YoloVideo({Key? key}) : super(key: key);

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late CameraController controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    init();
    initTts();
    //speak("Welcome to the app");
  }

  Future<void> initTts() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.awaitSpeakCompletion(true);
    flutterTts.stop();
  }

  Future<void> speak(String text) async {
    await flutterTts.setSpeechRate(0.3);
    await flutterTts.speak(text);
  }

  init() async {
    cameras = await availableCameras();
    vision = FlutterVision();
    controller = CameraController(cameras[0], ResolutionPreset.high);
    controller.initialize().then((value) {
      loadYoloModel().then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = false;
          yoloResults = [];
        });
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
    controller.dispose();
    await vision.closeYoloModel();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Camera'),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(
                controller,
              ),
            ),
            ...displayBoxesAroundRecognizedObjects(size),
            Positioned(
              bottom: 75,
              width: MediaQuery.of(context).size.width,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      width: 5, color: Colors.white, style: BorderStyle.solid),
                ),
                child: isDetecting
                    ? IconButton(
                  onPressed: () async {
                    stopDetection();
                  },
                  icon: const Icon(
                    Icons.stop,
                    color: Colors.red,
                  ),
                  iconSize: 50,
                )
                    : IconButton(
                  onPressed: () async {
                    await startDetection();
                    await speak("Now you can detect currency");
                  },
                  icon: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                  ),
                  iconSize: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
        labels: 'assets/labels.txt',
        modelPath: 'assets/large_epoch_float32.tflite',
        modelVersion: "yolov8",
        numThreads: 1,
        useGpu: false);
    setState(() {
      isLoaded = true;
    });
  }



  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
    //await speak("Detection started");
    await speak("Now you can detect currency");
    await flutterTts.setSilence(5);
    stopDetection();
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
    await speak("Stop Detection");
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });

      int count = result.length;
      String numofobjects = "'you have $count objects'";
      speak(numofobjects);

      Future.delayed(const Duration(seconds: 2)).then((_) async {

        String allresult = "";
        for (var i = 0; i < result.length; i++) {
          allresult += "'I see a ${result[i]["tag"]}' ";
        }
        await speak(allresult);
      });



    }
  }
  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}

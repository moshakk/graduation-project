import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'Home.dart';
import 'app_color.dart';

class YoloImage extends StatefulWidget {
  const YoloImage({Key? key}) : super(key: key);

  @override
  State<YoloImage> createState() => _YoloImageState();
}

class _YoloImageState extends State<YoloImage> {
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  File? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    loadYoloModel().then((value) {
      setState(() {
        yoloResults = [];
        isLoaded = true;
      });
    });
    pickImage(); // call this function when call YoloImage
  }

  @override
  void dispose() async {
    super.dispose();
    await vision.closeYoloModel();
  }

  Future<void> speak(String text) async {
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (imageFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          imageFile != null ? Image.file(imageFile!) : const SizedBox(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                child: Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Add your icon here
                  Icon(Icons.camera_alt,
                      size: 250.0, color: Colors.white.withOpacity(0.3)),
                  GestureDetector(
                    onTap: yoloOnImage,
                    onDoubleTap: pickImage,
                    behavior: HitTestBehavior.translucent,
                  ),
                ],
              ),
            )),
          ),
          ...displayBoxesAroundRecognizedObjects(size),
        ],
      );
    } else if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    } else {
      return GestureDetector(
        onTap: pickImage,
        child: Container(
          color: Colors.white,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera,
                  color: AppColors.colorApp2, // Change color here if needed
                  size: 320, // Change size here if needed
                ),
              ],
            ),
          ),
        ),
      );
    }
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

  Future<void> pickImage() async {
    Future.delayed(const Duration(seconds: 1)).then((_) async {
      const String speech = "Please press to side button to take image ,"
          "then click on the check mark located at the upper right of the page";
      await speak(speech);
    });

    final ImagePicker picker = ImagePicker();
    // Capture a photo
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        imageFile = File(photo.path);

        Future.delayed(const Duration(seconds: 2)).then((_) {
          yoloOnImage();
          //speak("Image is ready now to detect ");
        });
      });
    } else {
      await flutterTts.stop();
    }
  }

  yoloOnImage() async {
    //speak("Now you taked image");
    yoloResults.clear();
    Uint8List byte = await imageFile!.readAsBytes();
    final image = await decodeImageFromList(byte);
    imageHeight = image.height;
    imageWidth = image.width;
    final result = await vision.yoloOnImage(
        bytesList: byte,
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.8,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
      int count = result.length;
      String numofobjects = "'you have $count objects'";
      await speak(numofobjects);
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        String allresult = "";
        for (var i = 0; i < result.length; i++) {
          allresult += "'I see a ${result[i]["tag"]}' ";
        }
        await speak(
            "${allresult}please click once to hear the result again.  Or double click  to detect another object .");
      });
    } else {
      speak(
          "No objects detected in the image. Please select another image by double click .");
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / (imageWidth);
    double imgRatio = imageWidth / imageHeight;
    double newWidth = imageWidth * factorX;
    double newHeight = newWidth / imgRatio;
    double factorY = newHeight / (imageHeight);

    double pady = (screen.height - newHeight) / 2;

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);
    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY + pady,
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

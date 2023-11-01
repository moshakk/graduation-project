import 'dart:async';
import 'package:currency_detection/Home.dart';
import 'package:currency_detection/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();

    flutterTts.setLanguage("en-US");

    flutterTts.speak("Welcome to Currency detection app");

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = Tween<Offset>(
      begin: const Offset(1.0, 5.0), // Start the animation from the bottom
      end: Offset.zero, // Move the animation to the center
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Timer(
      const Duration(seconds: 4),
          () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1700), () {
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorApp1,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.colorApp1,
          statusBarIconBrightness: Brightness.dark,
        ),
        backgroundColor: AppColors.colorApp1,
        elevation: 0,
      ),
      body: Center(
        child: SlideTransition(
          position: _animation,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 2300),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (BuildContext context, double opacity, Widget? child) {
              return Opacity(
                opacity: opacity,
                child: child,
              );
            },
            child: const Text(
              'Currency Detection App',
              style: TextStyle(
                color: AppColors.colorApp3,
                fontSize: 27.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


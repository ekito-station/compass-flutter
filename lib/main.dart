import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Compass Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Compass Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ユーザの位置
  Position myPosition = Position(
    // 初期座標（ひとまず渋谷駅の座標）
    latitude: 35.658199,
    longitude: 139.701625,
    timestamp: DateTime.now(),
    altitude: 0,
    accuracy: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    floor: null,
  );
  late StreamSubscription<Position> myPositionStream;
  late double? deviceDirection;

  // 目標地点の位置
  Position markerPosition = Position(
    // （例）新宿駅の座標
    latitude: 35.689702,
    longitude: 139.700560,
    timestamp: DateTime.now(),
    altitude: 0,
    accuracy: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    floor: null,
  );
  late double markerDirection;
  double directionTolerance = 5.0;

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  // startPositionから見たendPositionの方角を計算
  double calcDirection(Position startPosition, Position endPosition) {
    double startLat = startPosition.latitude;
    double startLng = startPosition.longitude;
    double endLat = endPosition.latitude;
    double endLng = endPosition.longitude;
    double direction =
        Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
    if (direction < 0.0) {
      direction += 360.0;
    }
    return direction;
  }

  // direction1とdirection2の差が閾値未満か確認
  bool checkTolerance(double direction1, double direction2) {
    if ((direction1 - direction2).abs() < directionTolerance) {
      return true;
    } else if ((direction1 - direction2).abs() > 360 - directionTolerance) {
      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    // 位置情報サービスが許可されていない場合は許可をリクエストする
    Future(() async {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    });

    // ユーザの現在位置を取得し続ける
    myPositionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      myPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      // FlutterCompassのイベントをlistenする
      body: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error reading heading: ${snapshot.error}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // デバイスの向いている方角を取得
            deviceDirection = snapshot.data?.heading;
            if (deviceDirection == null) {
              return const Center(
                child: Text("Device does not have sensors."),
              );
            }

            // ユーザの現在位置から見た目標地点の方角を計算
            markerDirection = calcDirection(myPosition, markerPosition);

            return Center(
              child: Opacity(
                // デバイスの向いている方角と目標地点の方角の差が閾値未満の場合
                // opacityを1にしてwidgetを表示させる
                opacity: checkTolerance(deviceDirection!, markerDirection)
                    ? 1.0
                    : 0.0,
                child: const Icon(
                  Icons.expand_less,
                  size: 100,
                ),
              ),
            );
          }),
    );
  }
}

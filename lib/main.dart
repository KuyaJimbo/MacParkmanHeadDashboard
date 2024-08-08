import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'dart:async';
import 'sensor_view.dart';
import 'value_adjuster.dart';
import 'color_oscilloscope.dart';
import 'sensors_display.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SensorState(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Display',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<double> actualDataPoints = List.filled(450, 0.0);
  List<double> displayDataPoints = List.filled(900, 0.0);
  double lowThreshold = 2.0;
  double highThreshold = 4.0;
  int delayFrames = 50;
  double yMin = -5.0;
  double yMax = 5.0;

  double punchPower = 0.0;
  List<int> punchSequence = []; // New variable to store the punch sequence

  StateMachineController? _headRigController;
  SMINumber? _headRigYInput;

  Timer? _punchTimer;
  bool _isPunching = false;

  @override
  void initState() {
    super.initState();
    _startDataUpdate();
  }

  @override
  void dispose() {
    _punchTimer?.cancel();
    super.dispose();
  }

  void _startDataUpdate() {
    Future.delayed(Duration(milliseconds: 30), () {
      if (mounted) {
        _updateData();
        _startDataUpdate();
      }
    });
  }

  void _updateData() {
    setState(() {
      // Update actual data points
      actualDataPoints = List<double>.from(
          actualDataPoints.sublist(1)..add(actualDataPoints.last));

      // Update display data points
      displayDataPoints = [];
      for (var value in actualDataPoints) {
        displayDataPoints.add(value);
        displayDataPoints.add(0.0);
      }

      // Update yMin and yMax if necessary
      double maxAbsValue =
          displayDataPoints.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
      if (maxAbsValue > yMax.abs()) {
        yMax = maxAbsValue;
        yMin = -maxAbsValue;
      }

      // Update head rig Y input
      _headRigYInput?.value = actualDataPoints.last;
    });
  }

  void _updateCounter(double change) {
    setState(() {
      double newValue = actualDataPoints.last + change;
      actualDataPoints = List<double>.from(
          actualDataPoints.sublist(0, actualDataPoints.length - 1)
            ..add(newValue));

      // Update display data points
      displayDataPoints = [];
      for (var value in actualDataPoints) {
        displayDataPoints.add(value);
        displayDataPoints.add(0.0);
      }

      // Update yMin and yMax if necessary
      double maxAbsValue =
          displayDataPoints.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
      if (maxAbsValue > yMax.abs()) {
        yMax = maxAbsValue;
        yMin = -maxAbsValue;
      }

      // Update head rig Y input
      _headRigYInput?.value = newValue;
    });
  }

  void _recalibrate() {
    setState(() {
      actualDataPoints = List<double>.filled(actualDataPoints.length, 0.0);
      displayDataPoints = List<double>.filled(displayDataPoints.length, 0.0);
      yMin = -5.0;
      yMax = 5.0;
      _headRigYInput?.value = 0.0;
    });
  }

  void _simulatePunch() {
    if (_isPunching) {
      _punchTimer?.cancel();
      _isPunching = false;
      return;
    }

    _isPunching = true;
    _generatePunchSequence();
    int index = 0;

    _punchTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (index >= punchSequence.length || !_isPunching) {
        timer.cancel();
        _isPunching = false;
        return;
      }

      double value = punchSequence[index].toDouble();
      _updateCounter(value - actualDataPoints.last);

      index++;
    });
  }

  void _generatePunchSequence() {
    punchSequence = [];
    int power = punchPower.round();
    int currentMax = power;
    int currentMin = -power;

    while (currentMax > 0 || currentMin < 0) {
      // Positive to negative cycle
      for (int i = currentMax; i >= currentMin; i--) {
        punchSequence.add(i);
      }

      // Negative to positive cycle
      for (int i = currentMin + 1; i <= currentMax - 1; i++) {
        punchSequence.add(i);
      }

      // Update max and min for next cycle
      currentMax--;
      currentMin++;
    }

    // Add final oscillation to zero
    punchSequence.addAll([0]);
  }

  void _onHeadRigInit(Artboard artboard) {
    _headRigController =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (_headRigController != null) {
      artboard.addController(_headRigController!);
      _headRigYInput = _headRigController!.findInput<double>('Y') as SMINumber?;
      _headRigYInput?.value = actualDataPoints.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<double> alignedDelayedData =
        List<double>.filled(delayFrames * 2, 0.0) +
            displayDataPoints.sublist(
                0, displayDataPoints.length - delayFrames * 2);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          return Column(
            children: [
              // Header
              Container(
                height: 50,
                color: Colors.green,
                child: const Center(child: Text('Header')),
              ),
              // Body
              Expanded(
                child: isWide
                    ? _buildWideLayout(alignedDelayedData)
                    : _buildNarrowLayout(alignedDelayedData),
              ),
              // Footer
              _buildFooter(isWide),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(List<double> alignedDelayedData) {
    return Row(
      children: [
        // Sensor view
        const Expanded(
          flex: 1,
          child: SensorView(),
        ),
        // Blue (head rig)
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.blue,
            child: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RiveAnimation.asset(
                  'assets/head.riv',
                  fit: BoxFit.contain,
                  onInit: _onHeadRigInit,
                ),
              ),
            ),
          ),
        ),
        // Red (where the color oscilloscopes should go)
        Expanded(
          flex: 2,
          child: _buildOscilloscopes(alignedDelayedData),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(List<double> alignedDelayedData) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Sensor view
          const SizedBox(
            height: 300,
            child: SensorView(),
          ),
          // Blue (head rig)
          Container(
            height: 300,
            color: Colors.blue,
            child: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RiveAnimation.asset(
                  'assets/head.riv',
                  fit: BoxFit.contain,
                  onInit: _onHeadRigInit,
                ),
              ),
            ),
          ),
          // Red (where the color oscilloscopes should go)
          SizedBox(
            height: 600,
            child: _buildOscilloscopes(alignedDelayedData),
          ),
        ],
      ),
    );
  }

  Widget _buildOscilloscopes(List<double> alignedDelayedData) {
    return Container(
      color: Colors.red,
      child: Column(
        children: [
          SizedBox(height: 16),
          Expanded(
            child: ColorOscilloscope(
              name: 'External Sensor Data',
              dataPoints: displayDataPoints,
              lowThreshold: lowThreshold,
              highThreshold: highThreshold,
              yAxisMin: yMin,
              yAxisMax: yMax,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ColorOscilloscope(
              name: 'Internal Sensor Data (Delayed)',
              dataPoints: alignedDelayedData,
              lowThreshold: lowThreshold,
              highThreshold: highThreshold,
              yAxisMin: yMin,
              yAxisMax: yMax,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isWide) {
    return Container(
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isWide ? _buildWideFooterContent() : _buildNarrowFooterContent(),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _recalibrate,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Recalibrate'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _simulatePunch,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _isPunching ? Colors.orange : Colors.blue,
                  ),
                  child: Text(_isPunching ? 'Stop Punch' : 'Simulate Punch'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideFooterContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ValueAdjuster(
          label: 'Counter Value',
          value: actualDataPoints.last,
          changeBy: 1,
          onIncrement: _updateCounter,
          onDecrement: (value) => _updateCounter(-value),
          showSign: true,
        ),
        ValueAdjuster(
          label: 'Low Threshold',
          value: lowThreshold,
          changeBy: 1,
          onIncrement: (value) => setState(() => lowThreshold += value),
          onDecrement: (value) => setState(() => lowThreshold -= value),
        ),
        ValueAdjuster(
          label: 'High Threshold',
          value: highThreshold,
          changeBy: 1,
          onIncrement: (value) => setState(() => highThreshold += value),
          onDecrement: (value) => setState(() => highThreshold -= value),
        ),
        ValueAdjuster(
          label: 'Punch Power',
          value: punchPower,
          changeBy: 1,
          onIncrement: (value) => setState(() => punchPower += value),
          onDecrement: (value) => setState(() => punchPower -= value),
        ),
      ],
    );
  }

  Widget _buildNarrowFooterContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueAdjuster(
          label: 'Counter Value',
          value: actualDataPoints.last,
          changeBy: 0.25,
          onIncrement: _updateCounter,
          onDecrement: (value) => _updateCounter(-value),
          showSign: true,
        ),
        SizedBox(height: 10),
        ValueAdjuster(
          label: 'Low Threshold',
          value: lowThreshold,
          changeBy: 0.25,
          onIncrement: (value) => setState(() => lowThreshold += value),
          onDecrement: (value) => setState(() => lowThreshold -= value),
        ),
        SizedBox(height: 10),
        ValueAdjuster(
          label: 'High Threshold',
          value: highThreshold,
          changeBy: 0.25,
          onIncrement: (value) => setState(() => highThreshold += value),
          onDecrement: (value) => setState(() => highThreshold -= value),
        ),
        SizedBox(height: 10),
        ValueAdjuster(
          label: 'Punch Power',
          value: punchPower,
          changeBy: 0.25,
          onIncrement: (value) => setState(() => punchPower += value),
          onDecrement: (value) => setState(() => punchPower -= value),
        ),
      ],
    );
  }
}

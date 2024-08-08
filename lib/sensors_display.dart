import 'package:rive/rive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// State management class
class SensorState extends ChangeNotifier {
  StateMachineController? _sideViewController;
  StateMachineController? _faceController;

  bool _i1Active = false;
  bool _i2Active = false;
  bool _i3Active = false;
  bool _e1Active = false;
  bool _e2Active = false;
  bool _e3Active = false;

  bool get i1Active => _i1Active;
  bool get i2Active => _i2Active;
  bool get i3Active => _i3Active;
  bool get e1Active => _e1Active;
  bool get e2Active => _e2Active;
  bool get e3Active => _e3Active;

  bool getSensorState(String sensor) {
    switch (sensor) {
      case 'I1':
        return _i1Active;
      case 'I2':
        return _i2Active;
      case 'I3':
        return _i3Active;
      case 'E1':
        return _e1Active;
      case 'E2':
        return _e2Active;
      case 'E3':
        return _e3Active;
      default:
        return false;
    }
  }

  void setSideViewController(StateMachineController controller) {
    _sideViewController = controller;
    updateRiveInputs();
  }

  void setFaceController(StateMachineController controller) {
    _faceController = controller;
    updateRiveInputs();
  }

  void toggleSensor(String sensor) {
    bool changed = false;
    switch (sensor) {
      case 'I1':
        _i1Active = !_i1Active;
        changed = true;
        break;
      case 'I2':
        _i2Active = !_i2Active;
        changed = true;
        break;
      case 'I3':
        _i3Active = !_i3Active;
        changed = true;
        break;
      case 'E1':
        _e1Active = !_e1Active;
        changed = true;
        break;
      case 'E2':
        _e2Active = !_e2Active;
        changed = true;
        break;
      case 'E3':
        _e3Active = !_e3Active;
        changed = true;
        break;
    }
    if (changed) {
      updateRiveInputs();
      notifyListeners();
    }
  }

  void updateRiveInputs() {
    _updateSideViewRiveInputs();
    _updateFaceRiveInputs();
  }

  void _updateSideViewRiveInputs() {
    if (_sideViewController != null) {
      (_sideViewController!.findInput<bool>('I1_Active') as SMIBool?)?.value =
          _i1Active;
      (_sideViewController!.findInput<bool>('I2_Active') as SMIBool?)?.value =
          _i2Active;
      (_sideViewController!.findInput<bool>('I3_Active') as SMIBool?)?.value =
          _i3Active;
      (_sideViewController!.findInput<bool>('E1_Active') as SMIBool?)?.value =
          _e1Active;
      (_sideViewController!.findInput<bool>('E2_Active') as SMIBool?)?.value =
          _e2Active;
      (_sideViewController!.findInput<bool>('E3_Active') as SMIBool?)?.value =
          _e3Active;
    }
  }

  void _updateFaceRiveInputs() {
    if (_faceController != null) {
      (_faceController!.findInput<bool>('E1_Active') as SMIBool?)?.value =
          _e1Active;
      (_faceController!.findInput<bool>('E2_Active') as SMIBool?)?.value =
          _e2Active;
      (_faceController!.findInput<bool>('E3_Active') as SMIBool?)?.value =
          _e3Active;
    }
  }
}

class SensorDisplayWidget extends StatelessWidget {
  const SensorDisplayWidget({Key? key}) : super(key: key);

  Widget _buildButton(String label, bool isActive, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.green : Colors.red,
        minimumSize: Size(80, 50),
      ),
      child: Text(label),
    );
  }

  Widget _buildRiveAnimation(String asset, Function(Artboard) onInit) {
    return Container(
      width: 300,
      height: 300,
      child: RiveAnimation.asset(
        asset,
        fit: BoxFit.contain,
        onInit: onInit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorState>(
      builder: (context, sensorState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Sensor Display'),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  _buildRiveAnimation('assets/faceview.riv', (artboard) {
                    final controller = StateMachineController.fromArtboard(
                        artboard, 'State Machine 1');
                    artboard.addController(controller!);
                    sensorState.setFaceController(controller);
                    sensorState.updateRiveInputs();
                  }),
                  SizedBox(height: 20),
                  _buildRiveAnimation('assets/sideview.riv', (artboard) {
                    final controller = StateMachineController.fromArtboard(
                        artboard, 'State Machine 1');
                    artboard.addController(controller!);
                    sensorState.setSideViewController(controller);
                    sensorState.updateRiveInputs();
                  }),
                  SizedBox(height: 20),
                  Text('Internal Sensors', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton('I1', sensorState.i1Active,
                          () => sensorState.toggleSensor('I1')),
                      SizedBox(width: 10),
                      _buildButton('I2', sensorState.i2Active,
                          () => sensorState.toggleSensor('I2')),
                      SizedBox(width: 10),
                      _buildButton('I3', sensorState.i3Active,
                          () => sensorState.toggleSensor('I3')),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text('External Sensors', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton('E1', sensorState.e1Active,
                          () => sensorState.toggleSensor('E1')),
                      SizedBox(width: 10),
                      _buildButton('E2', sensorState.e2Active,
                          () => sensorState.toggleSensor('E2')),
                      SizedBox(width: 10),
                      _buildButton('E3', sensorState.e3Active,
                          () => sensorState.toggleSensor('E3')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

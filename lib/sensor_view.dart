import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:provider/provider.dart';
import 'sensors_display.dart';

class SensorView extends StatefulWidget {
  const SensorView({Key? key}) : super(key: key);

  @override
  _SensorViewState createState() => _SensorViewState();
}

class _SensorViewState extends State<SensorView> {
  StateMachineController? _faceController;
  StateMachineController? _sideViewController;

  @override
  void dispose() {
    _faceController?.dispose();
    _sideViewController?.dispose();
    super.dispose();
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

  void _updateRiveAnimation(SensorState sensorState) {
    if (_faceController != null) {
      (_faceController!.findInput<bool>('E1_Active') as SMIBool?)?.value =
          sensorState.e1Active;
      (_faceController!.findInput<bool>('E2_Active') as SMIBool?)?.value =
          sensorState.e2Active;
      (_faceController!.findInput<bool>('E3_Active') as SMIBool?)?.value =
          sensorState.e3Active;
    }
    if (_sideViewController != null) {
      (_sideViewController!.findInput<bool>('I1_Active') as SMIBool?)?.value =
          sensorState.i1Active;
      (_sideViewController!.findInput<bool>('I2_Active') as SMIBool?)?.value =
          sensorState.i2Active;
      (_sideViewController!.findInput<bool>('I3_Active') as SMIBool?)?.value =
          sensorState.i3Active;
      (_sideViewController!.findInput<bool>('E1_Active') as SMIBool?)?.value =
          sensorState.e1Active;
      (_sideViewController!.findInput<bool>('E2_Active') as SMIBool?)?.value =
          sensorState.e2Active;
      (_sideViewController!.findInput<bool>('E3_Active') as SMIBool?)?.value =
          sensorState.e3Active;
    }
  }

  Widget _buildSensorStateRow(
      String label, List<String> sensors, SensorState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: '),
        ...sensors.map((sensor) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: CircleAvatar(
                radius: 10,
                backgroundColor:
                    state.getSensorState(sensor) ? Colors.green : Colors.red,
                child: Text(sensor.substring(1),
                    style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorState>(
      builder: (context, sensorState, child) {
        _updateRiveAnimation(sensorState);
        return SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                _buildRiveAnimation('assets/faceview.riv', (artboard) {
                  final controller = StateMachineController.fromArtboard(
                      artboard, 'State Machine 1');
                  if (controller != null) {
                    artboard.addController(controller);
                    _faceController = controller;
                    _updateRiveAnimation(sensorState);
                  }
                }),
                SizedBox(height: 20),
                _buildRiveAnimation('assets/sideview.riv', (artboard) {
                  final controller = StateMachineController.fromArtboard(
                      artboard, 'State Machine 1');
                  if (controller != null) {
                    artboard.addController(controller);
                    _sideViewController = controller;
                    _updateRiveAnimation(sensorState);
                  }
                }),
                SizedBox(height: 20),
                Text('Sensor States', style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                _buildSensorStateRow(
                    'Internal', ['I1', 'I2', 'I3'], sensorState),
                SizedBox(height: 10),
                _buildSensorStateRow(
                    'External', ['E1', 'E2', 'E3'], sensorState),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SensorDisplayWidget()),
                  ),
                  child: Text('Go to Sensor Display'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

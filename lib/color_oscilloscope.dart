import 'package:flutter/material.dart';
import 'package:oscilloscope/oscilloscope.dart';

class ColorOscilloscope extends StatelessWidget {
  final String name;
  final List<double> dataPoints;
  final double lowThreshold;
  final double highThreshold;
  final double yAxisMin;
  final double yAxisMax;

  ColorOscilloscope({
    required this.name,
    required this.dataPoints,
    required this.lowThreshold,
    required this.highThreshold,
    required this.yAxisMin,
    required this.yAxisMax,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(name),
        Expanded(
          child: Stack(
            children: [
              _buildOscilloscope(
                  Colors.green, _filterData((v) => v.abs() < lowThreshold)),
              _buildOscilloscope(
                  Colors.orange,
                  _filterData((v) =>
                      v.abs() >= lowThreshold && v.abs() < highThreshold)),
              _buildOscilloscope(
                  Colors.red, _filterData((v) => v.abs() >= highThreshold)),
              _buildOscilloscope(
                  Colors.white, List.filled(dataPoints.length, 0.0)),
            ],
          ),
        ),
      ],
    );
  }

  List<double> _filterData(bool Function(double) condition) {
    return dataPoints
        .map((v) => condition(v) ? v : 0.0)
        .toList()
        .cast<double>();
  }

  Widget _buildOscilloscope(Color color, List<double> dataSet) {
    return Oscilloscope(
      showYAxis: true,
      yAxisColor: Colors.white,
      margin: const EdgeInsets.all(20.0),
      strokeWidth: 3.0,
      backgroundColor:
          color == Colors.green ? Colors.black : Colors.transparent,
      traceColor: color,
      yAxisMax: yAxisMax,
      yAxisMin: yAxisMin,
      dataSet: dataSet,
    );
  }
}

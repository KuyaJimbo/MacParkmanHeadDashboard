import 'package:flutter/material.dart';

class ValueAdjuster extends StatelessWidget {
  final String label;
  final double value;
  final double changeBy;
  final Function(double) onIncrement;
  final Function(double) onDecrement;
  final bool showSign;

  const ValueAdjuster({
    Key? key,
    required this.label,
    required this.value,
    required this.changeBy,
    required this.onIncrement,
    required this.onDecrement,
    this.showSign = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => onIncrement(changeBy),
          child: const Text('+'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            '$label: ${showSign ? (value >= 0 ? '+' : '-') : ''}${value.abs().toStringAsFixed(2).padLeft(5, '0')}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        ElevatedButton(
          onPressed: () => onDecrement(changeBy),
          child: const Text('-'),
        ),
      ],
    );
  }
}

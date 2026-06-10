import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator_widget.dart';

/// Amount text field with an integrated calculator toggle button.
/// Amount is always stored as a double (major currency units).
class AmountInputField extends StatefulWidget {
  final double initialValue;
  final void Function(double amount) onChanged;
  final String? labelText;
  final String? currency;

  const AmountInputField({
    super.key,
    this.initialValue = 0,
    required this.onChanged,
    this.labelText = 'Amount',
    this.currency = '₹',
  });

  @override
  State<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  late final TextEditingController _controller;
  bool _showCalc = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue == 0
          ? ''
          : widget.initialValue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCalcResult(double value) {
    setState(() {
      _controller.text = value % 1 == 0
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(2);
      _showCalc = false;
    });
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: widget.labelText,
            prefixText: '${widget.currency} ',
            suffixIcon: IconButton(
              icon: const Icon(Icons.calculate_outlined),
              tooltip: 'Open calculator',
              onPressed: () => setState(() => _showCalc = !_showCalc),
            ),
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null) widget.onChanged(parsed);
          },
        ),
        if (_showCalc)
          SizedBox(
            height: 300,
            child: CalculatorWidget(
              initialValue: double.tryParse(_controller.text) ?? 0,
              onValueChanged: _onCalcResult,
            ),
          ),
      ],
    );
  }
}

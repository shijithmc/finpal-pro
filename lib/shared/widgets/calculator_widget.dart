import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

/// Safe expression calculator using AST-based parser (math_expressions).
/// No eval() — the parser evaluates only arithmetic operators.
class CalculatorWidget extends StatefulWidget {
  final double initialValue;
  final void Function(double value) onValueChanged;

  const CalculatorWidget({
    super.key,
    this.initialValue = 0,
    required this.onValueChanged,
  });

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  late String _expression;
  String _display = '';
  bool _hasError = false;

  static const _buttonLabels = [
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '-'],
    ['C', '0', '.', '+'],
    ['⌫', '00', '=', ''],
  ];

  @override
  void initState() {
    super.initState();
    _expression = widget.initialValue == 0
        ? ''
        : widget.initialValue.toStringAsFixed(2);
    _display = _expression;
  }

  void _onButton(String label) {
    setState(() {
      _hasError = false;
      switch (label) {
        case 'C':
          _expression = '';
          _display = '';
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
            _display = _expression;
          }
        case '=':
          _evaluate();
        case '÷':
          _expression += '/';
          _display = _expression;
        case '×':
          _expression += '*';
          _display = _expression;
        default:
          _expression += label;
          _display = _expression;
      }
    });
  }

  void _evaluate() {
    try {
      final parser = ShuntingYardParser();
      final exp = parser.parse(_expression);
      final ctx = ContextModel();
      final result = exp.evaluate(EvaluationType.REAL, ctx) as double;
      if (result.isNaN || result.isInfinite) {
        _hasError = true;
        _display = 'Error';
        return;
      }
      _expression = result.toStringAsFixed(2);
      // Trim trailing zeros: 100.00 → 100
      if (_expression.endsWith('.00')) {
        _expression = _expression.substring(0, _expression.length - 3);
      }
      _display = _expression;
      widget.onValueChanged(result);
    } catch (_) {
      _hasError = true;
      _display = 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              _display.isEmpty ? '0' : _display,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: _hasError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          // Buttons
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.4,
              ),
              itemCount: _buttonLabels.fold<int>(
                  0, (sum, row) => sum + row.length),
              itemBuilder: (ctx, index) {
                final row = index ~/ 4;
                final col = index % 4;
                if (row >= _buttonLabels.length) return const SizedBox.shrink();
                final label = _buttonLabels[row][col];
                if (label.isEmpty) return const SizedBox.shrink();
                return _CalcButton(
                  label: label,
                  isOperator: '÷×-+='.contains(label) || label == '=',
                  isAction: label == 'C' || label == '⌫',
                  onTap: () => _onButton(label),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  final bool isOperator;
  final bool isAction;
  final VoidCallback onTap;

  const _CalcButton({
    required this.label,
    required this.isOperator,
    required this.isAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bgColor;
    Color textColor;

    if (label == '=') {
      bgColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isOperator) {
      bgColor = theme.colorScheme.secondaryContainer;
      textColor = theme.colorScheme.onSecondaryContainer;
    } else if (isAction) {
      bgColor = theme.colorScheme.errorContainer;
      textColor = theme.colorScheme.onErrorContainer;
    } else {
      bgColor = theme.colorScheme.surface;
      textColor = theme.colorScheme.onSurface;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}

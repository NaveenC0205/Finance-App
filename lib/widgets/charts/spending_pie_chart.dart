import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class SpendingPieChart extends StatefulWidget {
  final Map<String, double> data;
  const SpendingPieChart({super.key, required this.data});

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final sorted = widget.data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = widget.data.values.fold(0.0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(touchCallback: (event, response) {
                  setState(() {
                    _touched = (event.isInterestedForInteractions && response?.touchedSection != null)
                        ? response!.touchedSection!.touchedSectionIndex
                        : -1;
                  });
                }),
                centerSpaceRadius: 50,
                sectionsSpace: 2,
                sections: List.generate(sorted.length, (i) {
                  final e = sorted[i];
                  final isTouched = i == _touched;
                  final color = AppColors.categoryColors[e.key] ?? AppColors.chartColors[i % AppColors.chartColors.length];
                  return PieChartSectionData(
                    value: e.value,
                    color: color,
                    radius: isTouched ? 65 : 55,
                    title: isTouched ? '${(e.value / total * 100).round()}%' : '',
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12, runSpacing: 8,
            children: List.generate(sorted.take(6).length, (i) {
              final e = sorted[i];
              final color = AppColors.categoryColors[e.key] ?? AppColors.chartColors[i % AppColors.chartColors.length];
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                  '${AppConstants.categoryEmojis[e.key] ?? ''} ${AppConstants.categoryLabels[e.key] ?? e.key}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ]);
            }).toList(),
          ),
        ]),
      ),
    );
  }
}

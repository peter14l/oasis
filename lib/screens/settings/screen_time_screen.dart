import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oasis_v2/services/screen_time_service.dart';
import 'package:oasis_v2/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  DateTime _selectedDate = DateTime.now();
  int _touchedIndex = -1;
  int _touchedBarIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenTimeService = Provider.of<ScreenTimeService>(context);

    // Data for selected day
    final usageData = screenTimeService.getDailyUsage(_selectedDate);
    final totalMinutes = usageData['totalMinutes'] as int;
    final hourlyBreakdown = usageData['hourlyBreakdown'] as List<int>;

    // Weekly data
    final weeklyData = screenTimeService.getWeeklyData();
    final weeklyAverage = screenTimeService.getWeeklyAverage();

    // Category data
    final categoryUsage = screenTimeService.getCategoryUsage(totalMinutes);

    // Calculate day parts for pie chart
    int morning = 0; // 6am - 12pm
    int afternoon = 0; // 12pm - 6pm
    int evening = 0; // 6pm - 12am
    int night = 0; // 12am - 6am

    for (int i = 0; i < 24; i++) {
      final minutes = hourlyBreakdown[i];
      if (i >= 6 && i < 12)
        morning += minutes;
      else if (i >= 12 && i < 18)
        afternoon += minutes;
      else if (i >= 18 && i < 24)
        evening += minutes;
      else
        night += minutes;
    }

    final pieSections = [
      if (morning > 0)
        _buildPieChartSection(0, morning, 'Morning', Colors.orangeAccent),
      if (afternoon > 0)
        _buildPieChartSection(1, afternoon, 'Afternoon', Colors.blueAccent),
      if (evening > 0)
        _buildPieChartSection(2, evening, 'Evening', colorScheme.secondary),
      if (night > 0)
        _buildPieChartSection(3, night, 'Night', Colors.indigoAccent),
    ];

    final isHealthy = weeklyAverage < 120; // Example threshold: 2 hours

    final content = Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Screen Time'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Total Screen Time',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(totalMinutes),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          totalMinutes > weeklyAverage
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Average: ${_formatDuration(weeklyAverage)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Weekly Activity Chart
            Text(
              'Weekly Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: colorScheme.inverseSurface,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          _formatDuration(rod.toY.toInt()),
                          TextStyle(color: colorScheme.onInverseSurface),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        if (response?.spot != null && event is FlTapUpEvent) {
                          _touchedBarIndex =
                              response!.spot!.touchedBarGroupIndex;
                        } else {
                          _touchedBarIndex = -1;
                        }
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < weeklyData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                weeklyData[value.toInt()]['day'],
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(weeklyData.length, (index) {
                    final minutes = weeklyData[index]['minutes'] as int;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: minutes.toDouble(),
                          color:
                              index == 6
                                  ? colorScheme.primary
                                  : colorScheme.primary.withValues(alpha: 0.3),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY:
                                (weeklyAverage * 1.5)
                                    .toDouble(), // Max height relative to average
                            color: colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Category Breakdown
            Text(
              'Most Used',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryUsage.map(
              (category) => _buildCategoryItem(
                context,
                category['name'],
                category['minutes'],
                category['icon'] as IconData,
                Color(category['color']),
                totalMinutes,
              ),
            ),

            const SizedBox(height: 32),

            // Time of Day (Pie Chart)
            if (totalMinutes > 0) ...[
              Text(
                'Time of Day',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              pieTouchResponse
                                  .touchedSection!
                                  .touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: pieSections,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (morning > 0)
                    _buildLegendItem('Morning', Colors.orangeAccent),
                  if (afternoon > 0)
                    _buildLegendItem('Afternoon', Colors.blueAccent),
                  if (evening > 0)
                    _buildLegendItem('Evening', colorScheme.secondary),
                  if (night > 0) _buildLegendItem('Night', Colors.indigoAccent),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // Insight Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    isHealthy
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isHealthy
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.orange.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isHealthy
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: isHealthy ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHealthy ? 'Healthy Usage' : 'High Usage',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isHealthy ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHealthy
                              ? 'You are within your daily average goal.'
                              : 'You are above your daily average goal. Consider taking a break.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    return ResponsiveLayout.isDesktop(context)
        ? MaxWidthContainer(
          maxWidth: ResponsiveLayout.maxFormWidth,
          child: content,
        )
        : content;
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String name,
    int minutes,
    IconData icon,
    Color color,
    int totalMinutes,
  ) {
    final theme = Theme.of(context);
    final percentage = totalMinutes > 0 ? minutes / totalMinutes : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDuration(minutes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieChartSection(
    int index,
    int value,
    String title,
    Color color,
  ) {
    final isTouched = index == _touchedIndex;
    final fontSize = isTouched ? 16.0 : 12.0;
    final radius = isTouched ? 60.0 : 50.0;

    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title:
          isTouched
              ? '${_formatDuration(value)}'
              : '${(value / (value + 1) * 100).toInt()}%',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      showTitle: isTouched,
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(title),
      ],
    );
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

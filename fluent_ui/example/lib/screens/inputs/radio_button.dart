import 'package:example/widgets/code_snippet_card.dart';
import 'package:example/widgets/page.dart';
import 'package:fluent_ui/fluent_ui.dart';

enum _DeliverySpeed { standard, express, overnight }

enum _NotificationFrequency { immediately, daily, weekly, never }

enum _ExportQuality { low, medium, high, original }

class RadioButtonPage extends StatefulWidget {
  const RadioButtonPage({super.key});

  @override
  State<RadioButtonPage> createState() => _RadioButtonPageState();
}

class _RadioButtonPageState extends State<RadioButtonPage> with PageMixin {
  // Example 1 – Background color
  bool backgroundColorDisabled = false;
  Color backgroundColor = Colors.red;

  // Example 2 – Delivery speed
  _DeliverySpeed deliverySpeed = _DeliverySpeed.standard;

  // Example 3 – Notification frequency
  _NotificationFrequency notificationFrequency =
      _NotificationFrequency.immediately;

  // Example 4 – Export quality
  _ExportQuality exportQuality = _ExportQuality.high;

  @override
  Widget build(final BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('RadioButton')),
      children: [
        const Text(
          'Radio buttons, also called option buttons, let users select one option from a collection of two or more mutually exclusive, but related, options. Radio buttons are always used in groups, and each option is represented by one radio button in the group.',
        ),

        // ── Example 1: Background color ────────────────────────────────────
        subtitle(content: const Text('A radio button group')),
        CodeSnippetCard(
          codeSnippet: '''bool backgroundColorDisabled = false;
Color backgroundColor = Colors.red;

InfoLabel(
  label: 'Background Color:',
  child: RadioGroup<Color>(
    groupValue: backgroundColor,
    onChanged: (v) =>
        setState(() => backgroundColor = v ?? backgroundColor),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        RadioButton<Color>(
          value: Colors.red,
          content: const Text('Red'),
          enabled: !backgroundColorDisabled,
        ),
        RadioButton<Color>(
          value: Colors.green,
          content: const Text('Green'),
          enabled: !backgroundColorDisabled,
        ),
        RadioButton<Color>(
          value: Colors.blue,
          content: const Text('Blue'),
          enabled: !backgroundColorDisabled,
        ),
      ],
    ),
  ),
),
''',
          child: IntrinsicHeight(
            child: Row(
              spacing: 40,
              children: [
                InfoLabel(
                  label: 'Background Color:',
                  child: RadioGroup<Color>(
                    groupValue: backgroundColor,
                    onChanged: (v) =>
                        setState(() => backgroundColor = v ?? backgroundColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        RadioButton<Color>(
                          value: Colors.red,
                          content: const Text('Red'),
                          enabled: !backgroundColorDisabled,
                        ),
                        RadioButton<Color>(
                          value: Colors.green,
                          content: const Text('Green'),
                          enabled: !backgroundColorDisabled,
                        ),
                        RadioButton<Color>(
                          value: Colors.blue,
                          content: const Text('Blue'),
                          enabled: !backgroundColorDisabled,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  decoration: BoxDecoration(
                    color: backgroundColorDisabled
                        ? Colors.grey
                        : backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                ToggleSwitch(
                  checked: backgroundColorDisabled,
                  onChanged: (final v) {
                    setState(() {
                      backgroundColorDisabled = v;
                    });
                  },
                  content: const Text('Disabled'),
                ),
              ],
            ),
          ),
        ),

        // ── Example 2: Delivery speed ──────────────────────────────────────
        subtitle(content: const Text('Delivery method')),
        description(
          content: const Text(
            'Select a shipping speed at checkout. The summary updates to reflect the chosen option.',
          ),
        ),
        CodeSnippetCard(
          codeSnippet: r'''enum DeliverySpeed { standard, express, overnight }

DeliverySpeed deliverySpeed = DeliverySpeed.standard;

RadioGroup<DeliverySpeed>(
  groupValue: deliverySpeed,
  onChanged: (v) => setState(() => deliverySpeed = v ?? deliverySpeed),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 6,
    children: [
      RadioButton<DeliverySpeed>(
        value: DeliverySpeed.standard,
        content: Text('Standard – Free (5–7 business days)'),
      ),
      RadioButton<DeliverySpeed>(
        value: DeliverySpeed.express,
        content: Text('Express – $9.99 (2–3 business days)'),
      ),
      RadioButton<DeliverySpeed>(
        value: DeliverySpeed.overnight,
        content: Text('Overnight – $24.99 (next business day)'),
      ),
    ],
  ),
)
''',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 40,
            children: [
              RadioGroup<_DeliverySpeed>(
                groupValue: deliverySpeed,
                onChanged: (v) =>
                    setState(() => deliverySpeed = v ?? deliverySpeed),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    RadioButton<_DeliverySpeed>(
                      value: _DeliverySpeed.standard,
                      content: Text('Standard – Free (5–7 business days)'),
                    ),
                    RadioButton<_DeliverySpeed>(
                      value: _DeliverySpeed.express,
                      content: Text(r'Express – $9.99 (2–3 business days)'),
                    ),
                    RadioButton<_DeliverySpeed>(
                      value: _DeliverySpeed.overnight,
                      content: Text(r'Overnight – $24.99 (next business day)'),
                    ),
                  ],
                ),
              ),
              _DeliverySpeedSummary(deliverySpeed: deliverySpeed),
            ],
          ),
        ),

        // ── Example 3: Notification frequency ─────────────────────────────
        subtitle(content: const Text('Notification frequency')),
        description(
          content: const Text(
            'Control how often the app sends you notifications.',
          ),
        ),
        CodeSnippetCard(
          codeSnippet:
              '''enum NotificationFrequency { immediately, daily, weekly, never }

NotificationFrequency notificationFrequency = NotificationFrequency.immediately;

InfoLabel(
  label: 'Send me notifications:',
  child: RadioGroup<NotificationFrequency>(
    groupValue: notificationFrequency,
    onChanged: (v) =>
        setState(() => notificationFrequency = v ?? notificationFrequency),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        RadioButton<NotificationFrequency>(
          value: NotificationFrequency.immediately,
          content: Text('Immediately'),
        ),
        RadioButton<NotificationFrequency>(
          value: NotificationFrequency.daily,
          content: Text('Once a day (daily digest)'),
        ),
        RadioButton<NotificationFrequency>(
          value: NotificationFrequency.weekly,
          content: Text('Once a week'),
        ),
        RadioButton<NotificationFrequency>(
          value: NotificationFrequency.never,
          content: Text('Never'),
        ),
      ],
    ),
  ),
)
''',
          child: InfoLabel(
            label: 'Send me notifications:',
            child: RadioGroup<_NotificationFrequency>(
              groupValue: notificationFrequency,
              onChanged: (v) => setState(
                () => notificationFrequency = v ?? notificationFrequency,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  RadioButton<_NotificationFrequency>(
                    value: _NotificationFrequency.immediately,
                    content: Text('Immediately'),
                  ),
                  RadioButton<_NotificationFrequency>(
                    value: _NotificationFrequency.daily,
                    content: Text('Once a day (daily digest)'),
                  ),
                  RadioButton<_NotificationFrequency>(
                    value: _NotificationFrequency.weekly,
                    content: Text('Once a week'),
                  ),
                  RadioButton<_NotificationFrequency>(
                    value: _NotificationFrequency.never,
                    content: Text('Never'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Example 4: Export quality ──────────────────────────────────────
        subtitle(content: const Text('Export quality')),
        description(
          content: const Text(
            'Choose the image quality when exporting. Higher quality produces larger files.',
          ),
        ),
        CodeSnippetCard(
          codeSnippet: '''enum ExportQuality { low, medium, high, original }

ExportQuality exportQuality = ExportQuality.high;

RadioGroup<ExportQuality>(
  groupValue: exportQuality,
  onChanged: (v) => setState(() => exportQuality = v ?? exportQuality),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 6,
    children: [
      RadioButton<ExportQuality>(
        value: ExportQuality.low,
        content: Text('Low (≈ 200 KB)'),
      ),
      RadioButton<ExportQuality>(
        value: ExportQuality.medium,
        content: Text('Medium (≈ 800 KB)'),
      ),
      RadioButton<ExportQuality>(
        value: ExportQuality.high,
        content: Text('High (≈ 2 MB)'),
      ),
      RadioButton<ExportQuality>(
        value: ExportQuality.original,
        content: Text('Original – no compression'),
      ),
    ],
  ),
)
''',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 40,
            children: [
              RadioGroup<_ExportQuality>(
                groupValue: exportQuality,
                onChanged: (v) =>
                    setState(() => exportQuality = v ?? exportQuality),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    RadioButton<_ExportQuality>(
                      value: _ExportQuality.low,
                      content: Text('Low (≈ 200 KB)'),
                    ),
                    RadioButton<_ExportQuality>(
                      value: _ExportQuality.medium,
                      content: Text('Medium (≈ 800 KB)'),
                    ),
                    RadioButton<_ExportQuality>(
                      value: _ExportQuality.high,
                      content: Text('High (≈ 2 MB)'),
                    ),
                    RadioButton<_ExportQuality>(
                      value: _ExportQuality.original,
                      content: Text('Original – no compression'),
                    ),
                  ],
                ),
              ),
              _ExportQualityIndicator(quality: exportQuality),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Delivery speed summary card ──────────────────────────────────────────────

class _DeliverySpeedSummary extends StatelessWidget {
  const _DeliverySpeedSummary({required this.deliverySpeed});

  final _DeliverySpeed deliverySpeed;

  @override
  Widget build(BuildContext context) {
    final (label, days, price) = switch (deliverySpeed) {
      _DeliverySpeed.standard => ('Standard', '5–7 business days', 'Free'),
      _DeliverySpeed.express => ('Express', '2–3 business days', r'$9.99'),
      _DeliverySpeed.overnight => ('Overnight', 'Next business day', r'$24.99'),
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Text(
              'Order summary',
              style: FluentTheme.of(context).typography.bodyStrong,
            ),
            const Divider(),
            _SummaryRow(label: 'Shipping method', value: label),
            _SummaryRow(label: 'Estimated delivery', value: days),
            _SummaryRow(label: 'Shipping cost', value: price),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 24,
      children: [
        Text(label, style: FluentTheme.of(context).typography.caption),
        Text(value, style: FluentTheme.of(context).typography.bodyStrong),
      ],
    );
  }
}

// ── Export quality indicator ─────────────────────────────────────────────────

class _ExportQualityIndicator extends StatelessWidget {
  const _ExportQualityIndicator({required this.quality});

  final _ExportQuality quality;

  @override
  Widget build(BuildContext context) {
    final (description, filledBars) = switch (quality) {
      _ExportQuality.low => ('Smaller file, lower detail', 1),
      _ExportQuality.medium => ('Balanced size and detail', 2),
      _ExportQuality.high => ('Large file, high detail', 3),
      _ExportQuality.original => ('Exact original, no compression', 4),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Row(
          spacing: 4,
          children: List.generate(4, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 12,
              height: 12 + (i * 6).toDouble(),
              decoration: BoxDecoration(
                color: i < filledBars
                    ? FluentTheme.of(context).accentColor
                    : FluentTheme.of(
                        context,
                      ).resources.controlStrokeColorDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        Text(description, style: FluentTheme.of(context).typography.caption),
      ],
    );
  }
}

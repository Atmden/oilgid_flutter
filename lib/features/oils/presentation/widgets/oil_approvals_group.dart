import 'package:flutter/material.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_approval.dart';
import 'package:oil_gid/themes/app_colors.dart';

class ApprovalsGroup extends StatelessWidget {
  final String title;
  final List<OilApproval> values;

  const ApprovalsGroup({super.key, required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .where((item) => item.title.isNotEmpty)
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      item.title,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class InfoBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const InfoBlock({required this.title, required this.child, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Поле "метка сверху + текст на всю ширину", с раскрытием длинного текста
/// по кнопке "Показать ещё" / "Скрыть".
class ExpandableInfoRow extends StatefulWidget {
  final String? label;
  final String value;
  final int collapsedMaxLines;
  final TextAlign textAlign;

  const ExpandableInfoRow({
    super.key,
    this.label,
    required this.value,
    this.collapsedMaxLines = 5,
    this.textAlign = TextAlign.start,
  });

  @override
  State<ExpandableInfoRow> createState() => _ExpandableInfoRowState();
}

class _ExpandableInfoRowState extends State<ExpandableInfoRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.value.isEmpty) return const SizedBox.shrink();

    const textStyle = TextStyle(fontSize: 14);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null && widget.label!.isNotEmpty) ...[
            Text(widget.label!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final painter = TextPainter(
                text: TextSpan(text: widget.value, style: textStyle),
                maxLines: widget.collapsedMaxLines,
                textDirection: Directionality.of(context),
              )..layout(maxWidth: constraints.maxWidth);
              final isOverflowing = painter.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.value,
                    style: textStyle,
                    textAlign: widget.textAlign,
                    maxLines: _expanded ? null : widget.collapsedMaxLines,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (isOverflowing)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Text(
                          _expanded ? 'Скрыть' : 'Показать ещё',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

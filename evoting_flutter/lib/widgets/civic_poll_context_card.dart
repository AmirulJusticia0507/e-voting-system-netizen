import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/topic.dart';

class CivicPollContextCard extends StatelessWidget {
  final Topic topic;

  const CivicPollContextCard({super.key, required this.topic});

  String _date(String? value) {
    final date = DateTime.tryParse(value ?? '')?.toLocal();
    return date == null ? '-' : DateFormat('d MMM yyyy, HH:mm').format(date);
  }

  String _timeRange(CivicPollSource source) {
    String format(int seconds) =>
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    final start = source.segmentStartSeconds;
    final end = source.segmentEndSeconds;
    if (start == null && end == null) return '';
    return '${start == null ? '-' : format(start)}–${end == null ? '-' : format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!topic.isCivicPoll) return const SizedBox.shrink();
    final source = topic.civicSource;

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.forum_outlined, size: 20),
                SizedBox(width: 8),
                Text('Jajak Pendapat Publik',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (topic.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(topic.description),
            ],
            const SizedBox(height: 8),
            Text('Periode: ${_date(topic.opensAt)} – ${_date(topic.closesAt)}'),
            if (source != null) ...[
              const Divider(height: 20),
              Text('Sumber: ${source.title}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (source.publisher.isNotEmpty) Text(source.publisher),
              if (_timeRange(source).isNotEmpty)
                Text('Cuplikan: ${_timeRange(source)}'),
              if (source.url.isNotEmpty)
                SelectableText(source.url,
                    style: const TextStyle(color: Colors.blue)),
            ],
            if (topic.disclaimer.isNotEmpty) ...[
              const Divider(height: 20),
              Text(topic.disclaimer,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

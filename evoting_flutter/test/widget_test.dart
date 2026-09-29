import 'package:evoting_flutter/models/topic.dart';
import 'package:evoting_flutter/widgets/civic_poll_context_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('civic poll shows its source and disclaimer', (tester) async {
    final topic = Topic.fromJson({
      'id': 1,
      'title': 'Transportasi publik',
      'description': 'Ringkasan kebijakan',
      'is_active': true,
      'created_at': '2026-09-29T10:00:00Z',
      'topic_type': 'civic_poll',
      'publication_status': 'published',
      'disclaimer': 'Hasil tidak mengikat.',
      'civic_source': {
        'title': 'Rapat DPRD',
        'publisher': 'DPRD Contoh',
        'url': 'https://example.com/rapat',
        'segment_start_seconds': 60,
        'segment_end_seconds': 120,
      },
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CivicPollContextCard(topic: topic)),
      ),
    );

    expect(find.text('Jajak Pendapat Publik'), findsOneWidget);
    expect(find.text('Sumber: Rapat DPRD'), findsOneWidget);
    expect(find.text('Hasil tidak mengikat.'), findsOneWidget);
    expect(find.text('Cuplikan: 1:00–2:00'), findsOneWidget);
  });
}

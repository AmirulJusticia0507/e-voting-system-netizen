import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';

class LiveResultsPage extends StatefulWidget {
  const LiveResultsPage({super.key});

  @override
  State<LiveResultsPage> createState() => _LiveResultsPageState();
}

class _LiveResultsPageState extends State<LiveResultsPage> {
  final api = ApiService();
  List<dynamic> topics = [];
  int? currentTopic;
  Map<String, dynamic>? data;
  bool connected = false;
  String? error;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  // Untuk animasi "naik/turun" per kandidat antar-snapshot
  Map<int, int> _prevOrder = {};
  Map<int, int> _movement = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final res = await api.get("topics/");
    if (mounted && res.statusCode == 200) {
      final t = jsonDecode(res.body);
      setState(() {
        topics = List<dynamic>.from(t);
        if (topics.isNotEmpty) currentTopic = topics.first['id'];
      });
      if (currentTopic != null) _connect();
    }
  }

  void _connect() {
    _disconnect();
    final id = currentTopic;
    if (id == null) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(api.wsUrl(id)));
      _sub = _channel!.stream.listen(
        (msg) {
          final payload = jsonDecode(msg as String);
          if (!mounted) return;
          setState(() {
            if (payload['type'] == 'snapshot' || payload['type'] == 'update') {
              _applySnapshot((payload['data'] as Map<String, dynamic>?) ?? data);
              connected = true;
              error = null;
            }
          });
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              connected = false;
              error = "Koneksi realtime terputus: $e";
            });
          }
        },
        onDone: () {
          if (mounted) setState(() => connected = false);
        },
      );
    } catch (e) {
      setState(() {
        connected = false;
        error = "Gagal konek WebSocket: $e";
      });
    }
  }

  /// Hitung pergerakan posisi (naik/turun) lalu simpan snapshot baru.
  void _applySnapshot(Map<String, dynamic>? next) {
    if (next == null) return;
    final sorted = [...(next['candidates'] as List<dynamic>? ?? [])]
      ..sort((a, b) => (b['votes'] ?? 0).compareTo(a['votes'] ?? 0));

    final newOrder = <int, int>{};
    final mov = <int, int>{};
    for (var i = 0; i < sorted.length; i++) {
      final id = (sorted[i]['candidate_id'] as num?)?.toInt() ?? i;
      final prev = _prevOrder[id];
      newOrder[id] = i;
      if (prev != null) {
        if (i < prev) mov[id] = 1; // naik
        else if (i > prev) mov[id] = -1; // turun
        else mov[id] = 0; // tetap
      }
    }
    _prevOrder = newOrder;
    _movement = mov;
    data = next;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hasil Realtime · Live"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<int>(
              initialValue: currentTopic,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Pilih Topik",
                border: OutlineInputBorder(),
              ),
              items: topics
                  .map<DropdownMenuItem<int>>((t) =>
                      DropdownMenuItem<int>(value: t['id'], child: Text(t['title'] ?? '')))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  currentTopic = v;
                  _prevOrder = {};
                  _movement = {};
                });
                _connect();
              },
            ),
          ),
          if (!connected && error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error!)),
                  TextButton(onPressed: _connect, child: const Text("Coba lagi")),
                ],
              ),
            )
          else if (!connected)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: Text("Menghubungkan ke server real-time...")),
            ),
          Expanded(
            child: data == null
                ? const Center(child: CircularProgressIndicator())
                : _buildData(),
          ),
        ],
      ),
    );
  }

  Widget _buildData() {
    final candidates = List<Map<String, dynamic>>.from(data?['candidates'] ?? [])
      ..sort((a, b) => (b['votes'] ?? 0).compareTo(a['votes'] ?? 0));
    final total = data?['total_votes'] ?? 0;
    final registered = data?['total_registered'];
    final participation = data?['participation_percent'];
    final maxVotes = candidates.isNotEmpty ? (candidates.first['votes'] ?? 0) : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.deepPurple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data?['topic_title'] ?? "Topik",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statChip(Icons.how_to_vote, "Suara", "$total"),
                    if (registered != null) ...[
                      const SizedBox(width: 8),
                      _statChip(Icons.group, "DPT", "$registered"),
                    ],
                    if (participation != null) ...[
                      const SizedBox(width: 8),
                      _statChip(Icons.percent, "Partisipasi",
                          "${participation.toStringAsFixed(1)}%"),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...candidates.asMap().entries.map((e) {
          final idx = e.key;
          final c = e.value;
          final id = (c['candidate_id'] as num?)?.toInt();
          final votes = c['votes'] ?? 0;
          final isLeader = idx == 0 && votes > 0;
          final mov = (id != null) ? (_movement[id] ?? 0) : 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: isLeader
                  ? const BorderSide(color: Colors.amber, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isLeader ? Colors.amber : Colors.deepPurple.shade100,
                    child: Text("${idx + 1}",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isLeader ? Colors.black87 : Colors.deepPurple)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(c['candidate_name'] ?? 'Kandidat',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          _movementBadge(mov),
                        ]),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: maxVotes == 0 ? 0 : (votes / maxVotes).clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                isLeader ? Colors.amber : Colors.deepPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (votes as num).toDouble()),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text(
                      "${v.round()}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isLeader ? Colors.amber.shade800 : Colors.deepPurple),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _movementBadge(int mov) {
    if (mov == 0) return const SizedBox.shrink();
    final up = mov > 0;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: up ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.trending_up : Icons.trending_down,
            size: 14, color: up ? Colors.green : Colors.red),
      ]),
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text("$label: $value"),
      visualDensity: VisualDensity.compact,
    );
  }
}
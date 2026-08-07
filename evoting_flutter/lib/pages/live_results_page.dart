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
              data = (payload['data'] as Map<String, dynamic>?) ?? data;
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
        title: const Text("Hasil Realtime"),
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
                setState(() => currentTopic = v);
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
    final candidates = List<Map<String, dynamic>>.from(data?['candidates'] ?? []);
    final total = data?['total_votes'] ?? 0;
    final registered = data?['total_registered'];
    final participation = data?['participation_percent'];
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
        ...candidates.map((c) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(c['candidate_name'] ?? 'Kandidat'),
              trailing: Text(
                "${c['votes'] ?? 0} Suara",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
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
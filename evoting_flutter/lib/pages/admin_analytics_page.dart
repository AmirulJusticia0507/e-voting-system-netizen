import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

/// Final batch: Dashboard analitik admin.
class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final api = ApiService();
  Map<String, dynamic>? data;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => isLoading = true);
    try {
      final res = await api.get("votes/analytics/", UserRole.admin);
      if (res.statusCode == 200) {
        setState(() {
          data = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Gagal memuat analitik (${res.statusCode}).";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analitik Voting 📊"),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetch),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: fetch,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(children: [
                        _statCard(Icons.how_to_vote, "Total Suara",
                            "${data?['total_votes'] ?? 0}"),
                        const SizedBox(width: 12),
                        _statCard(Icons.topic, "Topik", "${data?['total_topics'] ?? 0}"),
                      ]),
                      const SizedBox(height: 16),
                      _section("Tren Voting 7 Hari"),
                      _trendChart(),
                      const SizedBox(height: 16),
                      _section("Wilayah Paling Rame"),
                      ..._regions(),
                      const SizedBox(height: 16),
                      _section("Partisipasi per Periode"),
                      ..._periods(),
                    ],
                  ),
                ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _statCard(IconData icon, String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.green),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trendChart() {
    final trend = (data?['trend_days'] as List<dynamic>? ?? []) as List<dynamic>;
    if (trend.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text("Belum ada suara minggu ini.")),
        ),
      );
    }
    final maxY = trend.fold<int>(1, (m, e) => (e['count'] ?? 0) > m ? (e['count'] as int) : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: (maxY + 1).toDouble(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= trend.length) return const Text('');
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_shortDate(trend[i]['date']), style: const TextStyle(fontSize: 9)),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < trend.length; i++)
                      FlSpot(i.toDouble(), (trend[i]['count'] ?? 0).toDouble()),
                  ],
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _regions() {
    final regions = (data?['top_regions'] as List<dynamic>? ?? []) as List<dynamic>;
    return regions.isEmpty
        ? const Card(child: ListTile(title: Text("Belum ada data.")))
        : regions.asMap().entries.map<Widget>((e) {
            final r = e.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Text("${e.key + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                title: Text("🏳️ ${r['region_name']}"),
                subtitle: Text("DPT ${r['dpt']} · ${r['votes']} suara"),
                trailing: Text("${r['participation_percent']?.toStringAsFixed(0) ?? 0}%",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }).toList();
  }

  Widget _periods() {
    final periods = (data?['per_period'] as List<dynamic>? ?? []) as List<dynamic>;
    return periods.isEmpty
        ? const Text("Belum ada periode.")
        : periods.map<Widget>((p) {
            final part = p['participation_percent'];
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: const Icon(Icons.event_note),
                title: Text(p['title'] ?? "Periode"),
                subtitle: Text(
                  "${p['total_votes']} ${part != null ? '· ${part.toStringAsFixed(1)}%' : 'suara'} ",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.bar_chart),
                  onPressed: () {},
                  tooltip: "Lihat di Dashboard",
                ),
              ),
            );
          }).toList();
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    return iso.substring(5, 10); // MM-DD
  }
}
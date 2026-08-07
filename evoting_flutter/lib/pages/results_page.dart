import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../widgets/topic_share_sheet.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final api = ApiService();
  List<dynamic> results = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future<void> fetchResults() async {
    setState(() => isLoading = true);
    try {
      final res = await api.get("votes/results/");
      if (res.statusCode == 200) {
        setState(() {
          results = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Rekap Hasil Voting"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada data hasil voting.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final topic = results[i];
                    final candidates =
                        List<Map<String, dynamic>>.from(topic["candidates"] ?? []);

                    if (candidates.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text("Topik: ${topic["topic_title"]} (Belum ada suara)"),
                        ),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic["topic_title"] ?? "Topik Voting",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Row(children: [
                              const Spacer(),
                              IconButton(
                                tooltip: "Bagikan hasil & QR",
                                icon: const Icon(Icons.share),
                                color: Colors.deepPurple,
                                onPressed: () => showShareSheet(
                                  context,
                                  topic["topic_id"] as int,
                                  topicTitle: topic["topic_title"]?.toString(),
                                ),
                              ),
                            ]),
                            const Divider(height: 8),

                            // 🔹 Legend & Vote Counts
                            ...candidates.map((c) {
                              final color = Colors
                                  .primaries[candidates.indexOf(c) % Colors.primaries.length];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        c["candidate_name"] ?? "Kandidat",
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(
                                      "${c["vote_count"]} Suara",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 20),

                            // 🔹 Bar Chart
                            const Text("Grafik Batang Suara:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  barGroups: candidates.map((c) {
                                    final color = Colors.primaries[
                                        candidates.indexOf(c) % Colors.primaries.length];
                                    return BarChartGroupData(
                                      x: candidates.indexOf(c),
                                      barRods: [
                                        BarChartRodData(
                                          toY: (c["vote_count"] as num).toDouble(),
                                          color: color,
                                          width: 24,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: true, reservedSize: 28),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx >= 0 && idx < candidates.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                candidates[idx]["candidate_name"] ?? "",
                                                style: const TextStyle(fontSize: 10),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }
                                          return const Text("");
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: true),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}


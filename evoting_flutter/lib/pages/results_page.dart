import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final api = ApiService();
  List<dynamic> results = [];

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  void fetchResults() async {
    final res = await api.get("votes/results/");
    if (res.statusCode == 200) {
      setState(() {
        results = jsonDecode(res.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📊 Hasil Voting")),
      body: results.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final topic = results[i];
                final candidates = List<Map<String, dynamic>>.from(topic["candidates"]);

                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          topic["topic_title"],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // 🔹 Bar Chart
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barGroups: candidates.map((c) {
                                return BarChartGroupData(
                                  x: candidates.indexOf(c),
                                  barRods: [
                                    BarChartRodData(
                                      toY: (c["vote_count"] as num).toDouble(),
                                      color: Colors.blue,
                                      width: 20,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() < candidates.length) {
                                        return Text(
                                          candidates[value.toInt()]["candidate_name"],
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      }
                                      return const Text("");
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Pie Chart
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: candidates.map((c) {
                                final color = Colors.primaries[candidates.indexOf(c) % Colors.primaries.length];
                                return PieChartSectionData(
                                  value: (c["vote_count"] as num).toDouble(),
                                  title: "${c["vote_count"]}",
                                  color: color,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
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

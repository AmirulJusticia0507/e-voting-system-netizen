import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Final batch: pusat notifikasi in-app + broadcast admin + badge unread.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final api = ApiService();
  List<dynamic> items = [];
  int unread = 0;
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
      final res = await api.get("notifications/");
      final cnt = await api.get("notifications/unread_count/");
      if (res.statusCode == 200 && cnt.statusCode == 200) {
        setState(() {
          items = jsonDecode(res.body);
          unread = jsonDecode(cnt.body)['unread'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Gagal memuat notifikasi.";
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

  Future<void> markRead(int id) async {
    await api.post("notifications/$id/mark_read/", {});
    setState(() {
      for (final n in items) {
        if (n['id'] == id) n['is_read'] = true;
      }
    });
    unread = items.where((n) => n['is_read'] != true).length;
  }

  void _openBroadcast() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _BroadcastSheet(),
    ).then((_) => fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifikasi${unread > 0 ? " ($unread)" : ""}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Broadcast ke netizen",
            icon: const Icon(Icons.campaign),
            onPressed: _openBroadcast,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetch),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : items.isEmpty
                  ? const Center(child: Text("Belum ada notifikasi."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final n = items[i];
                        final read = n['is_read'] == true;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: read ? null : Colors.indigo.shade50,
                          child: ListTile(
                            leading: Icon(
                              Icons.notifications_active,
                              color: read ? Colors.grey : Colors.indigo,
                            ),
                            title: Text(
                              n['title'] ?? "",
                              style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold),
                            ),
                            subtitle: Text(n['body'] ?? ""),
                            isThreeLine: true,
                            trailing: read
                                ? null
                                : TextButton(
                                    onPressed: () => markRead(n['id'] as int),
                                    child: const Text("Tandai baca"),
                                  ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _BroadcastSheet extends StatefulWidget {
  const _BroadcastSheet();

  @override
  State<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends State<_BroadcastSheet> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final linkCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final api = ApiService();
    final res = await api.post("notifications/broadcasts/send/", {
      "title": titleCtrl.text,
      "body": bodyCtrl.text,
      "link": linkCtrl.text,
    });
    if (mounted) {
      setState(() => _sending = false);
      final ok = res.statusCode == 201;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? "Broadcast terkirim (${jsonDecode(res.body)['targets']} netizen)."
              : "Gagal broadcast (${res.statusCode}). ${res.body}"),
        ),
      );
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Broadcast ke semua netizen",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Judul", border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? "Judul wajib diisi" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Isi pesan", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: linkCtrl,
              decoration: const InputDecoration(labelText: "Link (opsional, mis. ?v=1)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send),
                label: Text(_sending ? "Mengirim..." : "Kirim Broadcast"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
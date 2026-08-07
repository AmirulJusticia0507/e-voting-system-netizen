import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

String _fmt(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final s = iso.replaceAll('T', ' ');
  return s.length > 16 ? s.substring(0, 16) : s;
}

String _toIso(String s) {
  final t = s.trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$').hasMatch(t)) {
    return '${t.replaceAll(' ', 'T')}:00';
  }
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t)) {
    return '${t}T00:00:00';
  }
  return t.replaceAll(' ', 'T');
}

class ManageElectionsPage extends StatefulWidget {
  const ManageElectionsPage({super.key});

  @override
  State<ManageElectionsPage> createState() => _ManageElectionsPageState();
}

class _ManageElectionsPageState extends State<ManageElectionsPage> {
  final api = ApiService();
  List<dynamic> elections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => isLoading = true);
    final res = await api.get("elections/", UserRole.admin);
    if (mounted) {
      setState(() {
        if (res.statusCode == 200) elections = jsonDecode(res.body);
        isLoading = false;
      });
    }
  }

  void _showDialog([Map<String, dynamic>? e]) {
    final isEdit = e != null;
    final nameCtrl = TextEditingController(text: isEdit ? e['name'] : '');
    final descCtrl = TextEditingController(text: isEdit ? (e['description'] ?? '') : '');
    final startCtrl = TextEditingController(text: isEdit ? _fmt(e['start_at']) : '');
    final endCtrl = TextEditingController(text: isEdit ? _fmt(e['end_at']) : '');
    bool active = isEdit ? (e['is_active'] ?? true) : true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? "Edit Periode" : "Tambah Periode"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Periode", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: startCtrl, decoration: const InputDecoration(labelText: "Mulai (YYYY-MM-DD HH:MM)", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: endCtrl, decoration: const InputDecoration(labelText: "Selesai (YYYY-MM-DD HH:MM)", border: OutlineInputBorder())),
                SwitchListTile(
                  title: const Text("Aktif"),
                  value: active,
                  onChanged: (v) => setDialogState(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final body = {
                  "name": nameCtrl.text.trim(),
                  "description": descCtrl.text.trim(),
                  "start_at": _toIso(startCtrl.text),
                  "end_at": _toIso(endCtrl.text),
                  "is_active": active,
                };
                http.Response res = isEdit
                    ? await api.patchJson("elections/${e['id']}/", body, UserRole.admin)
                    : await api.post("elections/", body, UserRole.admin);
                Navigator.pop(ctx);
                if (res.statusCode == 200 || res.statusCode == 201) {
                  fetch();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${res.body}")));
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> e) async {
    final res = await api.patchJson("elections/${e['id']}/", {"is_active": !(e['is_active'] ?? false)}, UserRole.admin);
    if (res.statusCode == 200) fetch();
  }

  void _delete(Map<String, dynamic> e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Periode"),
        content: Text("Hapus periode '${e['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await api.delete("elections/${e['id']}/", UserRole.admin);
              if (res.statusCode == 204 || res.statusCode == 200) fetch();
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Pemilihan"), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah Periode"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : elections.isEmpty
              ? const Center(child: Text("Belum ada periode pemilihan."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: elections.length,
                  itemBuilder: (context, i) {
                    final e = elections[i];
                    final status = e['status'] ?? '';
                    final color = status == 'ongoing' ? Colors.green : (status == 'upcoming' ? Colors.orange : Colors.grey);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${_fmt(e['start_at'])} → ${_fmt(e['end_at'])}"),
                            Text("Topik: ${e['topic_count'] ?? 0} | DPT: ${e['voter_count'] ?? 0}"),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.group, color: Colors.deepOrange),
                              tooltip: "Kelola DPT",
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ManageDptPage(election: e)),
                              ),
                            ),
                            IconButton(
                              icon: Icon(e['is_active'] == true ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => _toggleActive(e),
                            ),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(e)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(e)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ManageRegionsPage extends StatefulWidget {
  const ManageRegionsPage({super.key});

  @override
  State<ManageRegionsPage> createState() => _ManageRegionsPageState();
}

class _ManageRegionsPageState extends State<ManageRegionsPage> {
  final api = ApiService();
  List<dynamic> regions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    final res = await api.get("elections/regions/", UserRole.admin);
    if (mounted) {
      setState(() {
        if (res.statusCode == 200) regions = jsonDecode(res.body);
        isLoading = false;
      });
    }
  }

  void _showDialog([Map<String, dynamic>? r]) {
    final isEdit = r != null;
    final nameCtrl = TextEditingController(text: isEdit ? r['name'] : '');
    final codeCtrl = TextEditingController(text: isEdit ? r['code'] : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Edit Wilayah" : "Tambah Wilayah"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Wilayah", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Kode (mis. JKT)", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final body = {"name": nameCtrl.text.trim(), "code": codeCtrl.text.trim()};
              http.Response res = isEdit
                  ? await api.patchJson("elections/regions/${r['id']}/", body, UserRole.admin)
                  : await api.post("elections/regions/", body, UserRole.admin);
              Navigator.pop(ctx);
              if (res.statusCode == 200 || res.statusCode == 201) fetch();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _delete(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Wilayah"),
        content: Text("Hapus '${r['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await api.delete("elections/regions/${r['id']}/", UserRole.admin);
              if (res.statusCode == 204 || res.statusCode == 200) fetch();
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Wilayah"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah Wilayah"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: regions.length,
              itemBuilder: (context, i) {
                final r = regions[i];
                return Card(
                  child: ListTile(
                    title: Text(r['name'] ?? ''),
                    subtitle: Text("Kode: ${r['code'] ?? '-'}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(r)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(r)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ManageDptPage extends StatefulWidget {
  final Map<String, dynamic> election;
  const ManageDptPage({super.key, required this.election});

  @override
  State<ManageDptPage> createState() => _ManageDptPageState();
}

class _ManageDptPageState extends State<ManageDptPage> {
  final api = ApiService();
  late List<dynamic> voters;
  List<dynamic> regions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    voters = [];
    fetch();
  }

  Future<void> fetch() async {
    setState(() => isLoading = true);
    final res = await api.get("elections/${widget.election['id']}/voters/", UserRole.admin);
    final resR = await api.get("elections/regions/", UserRole.admin);
    if (mounted) {
      setState(() {
        if (res.statusCode == 200) voters = jsonDecode(res.body);
        if (resR.statusCode == 200) regions = jsonDecode(resR.body);
        isLoading = false;
      });
    }
  }

  void _addVoter() {
    final phoneCtrl = TextEditingController();
    int? regionId;
    bool active = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah ke DPT"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Nomor HP", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButton<int>(
                isExpanded: true,
                value: regionId,
                hint: const Text("Wilayah (opsional)"),
                items: regions.map<DropdownMenuItem<int>>((r) => DropdownMenuItem<int>(value: r['id'], child: Text(r['name'] ?? ''))).toList(),
                onChanged: (v) => setDialogState(() => regionId = v),
              ),
              SwitchListTile(
                title: const Text("Aktif"),
                value: active,
                onChanged: (v) => setDialogState(() => active = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (phoneCtrl.text.trim().isEmpty) return;
                final res = await api.post(
                  "elections/${widget.election['id']}/voters/",
                  {"phone_number": phoneCtrl.text.trim(), "region": regionId, "is_active": active},
                  UserRole.admin,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.statusCode == 201 || res.statusCode == 200 ? "Pemilih ditambahkan." : "Gagal: ${res.body}")));
                fetch();
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeVoter(Map<String, dynamic> v) async {
    final res = await api.post(
      "elections/${widget.election['id']}/remove_voter/",
      {"voter_id": v['id']},
      UserRole.admin,
    );
    if (res.statusCode == 200) fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("DPT - ${widget.election['name']}"), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVoter,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : voters.isEmpty
              ? const Center(child: Text("Belum ada pemilih terdaftar."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: voters.length,
                  itemBuilder: (context, i) {
                    final v = voters[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(v['username'] ?? v['phone_number'] ?? ''),
                        subtitle: Text("Wilayah: ${(v['region'] as Map?)?['name'] ?? '-'} | Aktif: ${v['is_active']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_remove, color: Colors.red),
                          onPressed: () => _removeVoter(v),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
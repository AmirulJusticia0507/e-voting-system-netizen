import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ManageRolesPage extends StatefulWidget {
  const ManageRolesPage({super.key});

  @override
  State<ManageRolesPage> createState() => _ManageRolesPageState();
}

class _ManageRolesPageState extends State<ManageRolesPage> {
  final api = ApiService();
  List<dynamic> roles = [];
  List<dynamic> permissions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final resR = await api.get("roles/", UserRole.admin);
    final resP = await api.get("roles/permissions/", UserRole.admin);
    if (mounted) {
      setState(() {
        if (resR.statusCode == 200) roles = jsonDecode(resR.body);
        if (resP.statusCode == 200) permissions = jsonDecode(resP.body);
        isLoading = false;
      });
    }
  }

  void _showRoleDialog([Map<String, dynamic>? role]) {
    final isEdit = role != null;
    final nameCtrl = TextEditingController(text: isEdit ? role['name'] : '');
    final descCtrl = TextEditingController(text: isEdit ? (role['description'] ?? '') : '');
    Set<int> selected = isEdit
        ? Set<int>.from((role['permissions'] as List<dynamic>? ?? [])
            .map((p) => p is int ? p : (p is Map ? p['id'] : 0))
            .where((e) => e != 0))
        : {};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? "Edit Role" : "Tambah Role"),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    enabled: !(isEdit && role?['is_system'] == true),
                    decoration: const InputDecoration(labelText: "Nama Role", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text("Izin (permissions):", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...permissions.map((p) {
                    final id = p['id'];
                    final enabled = isEdit && role?['is_system'] == true && role?['name'] == 'superadmin';
                    return CheckboxListTile(
                      dense: true,
                      title: Text(p['name'] ?? p['code'] ?? ''),
                      subtitle: Text(p['code'] ?? ''),
                      value: selected.contains(id),
                      onChanged: enabled
                          ? null
                          : (val) => setDialogState(() {
                                val! ? selected.add(id) : selected.remove(id);
                              }),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                http.Response res;
                if (isEdit) {
                  res = await api.patchJson("roles/${role['id']}/", {
                    "name": nameCtrl.text.trim(),
                    "description": descCtrl.text.trim(),
                    "permissions": selected.toList(),
                  }, UserRole.admin);
                } else {
                  res = await api.post("roles/", {
                    "name": nameCtrl.text.trim(),
                    "description": descCtrl.text.trim(),
                    "permissions": selected.toList(),
                  }, UserRole.admin);
                }
                Navigator.pop(ctx);
                if (res.statusCode == 200 || res.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Role disimpan.")),
                  );
                  fetchData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal: ${res.body}")),
                  );
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRole(Map<String, dynamic> role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Role"),
        content: Text("Hapus role '${role['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await api.delete("roles/${role['id']}/", UserRole.admin);
              if (res.statusCode == 204 || res.statusCode == 200) {
                fetchData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Gagal hapus: ${res.body}")),
                );
              }
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
      appBar: AppBar(
        title: const Text("Kelola Role & Izin"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoleDialog(),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah Role"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : roles.isEmpty
              ? const Center(child: Text("Belum ada role."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: roles.length,
                  itemBuilder: (context, i) {
                    final r = roles[i];
                    final codes = (r['permission_codes'] as List<dynamic>? ?? []);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (r['is_system'] == true) ...[
                              const SizedBox(width: 8),
                              const Chip(label: Text("Sistem"), visualDensity: VisualDensity.compact),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((r['description'] ?? '').isNotEmpty) Text(r['description'] ?? ''),
                            const SizedBox(height: 6),
                            Text(
                              "User: ${r['user_count'] ?? 0} | Izin: ${codes.join(', ')}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: r['is_system'] == true
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showRoleDialog(r),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteRole(r),
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
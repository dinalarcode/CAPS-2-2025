import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestPage extends StatefulWidget {
  const FirestoreTestPage({super.key});
  @override
  State<FirestoreTestPage> createState() => _FirestoreTestPageState();
}

class _FirestoreTestPageState extends State<FirestoreTestPage> {
  final _collC = TextEditingController(text: 'users');

  @override
  void dispose() {
    _collC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collName = _collC.text.trim().isEmpty ? 'users' : _collC.text.trim();
    final query = FirebaseFirestore.instance.collection(collName).limit(100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Explorer (Lite)'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _collC,
                    decoration: const InputDecoration(
                      labelText: 'Nama koleksi (mis. users)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Load'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Kosong / tidak ada dokumen.'));
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final id = d.id;
                    final data = d.data() as Map<String, dynamic>? ?? {};
                    // tampilkan 1–2 field populer kalau ada:
                    final preview = [
                      if (data['email'] != null) 'email: ${data['email']}',
                      if (data['name'] != null) 'name: ${data['name']}',
                    ].join(' · ');
                    return ListTile(
                      title: Text(id),
                      subtitle: Text(
                        preview.isEmpty ? data.toString() : preview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _showDoc(context, collName, d),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDoc(BuildContext context, String coll, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(12),
          child: ListView(
            controller: controller,
            children: [
              Text('$coll / ${doc.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(
                _prettyJson(data),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> m) {
    // biar gampang dibaca, tanpa import dart:convert
    final b = StringBuffer();
    void w(dynamic v, [int indent = 0]) {
      final pad = '  ' * indent;
      if (v is Map) {
        b.writeln('{');
        v.forEach((k, val) {
          b.write('$pad  $k: ');
          w(val, indent + 1);
        });
        b.writeln('$pad}');
      } else if (v is List) {
        b.writeln('[');
        for (final e in v) {
          b.write('$pad  ');
          w(e, indent + 1);
        }
        b.writeln('$pad]');
      } else {
        b.writeln(v.toString());
      }
    }
    w(m);
    return b.toString();
  }
}

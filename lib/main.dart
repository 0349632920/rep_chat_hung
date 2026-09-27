import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

const String FIREBASE_URL = 'https://chat-app-hung-default-rtdb.asia-southeast1.firebasedatabase.app';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhan tin nhan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const ReceiveScreen(),
    );
  }
}

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});
  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  List<Map<String, dynamic>> _messages = [];
  Timer? _timer;
  bool _loading = true;
  int _lastCount = 0;
  String _lastError = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final url = '$FIREBASE_URL/messages.json';
      final r = await http.get(Uri.parse(url));
      print('LOAD: $url -> ${r.statusCode}');
      print('BODY: ${r.body}');

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data == null) {
          setState(() {
            _messages = [];
            _loading = false;
            _lastError = '';
          });
          return;
        }
        final Map<String, dynamic> map = Map<String, dynamic>.from(data);
        final list = map.entries
            .map((e) => {...Map<String, dynamic>.from(e.value), 'id': e.key})
            .toList();
        list.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
        setState(() {
          _messages = list;
          _loading = false;
          _lastError = '';
        });
        if (list.length > _lastCount && _lastCount > 0) {
          final newest = list.last;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tin moi tu ${newest['user']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _lastCount = list.length;
      } else {
        setState(() {
          _loading = false;
          _lastError = 'HTTP ${r.statusCode}';
        });
      }
    } catch (e) {
      print('LOI: $e');
      setState(() {
        _loading = false;
        _lastError = '$e';
      });
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoa tat ca?'),
        content: const Text('Ban co chac muon xoa het tin nhan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await http.delete(Uri.parse('$FIREBASE_URL/messages.json'));
      setState(() {
        _messages = [];
        _lastCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhan tin nhan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages, tooltip: 'Tai lai'),
          IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _messages.isEmpty ? null : _clearAll,
              tooltip: 'Xoa het'),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wifi_tethering, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Dang lang nghe... (${_messages.length} tin nhan)',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                    if (_loading)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
                  ],
                ),
                if (_lastError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Loi: $_lastError',
                        style: const TextStyle(color: Colors.red, fontSize: 11)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Chua co tin nhan nao',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Mo app Chat de gui tin nhan thu',
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final m = _messages[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.green.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.green,
                                      child: Text(
                                        (m['user'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(m['user'] ?? 'An danh',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 15)),
                                          Text(m['time'] ?? '',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.mark_email_unread,
                                        color: Colors.green, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(m['text'] ?? '', style: const TextStyle(fontSize: 15)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

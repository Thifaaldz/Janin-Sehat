import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  final int userId;
  const CalendarPage({super.key, required this.userId});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime? _selectedHpht;
  String? _edd;
  List<dynamic> _schedule = [];
  Map<DateTime, List<String>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = false;

  /// Ambil HPHT user dari backend
  Future<void> _loadUserHpht() async {
    setState(() => _loading = true);
    final url = Uri.parse("http://127.0.0.1:9000/auth/profile/${widget.userId}");
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data["hptp"] != null && data["hptp"].toString().isNotEmpty) {
          setState(() {
            _selectedHpht = DateTime.parse(data["hptp"]);
          });
          await _fetchCalendar();
        } else {
          setState(() => _loading = false);
        }
      } else {
        debugPrint("Gagal ambil profile: ${resp.body}");
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Error ambil HPHT: $e");
      setState(() => _loading = false);
    }
  }

  /// Ambil jadwal dari backend
  Future<void> _fetchCalendar() async {
    if (_selectedHpht == null) return;

    setState(() => _loading = true);
    final url = Uri.parse(
        "http://127.0.0.1:9000/calendar/schedule?hpht=${_selectedHpht!.toIso8601String().split('T')[0]}");

    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final schedule = List<Map<String, dynamic>>.from(data["schedule"]);

        Map<DateTime, List<String>> events = {};
        for (var item in schedule) {
          final date = DateTime.parse(item["tanggal"]);
          final key = DateTime(date.year, date.month, date.day);
          events.putIfAbsent(key, () => []);
          events[key]!.add(item["kegiatan"]);
        }

        setState(() {
          _edd = data["edd"];
          _schedule = schedule;
          _events = events;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        debugPrint("Gagal fetch kalender: ${resp.body}");
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserHpht();
  }

  /// Hitung progress kehamilan berdasarkan tanggal hari ini
  double _calculateProgress() {
    if (_selectedHpht == null || _schedule.isEmpty) return 0;
    final today = DateTime.now();
    int done = _schedule.where((e) {
      final d = DateTime.parse(e["tanggal"]);
      return d.isBefore(today) || d.isAtSameMomentAs(today);
    }).length;
    return done / _schedule.length;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text("📅 Kalender Kehamilan"),
        backgroundColor: Colors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info HPHT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedHpht == null
                            ? "HPHT belum diisi"
                            : "HPHT: ${_selectedHpht!.toLocal().toString().split(' ')[0]}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (_edd != null)
                        Text(
                          "Perkiraan Persalinan: $_edd",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Kalender dengan event
                  if (_selectedHpht != null)
                    TableCalendar(
                      focusedDay: _focusedDay,
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2100),
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      eventLoader: (day) =>
                          _events[DateTime(day.year, day.month, day.day)] ?? [],
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                            color: Colors.orange, shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(
                            color: Colors.teal, shape: BoxShape.circle),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });

                        final events = _events[
                            DateTime(selectedDay.year, selectedDay.month, selectedDay.day)] ?? [];

                        if (events.isNotEmpty) {
                          // Popup kecil menampilkan event
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Kegiatan ${selectedDay.day}-${selectedDay.month}"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: events
                                    .map((e) => ListTile(
                                          leading: const Icon(Icons.event_note, color: Colors.teal),
                                          title: Text(e),
                                        ))
                                    .toList(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Tutup"),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isNotEmpty) {
                            return Positioned(
                              bottom: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: events
                                    .map((e) => Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 1),
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.teal,
                                            shape: BoxShape.circle,
                                          ),
                                        ))
                                    .toList(),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Progress keseluruhan
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          color: Colors.teal,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("${(progress * 100).toStringAsFixed(1)}%"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scrollable list semua jadwal
                  Expanded(
                    child: ListView.builder(
                      itemCount: _schedule.length,
                      itemBuilder: (ctx, i) {
                        final item = _schedule[i];
                        final date = DateTime.parse(item["tanggal"]);
                        final isDone = date.isBefore(DateTime.now()) || date.isAtSameMomentAs(DateTime.now());
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            leading: Icon(
                              isDone ? Icons.check_circle : Icons.pending,
                              color: isDone ? Colors.teal : Colors.orange,
                            ),
                            title: Text(item["kegiatan"]),
                            subtitle: Text(item["tanggal"]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

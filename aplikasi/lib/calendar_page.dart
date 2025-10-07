import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  bool _loadingHpht = false;
  bool _loadingSchedule = false;

  final String baseUrl = "http://127.0.0.1:9000";

  @override
  void initState() {
    super.initState();
    _initializeCalendar();
  }

  Future<void> _initializeCalendar() async {
    setState(() {
      _loadingHpht = true;
      _loadingSchedule = true;
    });

    await Future.wait([
      _loadUserHpht(),
      Future.delayed(const Duration(milliseconds: 200))
    ]);
  }

  Future<void> _loadUserHpht() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/profile/${widget.userId}"));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final hphtStr = data["user"]["hptp"];
        if (hphtStr != null && hphtStr.isNotEmpty) {
          _selectedHpht = DateTime.tryParse(hphtStr);
          await _fetchCalendar();
        }
      } else {
        debugPrint("Gagal ambil profile: ${resp.body}");
      }
    } catch (e) {
      debugPrint("❌ Error ambil HPHT: $e");
    } finally {
      setState(() => _loadingHpht = false);
    }
  }

  Future<void> _fetchCalendar() async {
    if (_selectedHpht == null) return;
    setState(() => _loadingSchedule = true);

    try {
      final url = Uri.parse(
        "$baseUrl/calendar/schedule?hpht=${_selectedHpht!.toIso8601String().split('T')[0]}",
      );
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final schedule = List<Map<String, dynamic>>.from(data["schedule"]);

        final Map<DateTime, List<String>> events = {};
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
        });
      } else {
        debugPrint("❌ Gagal fetch calendar: ${resp.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetch calendar: $e");
    } finally {
      setState(() => _loadingSchedule = false);
    }
  }

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
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text("📅 Kalender Kehamilan"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: _loadingHpht
          ? const Center(child: CircularProgressIndicator())
          : _selectedHpht == null
              ? const Center(
                  child: Text(
                    "⚠️ Belum ada data HPHT. Silakan hubungi petugas untuk mengisi data awal.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 📌 Card Informasi Kehamilan
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("📆 Tanggal HPHT",
                                          style: TextStyle(color: Colors.grey)),
                                      Text(
                                        _selectedHpht!.toLocal().toString().split(' ')[0],
                                        style: const TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  if (_edd != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text("🍼 Perkiraan Persalinan",
                                            style: TextStyle(color: Colors.grey)),
                                        Text(
                                          _edd!,
                                          style: const TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                borderRadius: BorderRadius.circular(8),
                                backgroundColor: Colors.grey[300],
                                color: Colors.teal,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "📈 Perjalanan Kehamilan: ${(progress * 100).toStringAsFixed(1)}%",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 📅 Kalender (tinggi tetap agar tidak ketimpa)
                      SizedBox(
                        height: 430, // ✅ Tinggi kalender diatur supaya tanggal tidak ketutup
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: TableCalendar(
                              focusedDay: _focusedDay,
                              firstDay: DateTime(2020),
                              lastDay: DateTime(2100),
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              eventLoader: (day) =>
                                  _events[DateTime(day.year, day.month, day.day)] ?? [],
                              calendarStyle: const CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: Colors.teal,
                                  shape: BoxShape.circle,
                                ),
                                markersMaxCount: 3,
                                markerDecoration: BoxDecoration(
                                  color: Colors.teal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });

                                final events = _events[DateTime(
                                        selectedDay.year, selectedDay.month, selectedDay.day)] ??
                                    [];

                                if (events.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                          "📌 Kegiatan ${selectedDay.day}-${selectedDay.month}-${selectedDay.year}"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: events
                                            .map((e) => ListTile(
                                                  leading: const Icon(Icons.event_note,
                                                      color: Colors.teal),
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
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 📋 Jadwal
                      const Text(
                        "📅 Jadwal Pemeriksaan & Kegiatan",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(height: 10),
                      _loadingSchedule
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: _schedule.map((item) {
                                final date = DateTime.parse(item["tanggal"]);
                                final isDone = date.isBefore(DateTime.now()) ||
                                    date.isAtSameMomentAs(DateTime.now());
                                return Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: Icon(
                                      isDone ? Icons.check_circle : Icons.pending_actions,
                                      color: isDone ? Colors.teal : Colors.orange,
                                      size: 30,
                                    ),
                                    title: Text(item["kegiatan"],
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      item["tanggal"],
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
    );
  }
}

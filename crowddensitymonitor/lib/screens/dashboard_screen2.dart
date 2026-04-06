import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String wsUrl = 'ws://192.168.31.5:3000/flutter'; // ⚠️ change IP

  WebSocketChannel? _channel;

  int _count = 0;
  double _density = 0;
  String _status = 'SAFE';
  String _lastTime = '--';

  bool _isNodeConnected = false;
  bool _isEspConnected = false;

  final List<FlSpot> _chartData = [];
  int _chartIndex = 0;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          if (!mounted) return;

          final data = jsonDecode(message);

          if (data['type'] == 'STATUS') {
            setState(() {
              _isNodeConnected = data['node'] ?? false;
              _isEspConnected = data['esp'] ?? false;
            });
          }

          if (data['type'] == 'DATA') {
            setState(() {
              _count = data['count'] ?? 0;
              _density = (data['density'] ?? 0).toDouble();
              _status = data['status'] ?? 'SAFE';
              _lastTime =
                  DateFormat('hh:mm:ss a').format(DateTime.now());

              _chartData.add(
                FlSpot(_chartIndex.toDouble(), _count.toDouble()),
              );

              if (_chartData.length > 20) {
                _chartData.removeAt(0);
              }

              _chartIndex++;
            });
          }
        },
        onDone: () {
          setState(() {
            _isNodeConnected = false;
            _isEspConnected = false;
          });
          _reconnect();
        },
        onError: (_) {
          setState(() {
            _isNodeConnected = false;
            _isEspConnected = false;
          });
          _reconnect();
        },
      );
    } catch (_) {
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _connect();
    });
  }

  Color get _statusColor =>
      _status == 'OVERCROWDED' ? Colors.red : Colors.green;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Crowd Monitor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── STATUS BAR ─────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage,
                          color: _isNodeConnected
                              ? Colors.green
                              : Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        _isNodeConnected
                            ? "Node Online"
                            : "Node Offline",
                        style:
                            const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.memory,
                          color: _isEspConnected
                              ? Colors.green
                              : Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        _isEspConnected
                            ? "ESP Connected"
                            : "ESP Disconnected",
                        style:
                            const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── MAIN STATUS ────────────
            Text(
              _status,
              style: TextStyle(
                color: _statusColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text("Updated: $_lastTime",
                style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 20),

            // ── INFO ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("People: $_count",
                    style: const TextStyle(color: Colors.white)),
                Text("Density: ${_density.toStringAsFixed(1)}%",
                    style: TextStyle(color: _statusColor)),
              ],
            ),

            const SizedBox(height: 20),

            LinearProgressIndicator(
              value: _density / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[800],
              valueColor:
                  AlwaysStoppedAnimation<Color>(_statusColor),
            ),

            const SizedBox(height: 20),

            // ── CHART ─────────────────
            Expanded(
              child: LineChart(
                LineChartData(
                  titlesData:
                      const FlTitlesData(show: false),
                  borderData:
                      FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData,
                      isCurved: true,
                      color: Colors.blue,
                      dotData:
                          const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
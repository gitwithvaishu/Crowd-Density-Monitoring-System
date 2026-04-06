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
  final String wsUrl = 'ws://192.168.31.5:3000/flutter';

  WebSocketChannel? _channel;

  int _count = 0;
  double _density = 0;
  String _status = 'SAFE';
  String _lastEvent = '--';
  String _lastTime = '--';
  int _maxCapacity = 50;

  bool _isNodeConnected = false;
  bool _isEspConnected = false;

  final List<FlSpot> _chartData = [];
  int _chartIndex = 0;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  //CONNECT
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          if (!mounted) return;

          final data = jsonDecode(message);

          //STATUS MESSAGE
          if (data['type'] == 'STATUS') {
            setState(() {
              _isNodeConnected = data['node'] ?? false;
              _isEspConnected = data['esp'] ?? false;
            });
          }

          //  DATA MESSAGE
          if (data['type'] == 'DATA') {
            setState(() {
              _count = data['count'] ?? 0;
              _density = (data['density'] ?? 0).toDouble();
              _status = data['status'] ?? 'SAFE';
              _lastEvent = data['event'] ?? '--';
              _maxCapacity = data['maxCapacity'] ?? 50;
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
          _handleDisconnect();
        },
        onError: (err) {
          debugPrint('WS Error: $err');
          _handleDisconnect();
        },
      );

      // If connected → node is online
      setState(() {
        _isNodeConnected = true;
      });

    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    setState(() {
      _isNodeConnected = false;
      _isEspConnected = false;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _connectWebSocket();
    });
  }

  // UI HELPERS 
  Color get _statusColor {
    switch (_status) {
      case 'OVERCROWDED':
        return Colors.red;
      case 'MODERATE':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'OVERCROWDED':
        return Icons.dangerous;
      case 'MODERATE':
        return Icons.warning_amber;
      default:
        return Icons.check_circle;
    }
  }

  //  UI 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          '🏙️ Crowd Monitor',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            //  CONNECTION STATUS BAR 
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
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
                        style: const TextStyle(color: Colors.white),
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
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            //  STATUS CARD 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusColor, width: 2),
              ),
              child: Column(
                children: [
                  Icon(_statusIcon, color: _statusColor, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Last update: $_lastTime',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            //  INFO ROW 
            Row(
              children: [
                _infoCard('👥 People', '$_count / $_maxCapacity', Colors.blue),
                const SizedBox(width: 12),
                _infoCard('📊 Density', '${_density.toStringAsFixed(1)}%', _statusColor),
              ],
            ),

            const SizedBox(height: 16),

            //  PROGRESS BAR 
            LinearProgressIndicator(
              value: _density / 100,
              minHeight: 15,
              backgroundColor: Colors.grey[800],
              valueColor:
                  AlwaysStoppedAnimation<Color>(_statusColor),
            ),

            const SizedBox(height: 20),

            //  CHART 
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _chartData.isEmpty
                  ? const Center(
                      child: Text("Waiting for data...",
                          style: TextStyle(color: Colors.grey)),
                    )
                  : LineChart(
                      LineChartData(
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _chartData,
                            isCurved: true,
                            color: Colors.blue,
                            dotData: const FlDotData(show: false),
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

  Widget _infoCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
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
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   // ── Replace with your PC's local IP ──────────
//   final String wsUrl = 'ws://192.168.31.5:3000';

//   late WebSocketChannel _channel;
//   int _count       = 0;
//   int _density     = 0;
//   String _status   = 'SAFE';
//   String _lastEvent = '--';
//   String _lastTime  = '--';
//   int _maxCapacity  = 50;

//   final List<FlSpot> _chartData = [];
//   int _chartIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _connectWebSocket();
//   }

//   void _connectWebSocket() {
//     _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
//     _channel.stream.listen(
//       (message) {
//         final data = jsonDecode(message);
//         setState(() {
//           _count       = data['count']       ?? 0;
//           _density     = data['density']     ?? 0;
//           _status      = data['status']      ?? 'SAFE';
//           _lastEvent   = data['event']       ?? '--';
//           _maxCapacity = data['maxCapacity'] ?? 50;
//           _lastTime    = DateFormat('hh:mm:ss a')
//               .format(DateTime.now());

//           _chartData.add(FlSpot(
//             _chartIndex.toDouble(),
//             _count.toDouble(),
//           ));
//           if (_chartData.length > 20) _chartData.removeAt(0);
//           _chartIndex++;
//         });
//       },
//       onError: (err) {
//         print('WebSocket error: $err');
//         Future.delayed(const Duration(seconds: 3), _connectWebSocket);
//       },
//       onDone: () {
//         print('WebSocket closed. Reconnecting...');
//         Future.delayed(const Duration(seconds: 3), _connectWebSocket);
//       },
//     );
//   }

//   Color get _statusColor {
//     switch (_status) {
//       case 'MODERATE':    return Colors.orange;
//       case 'OVERCROWDED': return Colors.red;
//       default:            return Colors.green;
//     }
//   }

//   IconData get _statusIcon {
//     switch (_status) {
//       case 'MODERATE':    return Icons.warning_amber;
//       case 'OVERCROWDED': return Icons.dangerous;
//       default:            return Icons.check_circle;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0D1117),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF161B22),
//         title: const Text(
//           '🏙️ Crowd Monitor',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 16),
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.green.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: Colors.green),
//             ),
//             child: const Row(
//               children: [
//                 Icon(Icons.circle, color: Colors.green, size: 8),
//                 SizedBox(width: 6),
//                 Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 12)),
//               ],
//             ),
//           )
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // ── Status Card ──────────────────
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: _statusColor.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: _statusColor, width: 2),
//               ),
//               child: Column(
//                 children: [
//                   Icon(_statusIcon, color: _statusColor, size: 48),
//                   const SizedBox(height: 8),
//                   Text(
//                     _status,
//                     style: TextStyle(
//                       color: _statusColor,
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'Last update: $_lastTime',
//                     style: const TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // ── Count + Density Row ──────────
//             Row(
//               children: [
//                 _infoCard('👥 People Inside', '$_count / $_maxCapacity', Colors.blue),
//                 const SizedBox(width: 12),
//                 _infoCard('📊 Density', '$_density%', _statusColor),
//               ],
//             ),

//             const SizedBox(height: 16),

//             // ── Last Event ───────────────────
//             Row(
//               children: [
//                 _infoCard(
//                   '🚶 Last Event',
//                   _lastEvent,
//                   _lastEvent == 'ENTRY' ? Colors.green : Colors.red,
//                 ),
//                 const SizedBox(width: 12),
//                 _infoCard('🕐 At', _lastTime, Colors.purple),
//               ],
//             ),

//             const SizedBox(height: 16),

//             // ── Density Progress Bar ─────────
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF161B22),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Capacity Usage',
//                     style: TextStyle(color: Colors.white70, fontSize: 14),
//                   ),
//                   const SizedBox(height: 10),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: LinearProgressIndicator(
//                       value: _density / 100,
//                       minHeight: 20,
//                       backgroundColor: Colors.grey[800],
//                       valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     '$_density% occupied',
//                     style: TextStyle(color: _statusColor, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // ── Live Chart ───────────────────
//             Container(
//               padding: const EdgeInsets.all(16),
//               height: 200,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF161B22),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Live Crowd Trend',
//                     style: TextStyle(color: Colors.white70, fontSize: 14),
//                   ),
//                   const SizedBox(height: 12),
//                   Expanded(
//                     child: _chartData.isEmpty
//                         ? const Center(
//                             child: Text(
//                               'Waiting for data...',
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           )
//                         : LineChart(
//                             LineChartData(
//                               gridData: const FlGridData(show: false),
//                               titlesData: const FlTitlesData(show: false),
//                               borderData: FlBorderData(show: false),
//                               lineBarsData: [
//                                 LineChartBarData(
//                                   spots: _chartData,
//                                   isCurved: true,
//                                   color: Colors.blue,
//                                   barWidth: 3,
//                                   dotData: const FlDotData(show: false),
//                                   belowBarData: BarAreaData(
//                                     show: true,
//                                     color: Colors.blue.withOpacity(0.15),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _infoCard(String label, String value, Color color) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: const Color(0xFF161B22),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: color.withOpacity(0.4)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(label,
//                 style: const TextStyle(color: Colors.grey, fontSize: 12)),
//             const SizedBox(height: 6),
//             Text(value,
//                 style: TextStyle(
//                     color: color,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _channel.sink.close();
//     super.dispose();
//   }
// }
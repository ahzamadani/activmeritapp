import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class MeritAnalysis extends StatefulWidget {
  const MeritAnalysis({Key? key}) : super(key: key);

  @override
  State<MeritAnalysis> createState() => _MeritAnalysisState();
}

class _MeritAnalysisState extends State<MeritAnalysis> {
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  int _accumulatedMerit = 0;
  List<FlSpot> _chartData = [];
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMeritData();
  }

  Future<void> _fetchMeritData() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'No authenticated user.';
      });
      return;
    }

    final userEmail = user.email;
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'User data not found.';
      });
      return;
    }

    final userData = userSnapshot.docs.first.data() as Map<String, dynamic>?;
    if (userData == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'User data is null.';
      });
      return;
    }

    final matricNumber = userData['matricNumber'] as String?;

    if (matricNumber == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'Matric number not found.';
      });
      return;
    }

    final activityLogs =
        await FirebaseFirestore.instance.collection('activitylog').get();

    if (activityLogs.docs.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'No activity logs found.';
      });
      return;
    }

    int totalMerit = 0;
    Map<DateTime, int> meritByMonth = {};
    List<Map<String, dynamic>> events = [];

    for (var log in activityLogs.docs) {
      final scannedUserDoc =
          await log.reference.collection('scannedUser').doc(matricNumber).get();

      if (scannedUserDoc.exists) {
        final eventRef = log['eventId'] as DocumentReference?;
        if (eventRef == null) continue;

        final eventSnapshot = await eventRef.get();
        if (eventSnapshot.exists) {
          final eventData = eventSnapshot.data() as Map<String, dynamic>?;
          if (eventData == null) continue;

          final eventMerit = eventData['merit'] is String
              ? int.tryParse(eventData['merit']) ?? 1
              : eventData['merit'] as int?;
          if (eventMerit == null) continue;

          totalMerit += eventMerit;

          final eventDate = DateTime.tryParse(eventData['date'] ?? '');
          if (eventDate == null) continue;

          final eventMonth = DateTime(eventDate.year, eventDate.month);

          if (!meritByMonth.containsKey(eventMonth)) {
            meritByMonth[eventMonth] = 0;
          }
          meritByMonth[eventMonth] = meritByMonth[eventMonth]! + eventMerit;

          final timestamp = (scannedUserDoc.data()
              as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
          final eventTime = timestamp != null
              ? DateFormat('HH:mm:ss').format(timestamp.toDate())
              : 'Unknown Time';

          events.add({
            'name': eventData['eventName'] ?? 'Unknown Event',
            'eventDate': eventDate,
            'scanDate': timestamp?.toDate(),
            'time': eventTime,
            'merit': eventMerit,
          });
        }
      }
    }

    List<FlSpot> monthlyMeritPoints = [];
    for (var entry in meritByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      monthlyMeritPoints
          .add(FlSpot(entry.key.month.toDouble(), entry.value.toDouble()));
    }

    events.sort((a, b) => b['scanDate'].compareTo(a['scanDate']));

    setState(() {
      _accumulatedMerit = totalMerit;
      _chartData = monthlyMeritPoints;
      _events = events;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Merit Analysis'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white.withOpacity(0.3),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff717ff5), Color(0xffcfe2ff)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.all(16),
                        color: Colors.white, // Ensuring the card color is white
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Monthly Merit Accumulation',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              AspectRatio(
                                aspectRatio: 1.70,
                                child: LineChart(
                                  mainData(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return _buildEventCard(event);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['name'] ?? 'Unknown Event',
                        style: TextStyle(
                          fontSize: 20, // Adjusted font size to avoid overflow
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow
                            .ellipsis, // Ensure text doesn't overflow
                      ),
                      SizedBox(height: 8.0),
                      Text(
                          'Date: ${DateFormat('d MMM yyyy').format(event['eventDate'])}'),
                      Text('Time: ${event['time']}'),
                    ],
                  ),
                ),
                Text(
                  '+${event['merit']}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LineChartData mainData() {
    double maxYValue = (_accumulatedMerit).toDouble();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 5,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Color.fromARGB(255, 232, 240, 246)),
      ),
      minX: _chartData.isNotEmpty ? _chartData.first.x : 0,
      maxX: _chartData.isNotEmpty ? _chartData.last.x : 12,
      minY: 0,
      maxY: maxYValue,
      lineBarsData: [
        LineChartBarData(
          spots: _chartData,
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      ],
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    final monthIndex = value.toInt() - 1;
    final month = (monthIndex >= 0 && monthIndex < months.length)
        ? months[monthIndex]
        : '';

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(month, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    return Text('${value.toInt()}', style: style, textAlign: TextAlign.left);
  }
}

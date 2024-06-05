import 'package:flutter/material.dart';
import 'package:activmerit/CreateEventPage.dart';
import 'package:activmerit/EventHistoryPage.dart';
import 'package:activmerit/ProfilePage.dart';
import 'package:activmerit/qrScan.dart';
import 'package:activmerit/colors.dart';
import 'package:activmerit/MeritAnalysis.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ActivMerit',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageController _pageController = PageController();

  static List<Widget> _widgetOptions = <Widget>[
    HomePageContent(),
    CreateEventPage(),
    EventHistoryPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff717ff5), Color(0xffcfe2ff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: PageView(
          controller: _pageController,
          children: _widgetOptions,
          onPageChanged: (index) {},
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorButton,
        shape: CircleBorder(),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => QRScan(),
            ),
          );
        },
        child: const Icon(
          Icons.qr_code_scanner,
          color: Color(0xfff6f9ff),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 60,
        color: backgroundTextColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.home,
                color: Color(0xff717ff5),
              ),
              onPressed: () {
                _onItemTapped(0);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.event,
                color: Color(0xff717ff5),
              ),
              onPressed: () {
                _onItemTapped(1);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.history,
                color: Color(0xff717ff5),
              ),
              onPressed: () {
                _onItemTapped(2);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.person,
                color: Color(0xff717ff5),
              ),
              onPressed: () {
                _onItemTapped(3);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({Key? key}) : super(key: key);

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  int _accumulatedMerit = 0;
  List<FlSpot> _chartData = [];
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMeritData();
  }

  Future<void> _fetchMeritData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final userEmail = user.email;
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      return;
    }

    final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
    final matricNumber = userData['matricNumber'] as String;

    final activityLogs =
        await FirebaseFirestore.instance.collection('activitylog').get();

    int totalMerit = 0;
    List<FlSpot> chartData = [];
    Map<DateTime, int> meritByMonth = {};

    for (var log in activityLogs.docs) {
      final scannedUserDoc =
          await log.reference.collection('scannedUser').doc(matricNumber).get();

      if (scannedUserDoc.exists) {
        final eventRef = log['eventId'] as DocumentReference;
        final eventSnapshot = await eventRef.get();
        if (eventSnapshot.exists) {
          final eventData = eventSnapshot.data() as Map<String, dynamic>;
          final eventMerit = eventData['merit'] is String
              ? int.tryParse(eventData['merit']) ?? 1
              : eventData['merit'] as int;
          totalMerit += eventMerit;

          final eventDate = DateTime.parse(eventData['date']);
          final eventMonth = DateTime(eventDate.year, eventDate.month);

          if (!meritByMonth.containsKey(eventMonth)) {
            meritByMonth[eventMonth] = 0;
          }
          meritByMonth[eventMonth] = meritByMonth[eventMonth]! + eventMerit;
        }
      }
    }

    int cumulativeMerit = 0;
    for (var entry in meritByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      cumulativeMerit = entry.value; // Only use the merit points for the month
      chartData
          .add(FlSpot(entry.key.month.toDouble(), cumulativeMerit.toDouble()));
    }

    setState(() {
      _accumulatedMerit = totalMerit;
      _chartData = chartData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Activ-Merit',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            // Merit Accumulation
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      'MERIT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '$_accumulatedMerit',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '*Already passed the minimum requirement for college',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Line Chart Container
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Merit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 1.50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        mainData(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MeritAnalysis(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorButton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              child: Text('Merit Analysis', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData mainData() {
    double maxYValue = (_accumulatedMerit + 10).toDouble();

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
    final month = months[(value.toInt() - 1) % 12];

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

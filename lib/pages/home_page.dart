import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<FlSpot> spots = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    try {
      CollectionReference collectionRef = firestore.collection('refills');
      QuerySnapshot querySnapshot = await collectionRef.get();
      List<FlSpot> tempSpots = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double eurPerLitre = double.tryParse(data['eurPerLitre']) ?? 0;
        String dateString = data['date'];
        DateTime date = DateFormat('dd.MM.yyyy').parse(dateString);
        double xValue = date.millisecondsSinceEpoch.toDouble();
        return FlSpot(xValue, eurPerLitre);
      }).toList();

      tempSpots.sort((a, b) => a.x.compareTo(b.x));

      setState(() {
        spots = tempSpots;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSpotInfo(FlSpot spot) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
    String formattedDate = DateFormat('dd.MM.yyyy').format(date);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Spot Information'),
          content: Text('Date: $formattedDate\nPrice: ${spot.y.toStringAsFixed(2)} EUR'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
        child: AspectRatio(
          aspectRatio: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    gradient: const LinearGradient(
                      colors: [
                        Colors.red,
                        Colors.blue,
                        Colors.green,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    barWidth: 4,
                    isCurved: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 0.1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        DateTime date =
                        DateTime.fromMillisecondsSinceEpoch(
                            value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MM/dd').format(date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                      interval: (spots.isNotEmpty)
                          ? (spots.last.x - spots.first.x) / 5
                          : 1,
                    ),
                  ),
                  topTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Price (EUR) vs Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    axisNameSize: 30,
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 0.1,
                  verticalInterval: (spots.isNotEmpty)
                      ? (spots.last.x - spots.first.x) / 5
                      : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(

                  ),
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (!event.isInterestedForInteractions || touchResponse == null || touchResponse.lineBarSpots == null) {
                      return;
                    }
                    final spot = touchResponse.lineBarSpots![0];
                    _showSpotInfo(spot);
                  },
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

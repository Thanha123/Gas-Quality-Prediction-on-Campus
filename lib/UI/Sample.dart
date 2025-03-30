import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../Bloc/Overall AQI Bloc/overall_bloc.dart';
import '../Repository/ModelClass/OverallAQiModel.dart';

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  late OverallAqiModel aqi;
  List<Map<String, dynamic>> chartData = [];
  late Timer timer;
  DateTime startTime = DateTime.now();

  // Add these new variables
  List<DateTime> availableDates = []; // To store dates from backend
  DateTime? selectedDate; // Currently selected date

  @override
  void initState() {
    super.initState();

    chartData.add({
      'time': startTime,
      'value': 0.0,
    });
    BlocProvider.of<OverallBloc>(context).add(FeatchOverall());

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      updateData();
    });
  }

  void updateData() {
    setState(() {
      chartData.add({
        'time': DateTime.now(),
        'value': (5 + (chartData.length % 4) * 5).toDouble(),
      });

      if (chartData.length > 24 * 60) {
        chartData.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  String formatTime(double value) {
    int minutes = value.toInt();
    DateTime time = DateTime(0, 0, 0, minutes ~/ 60, minutes % 60);
    return DateFormat('hh:mm a').format(time);
  }

  // New method to update chart data based on selected date
  void updateChartData(DateTime date) {
    // Here you would typically fetch data for the specific date from your backend
    // For this example, I'll just clear and add sample data
    setState(() {
      chartData.clear();
      chartData.add({
        'time': date,
        'value': 0.0,
      });
      // Add your logic to fetch and populate chartData for the selected date
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Real-Time Line Graph')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: EdgeInsets.all(8.sp),
            child: BlocBuilder<OverallBloc, OverallState>(
              builder: (context, state) {
                if (state is OverallLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (state is OverallBlocError) {
                  return const Center(
                    child: Text(
                      "Error fetching AQI data. Please try again.",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (state is OverallBlocLoaded) {
                  aqi = BlocProvider.of<OverallBloc>(context).overall;
                  // Assuming your OverallAqiModel has a way to provide available dates
                  // You'll need to modify this based on your actual data structure
                  // For example purposes, adding some sample dates
                  if (availableDates.isEmpty) {
                    availableDates = List.generate(
                      7,
                          (index) => DateTime.now().subtract(Duration(days: index)),
                    );
                    selectedDate = availableDates.first;
                  }

                  return Column(
                    children: [
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: EdgeInsets.all(8.sp),
                          child: DropdownButton<DateTime>(
                            value: selectedDate,
                            dropdownColor: Colors.grey[900],
                            style: TextStyle(color: Colors.white, fontSize: 16.sp),
                            items: availableDates.map((DateTime date) {
                              return DropdownMenuItem<DateTime>(
                                value: date,
                                child: Text(
                                  DateFormat('MMM dd, yyyy').format(date),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (DateTime? newDate) {
                              if (newDate != null) {
                                setState(() {
                                  selectedDate = newDate;
                                  updateChartData(newDate);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: 24 * 60 * 2.w,
                        height: 400.h,
                        child: LineChart(
                          LineChartData(
                            backgroundColor: Colors.black,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: 2,
                              verticalInterval: 30,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.white24,
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (value) => FlLine(
                                color: Colors.white24,
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 2,
                                  getTitlesWidget: (value, meta) {
                                    if ([2, 4, 6, 8, 10, 12, 14, 16].contains(value.toInt())) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                  reservedSize: 40.w,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 30,
                                  getTitlesWidget: (value, meta) {
                                    if (value >= 0 && value <= 24 * 60) {
                                      return Text(
                                        formatTime(value),
                                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                  reservedSize: 40.h,
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.white24),
                            ),
                            minX: 0,
                            maxX: 24 * 60.toDouble(),
                            minY: 0,
                            maxY: 16,
                            lineBarsData: [
                              LineChartBarData(
                                spots: chartData
                                    .map((e) => FlSpot(
                                  (e['time'].difference(startTime).inSeconds).toDouble(), // X-axis as time in seconds
                                  e['value'] as double, // Y-axis as AQI value
                                ))
                                    .toList(),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 3,
                                    color: Colors.red,
                                    strokeWidth: 1,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }
}
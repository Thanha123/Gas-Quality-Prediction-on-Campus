import 'dart:async';
import 'dart:math';

import 'package:airquality/Bloc/AllgasesBloc/all_gases_bloc.dart';
import 'package:airquality/Bloc/Overall%20AQI%20Bloc/overall_bloc.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vibration/vibration.dart';

import '../Repository/ModelClass/LatestPredictionModel.dart';
import '../Repository/ModelClass/OverallAQiModel.dart';
import 'ManuallyInput.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late OverallAqiModel aqi;
  String? selectedDate;
  List<FlSpot> _aqiData = [];
  late LatestPredictionModel latest;
  Timer? _timer;

  // Variables for scrolling
  double _minX = 28800; // 8 AM in seconds
  double _maxX = 72000; // 8 PM in seconds
  double _minY = 0;
  double _maxY = 15; // Fixed max Y for AQI

  // View window variables for horizontal scrolling
  double _viewMinX = 28800; // Start at 8 AM
  double _viewMaxX = 72000; // End at 8 PM
  double _viewportSize = 43200; // 12 hours viewport (8 AM to 8 PM)

  // Current time variable for centering
  double _currentTimeX = 0;

  // Add timer for real-time updates
  Timer? _updateTimer;

  // Track if we're actively panning
  bool _isPanning = false;

  // Variables for inertial scrolling
  Timer? _inertiaTimer;

  // Touch handling variables
  FlSpot? _touchedSpot;
  String _touchedLine = 'Overall_AQI'; // Only using Overall_AQI

  // Flag to refresh UI when new data arrives
  bool _needsRefresh = false;

  // Last update timestamp to track new data
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();

    // Set initial current time
    _updateCurrentTime();

    // Initial data fetch
    BlocProvider.of<OverallBloc>(context).add(FeatchOverall());
    BlocProvider.of<AllGasesBloc>(context).add(FeatchAllGases());

    // Set up a timer for frequent polls to the backend
    // Reduced from 5 seconds to 2 seconds for more frequent updates
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      // Fetch new data
      BlocProvider.of<OverallBloc>(context).add(FeatchOverall());
      BlocProvider.of<AllGasesBloc>(context).add(FeatchAllGases());

      // Update current time if not panning
      if (!_isPanning) {
        _updateCurrentTime();
      }
    });

    // Add a more frequent UI update timer separate from data fetch
    _updateTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_needsRefresh) {
        setState(() {
          _needsRefresh = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel timers when widget is disposed
    _updateTimer?.cancel();
    _inertiaTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // Update current time and center the view
  void _updateCurrentTime() {
    final now = DateTime.now();
    _currentTimeX = (now.hour * 3600 + now.minute * 60 + now.second).toDouble();

    if (!_isPanning) {
      _centerViewOnCurrentTime();
      _needsRefresh = true;
    }
  }

  // Center the view on current time
  void _centerViewOnCurrentTime() {
    final viewportHalfSize = _viewportSize / 2;

    // Calculate new viewport boundaries centered on current time
    double newMinX = _currentTimeX - viewportHalfSize;
    double newMaxX = _currentTimeX + viewportHalfSize;

    // Apply boundary constraints
    if (newMinX < 28800) {
      newMinX = 28800;
      newMaxX = 28800 + _viewportSize;
    } else if (newMaxX > 72000) {
      newMaxX = 72000;
      newMinX = newMaxX - _viewportSize;
    }

    // Update viewport
    _viewMinX = newMinX;
    _viewMaxX = newMaxX;

    // Apply to chart view
    _minX = _viewMinX;
    _maxX = _viewMaxX;
  }

  // Add this function to your _HomeState class to check threshold and show alert
  void _checkAqiThreshold(double aqiValue) {
    // Define AQI thresholds and their corresponding alert messages
    final Map<double, Map<String, dynamic>> thresholds = {
      50: {
        'message': 'AQI has reached Moderate ',
        'color': Colors.red,
        'vibrationPattern': [500, 200, 500, 200, 500]
      },
      100: {
        'message': 'AQI has reached Unhealthy for Sensitive Groups',
        'color': Colors.red,
        'vibrationPattern': [500, 200, 500, 200, 500]
      },
      150: {
        'message': 'AQI has reached Unhealthy',
        'color': Colors.red,
        'vibrationPattern': [500, 200, 500, 200, 500]
      },
      200: {
        'message': 'AQI has reached Very Unhealthy',
        'color': Colors.red,
        'vibrationPattern': [500, 200, 500, 200, 500]
      },
      250: {
        'message': 'AQI has reached Hazardous',
        'color': Colors.red,
        'vibrationPattern': [500, 200, 500, 200, 500]
      }
    };

    // Find the highest threshold that the AQI has crossed
    double? triggeredThreshold;
    for (var threshold in thresholds.keys) {
      if (aqiValue >= threshold) {
        triggeredThreshold = threshold;
      }
    }

    // If a threshold is triggered, show alert and vibrate
    if (triggeredThreshold != null) {
      final alertInfo = thresholds[triggeredThreshold]!;

      // Vibrate the phone with the defined pattern
      if (Vibration.hasVibrator() != null) {
        Vibration.vibrate(pattern: alertInfo['vibrationPattern']);
      }

      // Show the alert dialog
      if (!_isAlertShowing) {
        _isAlertShowing = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('AQI Alert'),
              backgroundColor: alertInfo['color'].withOpacity(0.9),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 48, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    alertInfo['message'],
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please take necessary precautions.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Acknowledge', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _isAlertShowing = false;
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

// Add this variable to track if an alert is already showing
  bool _isAlertShowing = false;












  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SizedBox(
        width: 120.w, // Custom width
        height: 40.h, // Custom height
        child: ElevatedButton(
          onPressed: () {
Navigator.of(context).push(MaterialPageRoute(builder: (_)=>ManualAqiPage()));
},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 6, // Similar to FAB elevation
          ),
          child: Text(
            'Push', // Custom text
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),


      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black,
        title: Text('Air Quality Graph',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        actions: [
          // Add refresh button for manual updates
          IconButton(
            icon: Icon(Icons.refresh,color: Colors.white,),
            onPressed: () {
              BlocProvider.of<OverallBloc>(context).add(FeatchOverall());
              BlocProvider.of<AllGasesBloc>(context).add(FeatchAllGases());
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Refreshing data...'), duration: Duration(seconds: 1))
              );
            },
          ),
        ],
      ),
      body: BlocListener<OverallBloc, OverallState>(
        listener: (context, state) {
          if (state is OverallBlocLoaded) {
            // When new data is loaded, update the graph data
            _processNewData(state);
          }
        },
        child: BlocBuilder<OverallBloc, OverallState>(
          builder: (context, state) {
            if (state is OverallLoading && _aqiData.isEmpty) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is OverallBlocError) {
              return Center(
                child: Text(
                  "Error fetching AQI data. Please try again.",
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            if (state is OverallBlocLoaded || _aqiData.isNotEmpty) {
              if (state is OverallBlocLoaded) {
                aqi = BlocProvider.of<OverallBloc>(context).overall;
              }

              return _buildGraphUI();
            }

            return Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  // Process new data when it arrives
  void _processNewData(OverallBlocLoaded state) {
    aqi = BlocProvider.of<OverallBloc>(context).overall;

    // If no date is selected yet, select the most recent one
    if (selectedDate == null) {
      final dates = aqi.toJson().keys.toList();
      if (dates.isNotEmpty) {
        dates.sort((a, b) => b.compareTo(a)); // Sort dates newest first
        selectedDate = dates.first;
        _updateGraphData(selectedDate!);
      }
    } else {
      // Update graph with new data for the currently selected date
      _updateGraphData(selectedDate!);
    }
    if (_aqiData.isNotEmpty) {
      final latestAqi = _aqiData.last.y;
      _checkAqiThreshold(latestAqi);
    }
    // Mark that we need to refresh the UI
    _needsRefresh = true;
    _lastUpdateTime = DateTime.now();
  }

  Widget _buildGraphUI() {
    // Get all dates from the API response
    List<String> dates = [];
    try {
      // Convert map keys to list and sort them if needed
      dates = aqi.toJson().keys.toList();

      // Sort dates in descending order (newest first)
      dates.sort((a, b) => b.compareTo(a));
    } catch (e) {
      // Handle error if aqi is not initialized yet
      dates = [];
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Dropdown to select date
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: DropdownButton<String>(
                value: selectedDate,
                hint: Text('Select a date'),
                isExpanded: true, // Make dropdown take full width
                icon: Icon(Icons.arrow_drop_down),
                underline: SizedBox(), // Remove underline
                items: dates.map((date) {
                  return DropdownMenuItem<String>(
                    value: date,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(date),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDate = value;
                      _updateGraphData(selectedDate!);
                    });
                  }
                },
              ),
            ),
          ),

          // Last update indicator
          if (_lastUpdateTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.update, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Updated at ${_lastUpdateTime!.hour.toString().padLeft(2, '0')}:${_lastUpdateTime!.minute.toString().padLeft(2, '0')}:${_lastUpdateTime!.second.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

          SizedBox(height: 8.h),

          // Graph with improved scrolling
          SizedBox(
            height: 200.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 24 * 60 * 2.w,
                height: 400.h,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 2,
                      verticalInterval: 700,
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final timeString = _convertSecondsToTimeString(value.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                timeString,
                                style: TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            );
                          },
                          interval: 1400,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value % 2 == 0 && value <= 15) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: 12, color: Colors.white),
                              );
                            }
                            return SizedBox();
                          },
                          interval: 1,
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: _buildLineBarData(),
                    minX: _minX,
                    maxX: _maxX,
                    minY: _minY,
                    maxY: _maxY,
                    clipData: FlClipData.all(),

                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                        setState(() {
                          if (touchResponse == null ||
                              touchResponse.lineBarSpots == null ||
                              touchResponse.lineBarSpots!.isEmpty) {
                            _touchedSpot = null;
                          } else {
                            _touchedSpot = touchResponse.lineBarSpots![0];
                            _touchedLine = 'Overall_AQI';
                          }
                        });
                      },
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        tooltipMargin: 8,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final time = _convertSecondsToTimeString(barSpot.x.toInt());

                            return LineTooltipItem(
                              '$time\nAQI: ${barSpot.y.toStringAsFixed(2)}',
                              TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                    ),

                    extraLinesData: ExtraLinesData(
                      verticalLines: [
                        VerticalLine(
                          x: _currentTimeX,
                          color: Colors.red,
                          strokeWidth: 2,
                          dashArray: [5, 5],
                          label: VerticalLineLabel(
                            show: true,
                            alignment: Alignment.topCenter,
                            style: TextStyle(color: Colors.red, fontSize: 10),
                            labelResolver: (line) => 'Now',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Shorten animation duration for real-time response
                  duration: Duration(milliseconds: 100),
                  curve: Curves.easeInOut,
                ),
              ),
            ),
          ),
          SizedBox(height: 30.h,),

          // Display touched value below the graph
          _touchedSpot != null
              ? Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Time: ${_convertSecondsToTimeString(_touchedSpot!.x.toInt())} | AQI: ${_touchedSpot!.y.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )
              :SizedBox(height: 20.h,),

          BlocBuilder<AllGasesBloc, AllGasesState>(
            builder: (context, state) {
              if (state is AllGasesLoading && latest == null) {
                return Center(child: CircularProgressIndicator());
              }
              if (state is AllGasesBlocError) {
                return Center(child: Text('Error loading gas data', style: TextStyle(color: Colors.red)));
              }
              if (state is AllGasesBlocLoaded || latest != null) {
                if (state is AllGasesBlocLoaded) {
                  latest = BlocProvider.of<AllGasesBloc>(context).latestPrediction;
                }

                return Column(
                  children: [
                    SizedBox(height: 30.h,),

                    _buildGasCard("CH4", latest.ch4aqi, latest.cH4Ppm, latest.cH4Category),
                    _buildGasCard("CO", latest.coaqi, latest.cOPpm, latest.cOCategory),
                    _buildGasCard("NH3", latest.nh3aqi, latest.nH3Ppm, latest.nH3Category),
                    _buildGasCard("O3", latest.o3aqi, latest.o3Ppm, latest.o3Category),
                    SizedBox(height: 100.h,),
                  ],
                );
              } else {
                return SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }

  // Build line bar data - now only showing AQI
  List<LineChartBarData> _buildLineBarData() {
    return [
      LineChartBarData(
        spots: _aqiData,
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        isStrokeCapRound: true,
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withOpacity(0.2),
        ),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            // Highlight the most recent point with a different color
            final isLatestPoint = index == _aqiData.length - 1;
            final isTouched = _touchedSpot != null &&
                _touchedSpot!.x == spot.x &&
                _touchedSpot!.y == spot.y;

            return FlDotCirclePainter(
              radius: isTouched ? 6 : (isLatestPoint ? 5 : 3),
              color: isLatestPoint ? Colors.green : Colors.blue,
              strokeWidth: isTouched ? 2.5 : 1.5,
              strokeColor: Colors.white,
            );
          },
          checkToShowDot: (spot, barData) {
            // Always show if it's the touched spot or the latest spot
            if (_touchedSpot != null &&
                _touchedSpot!.x == spot.x &&
                _touchedSpot!.y == spot.y) {
              return true;
            }

            // Get the index of the spot
            final index = _aqiData.indexOf(spot);

            // Always show the last dot (most recent reading)
            if (index == _aqiData.length - 1) return true;

            // Calculate interval based on zoom level
            final visiblePoints = (_viewMaxX - _viewMinX) / (_maxX - _minX) * _aqiData.length;
            final interval = max(1, (visiblePoints / 15).round());

            // Show dots at regular intervals
            return index % interval == 0;
          },
        ),
      ),
    ];
  }

  // Update graph data based on the selected date
  void _updateGraphData(String date) {
    final data = aqi.toJson()[date];
    if (data != null) {
      // Create a map for easy lookup and update
      Map<double, FlSpot> spotMap = {};

      // First add existing data to the map
      for (var spot in _aqiData) {
        spotMap[spot.x] = spot;
      }

      // Process new data
      for (var entry in data) {
        if (entry['time'] != null) {
          final time = entry['time'].toString();
          final timeInSeconds = _convertTimeToSeconds(time);

          if (entry.containsKey('Overall_AQI') && entry['Overall_AQI'] != null) {
            final aqiValue = double.tryParse(entry['Overall_AQI'].toString()) ?? 0.0;
            spotMap[timeInSeconds.toDouble()] = FlSpot(timeInSeconds.toDouble(), aqiValue);
          }
        }
      }

      // Convert map back to list and sort
      final newAqiData = spotMap.values.toList();
      newAqiData.sort((a, b) => a.x.compareTo(b.x));

      // Check if there are actual changes to the data
      bool hasChanges = _aqiData.length != newAqiData.length;

      if (!hasChanges && _aqiData.isNotEmpty) {
        // Check last element to see if it changed
        final oldLast = _aqiData.last;
        final newLast = newAqiData.last;

        if (oldLast.x != newLast.x || oldLast.y != newLast.y) {
          hasChanges = true;
        }
      }

      if (hasChanges) {
        setState(() {
          _aqiData = newAqiData;
          _lastUpdateTime = DateTime.now();
        });
      }
    }
  }

  // Convert time string (e.g., "12:30:24") to seconds for the X-axis
  int _convertTimeToSeconds(String time) {
    final parts = time.split(':');
    if (parts.length >= 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return hours * 3600 + minutes * 60 + seconds;
    }
    return 0;
  }

  // Convert seconds back to time string for display
  String _convertSecondsToTimeString(int seconds) {
    final hours24 = (seconds ~/ 3600) % 24;
    final minutes = (seconds % 3600) ~/ 60;

    // Convert to 12-hour format
    final hours12 = hours24 % 12 == 0 ? 12 : hours24 % 12;
    final amPm = hours24 < 12 ? 'AM' : 'PM';

    // For axis labels, only show every 3 hours with full 24-hour cycle
    if (minutes == 0) {
      // Always show 8 AM, 11 AM, 2 PM, 5 PM, 8 PM
      if (hours24 % 3 == 0) {
        return '$hours12 $amPm';
      }
      return ''; // Hide other hours
    }

    // For tooltip or detailed display, include minutes
    return '${hours12.toString()}:${minutes.toString().padLeft(2, '0')} $amPm';
  }

  Widget _buildGasCard(String gasName, dynamic aqi, dynamic ppm, dynamic category) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      color: Colors.white10,
      child: Padding(
        padding: EdgeInsets.all(12.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
                gasName,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                )
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "AQI: $aqi",
                    style: TextStyle(color: Colors.white)
                ),
                Text(
                    "PPM: $ppm",
                    style: TextStyle(color: Colors.white)
                ),
                Text(
                    "Category: $category",
                    style: TextStyle(color: Colors.white)
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
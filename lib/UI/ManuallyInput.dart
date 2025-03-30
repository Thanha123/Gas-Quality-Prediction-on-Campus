import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Bloc/GetManulAllAqi_Bloc/get_manual_aqi_bloc.dart';
import '../Bloc/ManualPost_Bloc/manual_post_bloc.dart';
import '../Repository/ModelClass/ManulGetModelClass.dart';

class ManualAqiPage extends StatefulWidget {
  const ManualAqiPage({super.key});

  @override
  State<ManualAqiPage> createState() => _ManualAqiPageState();
}

class _ManualAqiPageState extends State<ManualAqiPage> {
  final _nh3Controller = TextEditingController();
  final _coController = TextEditingController();
  final _o3Controller = TextEditingController();
  final _ch4Controller = TextEditingController();
  bool showData = false; // Flag to control when to show the DataTable

  @override
  void initState() {
    super.initState();
    // Removed initial GET request: context.read<GetManualAqiBloc>().add(FeatchGetManualAqi());
  }

  void _handleSubmit() {
    double parseInput(String text) {
      if (text.isEmpty) return 0.0;
      return double.tryParse(text) ?? 0.0;
    }

    final nh3 = parseInput(_nh3Controller.text);
    final co = parseInput(_coController.text);
    final o3 = parseInput(_o3Controller.text);
    final ch4 = parseInput(_ch4Controller.text);

    if (nh3 < 0 || co < 0 || o3 < 0 || ch4 < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All values must be non-negative')),
      );
      return;
    }

    BlocProvider.of<ManualPostBloc>(context).add(
      FeatchManualPostdata(
        nh3: nh3.toString(),
        co: co.toString(),
        o3: o3.toString(),
        ch4: ch4.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Manual AQI'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField('NH3 (ppm)', _nh3Controller),
              _buildInputField('CO (ppm)', _coController),
              _buildInputField('O3 (ppm)', _o3Controller),
              _buildInputField('CH4 (ppm)', _ch4Controller),
              SizedBox(height: 20.h),
              BlocListener<ManualPostBloc, ManualPostState>(
                listener: (context, state) {
                  if (state is ManualPostBlocLoaded) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data submitted successfully')),
                    );
                    setState(() {
                      showData = true; // Enable data display after successful POST
                    });
                    context.read<GetManualAqiBloc>().add(FeatchGetManualAqi());
                  } else if (state is ManualPostBlocError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ErrorSubmission failed')),
                    );
                  }
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              BlocBuilder<GetManualAqiBloc, GetManualAqiState>(
                builder: (context, state) {
                  if (!showData) {
                    return const SizedBox(); // Show nothing until submit is pressed
                  }
                  if (state is GetManualAqiBlocLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is GetManualAqiBlocError) {
                    return Center(
                      child: Text(
                        "Error fetching dataUnknown error",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (state is GetManualAqiBlocLoaded) {
                    final getmanual = BlocProvider.of<GetManualAqiBloc>(context).getmanual; // Access from state
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        border: TableBorder.all(color: Colors.grey),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Parameter',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Value',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                          rows: [
                      DataRow(cells: [
                      DataCell(Text('CH4 AQI', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.ch4aqi.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('CH4 Category', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.cH4Category.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('CH4 PPM', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.cH4Ppm.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('CO AQI', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.coaqi.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('CO Category', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.cOCategory.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('CO PPM', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.cOPpm.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('NH3 AQI', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.nh3aqi.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('NH3 Category', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.nH3Category.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('NH3 PPM', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.nH3Ppm.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('O3 AQI', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.o3aqi.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('O3 Category', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.o3Category.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('O3 PPM', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.o3Ppm.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('Overall AQI', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.overallAQI.toString(), style: TextStyle(color: Colors.white))),
                  ]),
                  DataRow(cells: [
                  DataCell(Text('Overall Category', style: TextStyle(color: Colors.white))),
                  DataCell(Text(getmanual.overallCategory.toString(), style: TextStyle(color: Colors.white))),
                  ]),]
                      ),
                    );
                  }
                  return const SizedBox(); // Show nothing if no data yet
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(12.r),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nh3Controller.dispose();
    _coController.dispose();
    _o3Controller.dispose();
    _ch4Controller.dispose();
    super.dispose();
  }
}
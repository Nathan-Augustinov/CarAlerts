import 'package:flutter/material.dart';

class AddNewCarScreen extends StatefulWidget {
  const AddNewCarScreen({super.key});


  @override
  State<AddNewCarScreen> createState() => _AddNewCarScreenState();
}

class _AddNewCarScreenState extends State<AddNewCarScreen>{
  final _formKey = GlobalKey<FormState>();
  String carName = '';
  bool isInsuranceSelected = false;
  bool isInspectionSelected = false;
  bool isRomanianVignetteSelected = false;
  bool isHungarianVignetteSelected = false;
  bool isAustrianVignetteSelected = false;

  DateTime? insuranceBegginingDate;
  DateTime? inspectionBegginingDate;
  DateTime? romanianVignetteBegginingDate;
  DateTime? hungarianVignetteBegginingDate;
  DateTime? austrainVignetteBegginingDate;

  DateTime? insuranceExpiringDate;
  DateTime? inspectionExpiringDate;
  DateTime? romanianVignetteExpiringDate;
  DateTime? hungarianVignetteExpiringDate;
  DateTime? austrainVignetteExpiringDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add new car"),
      ),
       body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(labelText: 'Car Name'),
              onSaved: (value) => carName = value!,
            ),
            CheckboxListTile(
              title: const Text('Car Insurance'),
              value: isInsuranceSelected,
              onChanged: (bool? value) {
                setState(() => isInsuranceSelected = value!);
              },
            ),
            if (isInsuranceSelected) _buildDateSelector('Select car insurance expiring date'),
            CheckboxListTile(
              title: const Text('Car Inspection'),
              value: isInspectionSelected,
              onChanged: (bool? value) {
                setState(() => isInspectionSelected = value!);
              },
            ),
            if (isInspectionSelected) _buildDateSelector('Select car inspection expiring date'),
            CheckboxListTile(
              title: const Text('Romanian Vignette'),
              value: isRomanianVignetteSelected,
              onChanged: (bool? value) {
                setState(() => isRomanianVignetteSelected = value!);
              },
            ),
            if (isRomanianVignetteSelected) _buildDateSelector('Select romanian vignette expiring date'),
            CheckboxListTile(
              title: const Text('Hungarian Vignette'),
              value: isHungarianVignetteSelected,
              onChanged: (bool? value) {
                setState(() => isHungarianVignetteSelected = value!);
              },
            ),
            if (isHungarianVignetteSelected) _buildDateSelector('Select hungarian vignette expiring date'),
            CheckboxListTile(
              title: const Text('Austrian Vignette'),
              value: isAustrianVignetteSelected,
              onChanged: (bool? value) {
                setState(() => isAustrianVignetteSelected = value!);
              },
            ),
            if (isAustrianVignetteSelected) _buildDateSelector('Select austrian vignette expiring date'),
            ElevatedButton(
              child: const Text('Save Car'),
              onPressed: () {
                // Implement save logic
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label) {
    return ListTile(
      title: Text(label),
      subtitle: Text(insuranceExpiringDate?.toString() ?? 'No date chosen'),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2021),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => insuranceExpiringDate = picked);
      },
    );
  }

}
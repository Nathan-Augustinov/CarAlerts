import 'dart:async';
import 'package:car_alerts/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


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

  DateTime? insuranceExpiringDate;
  DateTime? inspectionExpiringDate;
  DateTime? romanianVignetteExpiringDate;
  DateTime? hungarianVignetteExpiringDate;
  DateTime? austrianVignetteExpiringDate;

  final String errorText = "Error";
  final String successText = "Success";
  // static final String? databaseURL = dotenv.env['FIREBASE_DATABASE_URL'];
  // final DatabaseReference databaseReference = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: databaseURL).ref();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add new car"),
        actions: <Widget>[
          IconButton(
            onPressed: (){
              Navigator.pop(context);
            }, 
            icon: const Icon(Icons.close),
            tooltip: "Exit",
          )
        ],
      ),
       body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Car Name - Car Identification Number', 
                suffixIcon: IconButton(onPressed: _showInfoPopUp, icon: const Icon(Icons.info_outline),)),
              onSaved: (value) => carName = value!,
            ),
            CheckboxListTile(
              title: const Text('Car Insurance'),
              value: isInsuranceSelected,
              onChanged: (bool? value) {
                setState(() => isInsuranceSelected = value!);
              },
            ),
            if (isInsuranceSelected) _buildDateSelector('Select car insurance expiring date', insuranceExpiringDate, (pickedDate) => setState(() => insuranceExpiringDate = pickedDate)),
            CheckboxListTile(
              title: const Text('Car Inspection'),
              value: isInspectionSelected,
              onChanged: (bool? value) {
                setState(() => isInspectionSelected = value!);
              },
            ),
            if (isInspectionSelected) _buildDateSelector('Select car inspection expiring date', inspectionExpiringDate, (pickedDate) => setState(() => inspectionExpiringDate = pickedDate)),
            CheckboxListTile(
              title: const Text('Romanian Vignette'),
              value: isRomanianVignetteSelected,
              onChanged: (bool? value) {
                setState(() => isRomanianVignetteSelected = value!);
              },
            ),
            if (isRomanianVignetteSelected) _buildDateSelector('Select romanian vignette expiring date', romanianVignetteExpiringDate, (pickedDate) => setState(() => romanianVignetteExpiringDate = pickedDate)),
            CheckboxListTile(
              title: const Text('Hungarian Vignette'),
              value: isHungarianVignetteSelected,
              onChanged: (bool? value) {
                setState(() => isHungarianVignetteSelected = value!);
              },
            ),
            if (isHungarianVignetteSelected) _buildDateSelector('Select hungarian vignette expiring date', hungarianVignetteExpiringDate, (pickedDate) => setState(() => hungarianVignetteExpiringDate = pickedDate)),
            CheckboxListTile(
              title: const Text('Austrian Vignette'),
              value: isAustrianVignetteSelected,
              onChanged: (bool? value) {
                setState(() => isAustrianVignetteSelected = value!);
              },
            ),
            if (isAustrianVignetteSelected) _buildDateSelector('Select austrian vignette expiring date', austrianVignetteExpiringDate, (pickedDate) => setState(() => austrianVignetteExpiringDate = pickedDate)),
            ElevatedButton(
              child: const Text('Save Car'),
              onPressed: () {
                // Implement save logic
                _saveCar();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? itemExpiringDate, Function(DateTime) onDateSelected) {
    return ListTile(
      title: Text(label),
      subtitle: Text(itemExpiringDate?.toString() ?? 'No date chosen'),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2021),
          lastDate: DateTime(2030),
        );
        if (picked != null) onDateSelected(picked);
      },
    );
  }

  Future<void> _saveCar() async {
    if(_formKey.currentState!.validate()){
      _formKey.currentState!.save();

      if(carName.isEmpty){
        _showErrorPopUp("Please enter the car name!", errorText);
        return;
      }

      bool nameUsed = await _carNameAlreadyUsed(carName);
      if(nameUsed){
        _showErrorPopUp("You already have a car with this name or identification number saved!", errorText);
        return; 
      }

      if(isInsuranceSelected && insuranceExpiringDate == null){
        _showErrorPopUp("Please select the insurance expiration date!", errorText);
        return;
      }
      if(isInspectionSelected && inspectionExpiringDate == null){
        _showErrorPopUp("Please select the inspection expiration date!", errorText);
        return;
      }
      if(isRomanianVignetteSelected && romanianVignetteExpiringDate == null){
        _showErrorPopUp("Please select the romanian vignette expiration date!", errorText);
        return;
      }
      if(isHungarianVignetteSelected && hungarianVignetteExpiringDate == null){
        _showErrorPopUp("Please select the hungarian vignette expiration date!", errorText);
        return;
      }
      if(isAustrianVignetteSelected && austrianVignetteExpiringDate == null){
        _showErrorPopUp("Please select the austrian vignette expiration date!", errorText);
        return;
      }
      _addCarToDatabase();
    }
  }

  void _addCarToDatabase(){

    Map<String, dynamic> carData = {
      'insurance_date' : isInsuranceSelected ? insuranceExpiringDate?.toIso8601String() : null,
      'inspection_date' : isInspectionSelected ? inspectionExpiringDate?.toIso8601String() : null,
      'romanian_vignette_date' : isRomanianVignetteSelected ? romanianVignetteExpiringDate?.toIso8601String() : null,
      'hungarian_vignette_date' : isHungarianVignetteSelected ? hungarianVignetteExpiringDate?.toIso8601String() : null,
      'austrian_vignette_date' : isAustrianVignetteSelected ? austrianVignetteExpiringDate?.toIso8601String() : null,
    };

    FirebaseFirestore.instance.collection('cars').doc(currentUserId).collection('user_cars').doc(carName).set(carData).then((_){
       _showErrorPopUp("Car successfully added!", successText);
    }).catchError((error){
       _showErrorPopUp("Error at adding the car into the database!", errorText);
    });
  }

  void _showErrorPopUp(String errorMessage, String titleMesssage){
    showDialog(
      context: context, 
      builder: (BuildContext context){
        return AlertDialog(
          title: Text(titleMesssage),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
                if(titleMesssage == successText){
                  Navigator.of(context).pop();
                  mainScreenKey.currentState?.selectTab(1);
                }
              }, 
              child: const Text('OK'))
          ],
        );
      }
    );
  }

  void _showInfoPopUp(){
    showDialog(
      context: context, 
      builder: (BuildContext context){
        return AlertDialog(
          title: const Text("Car Name - Car Identification Number"),
          content: const Text("Please enter the car name and the car identification number. You can either use the car name, the car identification number or both to identify the car.\nIf you use only the car name, please use the following format: Golf or, if the car name has more than one word, GolfGTI.\nIf you use only the car identification number, please save it in the following format: AR00XYZ.\nIn case you use both, please save them in the following format: Golf - AR00XYZ, or if the car name has more than one word: GolfGTI - AR00XYZ."),
          actions: <Widget>[
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
              }, 
              child: const Text('OK'))
          ],
        );
      }
    );
  }

  Future<bool> _carNameAlreadyUsed(String carName) async {
    bool result = false;
    try{
      await FirebaseFirestore.instance.collection('cars').doc(currentUserId).collection('user_cars').doc(carName).get().then((value) {
        getCarIdFromName(carName);
        if(value.exists || getCarIdFromName(carName) == getCarIdFromName(value.id)){
          result = true;
        }
      });

      // if(event.snapshot.exists){
      //   result = true;
      // }
    } catch(error){
      _showErrorPopUp("Error in querying the database: $error", errorText);
    }
      return result;
  }

  String getCarIdFromName(String carName){
    return carName.split(" ").elementAt(2);
  }

}
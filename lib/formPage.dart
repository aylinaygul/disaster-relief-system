import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final TextEditingController _nameController = TextEditingController();
final TextEditingController _surnameController = TextEditingController();
final TextEditingController _addressController = TextEditingController();
final TextEditingController _phoneController = TextEditingController();
final TextEditingController _emailController = TextEditingController();
final TextEditingController _additionalInfoController = TextEditingController();

const List<String> list = <String>[
  'Ulaşım imkanım yok.',
  'Su/yiyecek erişimim yok.',
  'Kıyafet ihtiyacım var.',
  'Sığınma alanı sorunları'
];

class FormPage extends StatefulWidget {
  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  String dropdownValue = list.first;

  void showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Request received.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                clearForm(); // Clear the form fields
              },
            ),
          ],
        );
      },
    );
  }

  void clearForm() {
    _nameController.clear();
    _surnameController.clear();
    _addressController.clear();
    _phoneController.clear();
    _emailController.clear();
    _additionalInfoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                'Surname',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              TextFormField(
                controller: _surnameController,
                decoration: InputDecoration(
                  hintText: 'Enter your surname',
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                'Address',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Enter your address',
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                'Phone',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'Enter your phone number',
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                'Request Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                ),
                child: DropdownButton<String>(
                  value: dropdownValue,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                  ),
                  underline: Container(),
                  onChanged: (String? value) {
                    setState(() {
                      dropdownValue = value!;
                    });
                  },
                  items: list.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                'Additional Info',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              TextFormField(
                controller: _additionalInfoController,
                decoration: InputDecoration(
                  hintText: 'Enter additional information',
                ),
              ),
              SizedBox(height: 20.0),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    // Perform form submission logic
                    FirebaseFirestore.instance.collection('requests').add({
                      'name': _nameController.text,
                      'surname': _surnameController.text,
                      'address': _addressController.text,
                      'phone': _phoneController.text,
                      'email': _emailController.text,
                      'requestType': dropdownValue,
                      'additionalInfo': _additionalInfoController.text,
                    }).then((_) {
                      showConfirmationDialog(); // Show success dialog
                    }).catchError((error) {});
                  },
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

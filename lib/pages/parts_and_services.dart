import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartsAndService extends StatefulWidget {
  const PartsAndService({Key? key}) : super(key: key);

  @override
  State<PartsAndService> createState() => _PartsAndServiceState();
}

class PartsAndServiceData {
  String date;
  String description;
  String price;

  PartsAndServiceData({
    required this.date,
    required this.description,
    required this.price,
  });
}

class _PartsAndServiceState extends State<PartsAndService> {
  List<PartsAndServiceData> partsAndServiceList = [];

  TextEditingController dateController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: const Text('Parts and Service'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: firestore.collection('services').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  partsAndServiceList = snapshot.data!.docs.map((doc) {
                    return PartsAndServiceData(
                      date: doc['date'],
                      description: doc['description'],
                      price: doc['price'],
                    );
                  }).toList();


                  partsAndServiceList.sort((a, b) => _compareDates(a.date, b.date));

                  return ListView.builder(
                    itemCount: partsAndServiceList.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onLongPress: () {
                          _showDeleteConfirmationDialog(partsAndServiceList[index]);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red[700]!),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            title: Text("Service ${partsAndServiceList[index].date}"),
                            onTap: () {
                              _showDetailDialog(partsAndServiceList[index]);
                            },
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text("Add a service"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Service"),
                    content: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Form(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: dateController,
                                decoration: const InputDecoration(
                                  labelText: "Date",
                                  icon: Icon(Icons.calendar_month),
                                ),
                              ),
                              TextFormField(
                                controller: descriptionController,
                                decoration: const InputDecoration(
                                  labelText: "Description",
                                  icon: Icon(Icons.description),
                                ),
                              ),
                              TextFormField(
                                controller: priceController,
                                decoration: const InputDecoration(
                                  labelText: "Price (eur)",
                                  icon: Icon(Icons.attach_money),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                        ),
                        child: const Text("Submit"),
                        onPressed: () {
                          Navigator.pop(context);
                          _addServiceToFirestore();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _addServiceToFirestore() async {
    try {
      await firestore.collection('services').add({
        'date': dateController.text,
        'description': descriptionController.text,
        'price': priceController.text,
      });

      dateController.clear();
      descriptionController.clear();
      priceController.clear();
    } catch (e) {
      print("Error adding service to Firestore: $e");
    }
  }

  void _showDetailDialog(PartsAndServiceData service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Service Detail"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date: ${service.date}"),
                Text("Description: ${service.description}"),
                Text("Price: ${service.price}"),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(PartsAndServiceData service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: Text("Are you sure you want to delete Service ${service.date}?"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the confirmation dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the confirmation dialog
                _deleteServiceFromFirestore(service);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _deleteServiceFromFirestore(PartsAndServiceData service) async {
    try {
      // Find the document reference based on the date (assuming date is unique)
      QuerySnapshot querySnapshot = await firestore
          .collection('services')
          .where('date', isEqualTo: service.date)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await firestore.collection('services').doc(querySnapshot.docs.first.id).delete();
      }
    } catch (e) {
      print("Error deleting service from Firestore: $e");
    }
  }

  int _compareDates(String date1, String date2) {
    List<String> parts1 = date1.split('.');
    List<String> parts2 = date2.split('.');

    DateTime dateTime1 = DateTime(
      int.parse(parts1[2]),
      int.parse(parts1[1]),
      int.parse(parts1[0]),
    );

    DateTime dateTime2 = DateTime(
      int.parse(parts2[2]),
      int.parse(parts2[1]),
      int.parse(parts2[0]),
    );

    return dateTime1.compareTo(dateTime2);
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Refill extends StatefulWidget {
  const Refill({Key? key}) : super(key: key);

  @override
  State<Refill> createState() => _RefillState();
}

class RefillData {
  String quantity;
  String price;
  String eurPerLitre;
  String date;

  RefillData({
    required this.quantity,
    required this.price,
    required this.eurPerLitre,
    required this.date,
  });
}

class _RefillState extends State<Refill> {
  List<RefillData> refillList = [];

  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController eurPerLitreController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  FirebaseFirestore firestore = FirebaseFirestore.instance;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: const Text('Refill'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: firestore.collection('refills').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  refillList = snapshot.data!.docs.map((doc) {
                    return RefillData(
                      quantity: doc['quantity'],
                      price: doc['price'],
                      eurPerLitre: doc['eurPerLitre'],
                      date: doc['date'],
                    );
                  }).toList();

                  // Sort the list based on date in ascending order (oldest to newest)
                  refillList.sort((a, b) => _compareDates(a.date, b.date));

                  return ListView.builder(
                    itemCount: refillList.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onLongPress: () {
                          _showDeleteConfirmationDialog(refillList[index]);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red[700]!),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            title: Text("Refill ${refillList[index].date}"),
                            onTap: () {
                              _showDetailDialog(refillList[index]);
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
            child: const Text("Add a refill"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Refill"),
                    content: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Form(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: quantityController,
                                decoration: const InputDecoration(
                                  labelText: "Quantity (litres)",
                                  icon: Icon(Icons.local_gas_station),
                                ),
                              ),
                              TextFormField(
                                controller: priceController,
                                decoration: const InputDecoration(
                                  labelText: "Price (eur)",
                                  icon: Icon(Icons.attach_money),
                                ),
                              ),
                              TextFormField(
                                controller: eurPerLitreController,
                                decoration: const InputDecoration(
                                  labelText: "Eur per litre",
                                  icon: Icon(Icons.water_drop),
                                ),
                              ),
                              TextFormField(
                                controller: dateController,
                                decoration: const InputDecoration(
                                  labelText: "Date",
                                  icon: Icon(Icons.calendar_month),
                                ),
                              )
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
                          _addRefillToFirestore();
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

  void _addRefillToFirestore() async {
    try {
      await firestore.collection('refills').add({
        'quantity': quantityController.text,
        'price': priceController.text,
        'eurPerLitre': eurPerLitreController.text,
        'date': dateController.text,
      });

      quantityController.clear();
      priceController.clear();
      eurPerLitreController.clear();
      dateController.clear();
    } catch (e) {
      print("Error adding refill to Firestore: $e");
    }
  }

  void _showDetailDialog(RefillData refill) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Refill Detail"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Quantity (litres): ${refill.quantity}"),
                Text("Price (eur): ${refill.price}"),
                Text("Eur per litre: ${refill.eurPerLitre}"),
                Text("Date: ${refill.date}"),
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

  void _showDeleteConfirmationDialog(RefillData refill) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: Text("Are you sure you want to delete Refill ${refill.date}?"),
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
                _deleteRefillFromFirestore(refill);
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

  void _deleteRefillFromFirestore(RefillData refill) async {
    try {

      QuerySnapshot querySnapshot = await firestore
          .collection('refills')
          .where('date', isEqualTo: refill.date)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await firestore.collection('refills').doc(querySnapshot.docs.first.id).delete();
      }
    } catch (e) {
      print("Error deleting refill from Firestore: $e");
    }
  }
}

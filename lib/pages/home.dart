import 'package:car_notes/pages/parts_and_services.dart';
import 'package:car_notes/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:car_notes/pages/refill.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List pages = [
    HomePage(),
    Refill(),
    PartsAndService()
  ];

  int currentIndex = 0;
  void onTap(int index){
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.red[700],
          currentIndex: currentIndex,
          onTap: onTap,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade500,
          items: [
            BottomNavigationBarItem(
                label: 'Home',
                icon: Icon(Icons.home_outlined)
            ),
            BottomNavigationBarItem(
                label: 'Refill',
                icon: Icon(Icons.attach_money)
            ),
            BottomNavigationBarItem(
                label: 'Parts and service',
                icon: Icon(Icons.shopping_cart_outlined)
            )
          ]
      ),
    );
  }
}

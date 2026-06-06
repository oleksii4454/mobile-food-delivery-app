import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String serverResponse = "Press to receive data from the server";

  Future<void> fetchOrderData() async {
    final url = Uri.parse('http://localhost:3000/api/orders'); 
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      setState(() {
        serverResponse = "${data['message']}\nStatus: ${data['db_status']}";
      });
    } catch (e) {
      setState(() {
        serverResponse = "Connection error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter + Node.js Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(serverResponse, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchOrderData,
              child: const Text('Request data'),
            ),
          ],
        ),
      ),
    );
  }
}
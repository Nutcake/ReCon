import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts+"),
      ),
      body: FutureBuilder(
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemBuilder: (context, index) {

                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(64),
                child: Text(
                  "Something went wrong: ${snapshot.error}",
                  softWrap: true,
                  style: Theme
                      .of(context)
                      .textTheme
                      .labelMedium,
                ),
              ),
              );
            } else {
              return const LinearProgressIndicator();
            }
          }
      ),
    );
  }
}
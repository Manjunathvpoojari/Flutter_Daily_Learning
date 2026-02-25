import 'package:first_app/auth/login.dart';
import 'package:first_app/model/counter_model.dart';
import 'package:first_app/screens/grid_example.dart';
import 'package:flutter/material.dart';
import 'package:first_app/screens/rest_api.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final String username;

  void showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Log Out!"),
        content: Text("Hi $username, Do you want to log out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  const HomePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    List<String> names = [
      "Alice",
      "Bob",
      "Charlie",
      "David",
      "Eve",
      "Frank",
      "Grace",
      "Heidi",
      "Ivan",
      "Judy",
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Home Page")),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final Counter = Provider.of<CounterModel>(context, listen: false);
          Counter.increment();
        },
        child: Icon(Icons.add),
      ),

      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer<CounterModel>(
                builder: (context, counterModel, child) {
                  return Text(
                    "Counter Value: ${counterModel.counter}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  );
                },
              ),

              Text(
                "Welcome $username to the Home Page!",
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => showAlert(context),
                child: Text('Log out'),
              ),

              SizedBox(height: 20),

              // basic list view
              Text(
                "Here is a simple list of items:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              ListTile(title: Text("item 1"), subtitle: Text("This is item 1")),
              ListTile(title: Text("item 2"), subtitle: Text("This is item 2")),
              ListTile(
                title: Text("item 3"),
                subtitle: Text("This is item  3"),
              ),

              SizedBox(height: 20),

              // Dynamic list view
              Text(
                "Here is a dynamic list of items:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                itemCount: names.length,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.person),
                    title: Text(names[index]),
                  );
                },
              ),
              SizedBox(height: 10),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GridPage()),
                  );
                },
                child: Text('Grid View Example'),
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RestApiPage()),
                  );
                },
                child: Text("Open REST API Page"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

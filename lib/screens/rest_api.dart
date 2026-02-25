import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RestApiPage extends StatefulWidget {
  @override
  _RestApiPageState createState() => _RestApiPageState();
}

class _RestApiPageState extends State<RestApiPage> {
  Map user = {};
  bool isLoading = false;

  String setup = "";
  String punchline = "";
  bool isJokeLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  // ================= USER API =================
  Future<void> fetchUser() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse('https://randomuser.me/api/'));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        setState(() {
          user = data['results'][0];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print(e);
    }
  }

  // ================= JOKE API =================
  Future<void> fetchJoke() async {
    setState(() => isJokeLoading = true);

    final response = await http.get(
      Uri.parse('https://official-joke-api.appspot.com/random_joke'),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      setState(() {
        setup = data['setup'];
        punchline = data['punchline'];
        isJokeLoading = false;
      });
    } else {
      setState(() => isJokeLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Random User + Joke")),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : user.isEmpty
            ? Text("No user data")
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 90,
                      backgroundImage: NetworkImage(user['picture']['large']),
                    ),
                    SizedBox(height: 20),

                    Text(
                      "${user['name']['title']} ${user['name']['first']} ${user['name']['last']}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),
                    Text(user['email']),
                    Text(user['phone']),

                    SizedBox(height: 10),
                    Text(
                      "${user['location']['city']}, ${user['location']['country']}",
                    ),

                    SizedBox(height: 30),

                    // 🔹 JOKE SECTION
                    Text(
                      "Random Joke",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    isJokeLoading
                        ? CircularProgressIndicator()
                        : Column(
                            children: [
                              Text(setup, textAlign: TextAlign.center),
                              SizedBox(height: 5),
                              Text(
                                punchline,
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                    SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: fetchJoke,
                      child: Text("Get Joke"),
                    ),
                  ],
                ),
              ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: fetchUser,
        child: Icon(Icons.refresh),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/auth/register.dart';
import 'package:first_app/screens/home_page.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formkey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // ignore: non_constant_identifier_names
  late AnimationController _Controller;
  late Animation<double> _fadeanimation;
  late Animation<double> _scaleanimation;
  late Animation<Offset> _slideanimation;

  @override
  void initState() {
    super.initState();
    _Controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _fadeanimation = Tween<double>(begin: 0, end: 1).animate(_Controller);
    _scaleanimation = Tween<double>(begin: 0, end: 1).animate(_Controller);
    _slideanimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(_Controller);
    _Controller.forward();
  }

  bool _isPasswordVisible = true;
  String message = "";

  Future<void> login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      String username = userDoc['username'] ?? "User";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(username: username)),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        message = e.message ?? "An error occurred during login";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellowAccent,
      appBar: AppBar(
        title: Text("Login Page"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: FadeTransition(
        opacity: _fadeanimation,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SlideTransition(
                    position: _slideanimation,
                    child: Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 95, 2, 102),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Enter Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }
                      if (!RegExp(
                        r'^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]+$',
                      ).hasMatch(value)) {
                        return "Please enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  // TextFormField(
                  //   controller: _emailController,
                  //   decoration: InputDecoration(
                  //     labelText: "Enter Email",
                  //     border: OutlineInputBorder(),
                  //     prefixIcon: Icon(Icons.email),
                  //   ),
                  //   validator: (value) {
                  //     if (value == null || value.isEmpty) {
                  //       return "Please enter your email";
                  //     }
                  //     if (!RegExp(r'^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]+$').hasMatch(value)) {
                  //       return "Please enter a valid email address";
                  //     }
                  //     return null;
                  //   },
                  // ),
                  // SizedBox(height: 30),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Enter Password",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password/ Password cannot be empty";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters long";
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return "Password must contain at least one uppercase letter";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        },
                        child: Text("Register"),
                      ),
                    ],
                  ),

                  ScaleTransition(
                    scale: _scaleanimation,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formkey.currentState!.validate()) {
                          login();
                        }
                      },
                      child: Text("Login"),
                    ),
                  ),

                  Text(
                    message,
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

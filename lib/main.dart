import 'package:firebase_core/firebase_core.dart';
import 'package:first_app/model/counter_model.dart';
import 'package:first_app/screens/intro_video_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'sb_publishable_gJJrwVBc5l9GW7hN8rFN7w_kaFqNJlw',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplYmVpbXB2aGNrYnlsaXB4aWF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyMzYxNTAsImV4cCI6MjA4OTgxMjE1MH0.B2tlP5L2FtJVo7qGfUbcDnyNOOL2Vnrw3wqClKvQ_PM',
  );

  runApp(
    ChangeNotifierProvider(create: (context) => CounterModel(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntroVideoScreen(),
    );
  }
}

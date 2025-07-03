import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCfppfpgtw3zG_ueshLFkecChTpqZTRCos",
      authDomain: "siasu-223bb.firebaseapp.com",
      projectId: "siasu-223bb",
      storageBucket: "siasu-223bb.firebasestorage.app",
      messagingSenderId: "533072990076",
      appId: "1:533072990076:web:845172bed03cc7e8759ef9",
      measurementId: "G-1DZFV1CT80",  // optional, you can leave this out
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Login Screen'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'LOGIN',
              style: TextStyle(
                fontSize: 35,
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Form(
                child: Column(
                  children: [
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'email',
                          hintText: 'Enter Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder()
                        ),
                        onChanged: (String value){
                                      
                        },
                        validator: (value) {
                          return value!.isEmpty ? 'Please Enter Email' : null;
                        },
                      ),
                    ),

                    SizedBox(height: 20,),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter Password',
                          prefixIcon: Icon(Icons.password),
                          border: OutlineInputBorder()
                        ),
                        onChanged: (String value){
                                      
                        },
                        validator: (value) {
                          return value!.isEmpty ? 'Please Enter Password' : null;
                        },
                      ),
                    ),

                    SizedBox( height: 30,),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: MaterialButton(
                        minWidth: double.infinity,
                        onPressed: () {},
                        child: Text('Login'),
                        color: Colors.grey,
                        textColor: Colors.white,
                      ),
                    )
                  ],
                )),
              )
          ], 
        ),
      )
    );
  }
}
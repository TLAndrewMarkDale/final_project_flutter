import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Classification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', // Set Roboto as the default font
        scaffoldBackgroundColor: const Color.fromRGBO(228, 241, 238, 1), // Background color
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.white, // Dialog background color
          titleTextStyle: TextStyle(
            color: Color.fromRGBO(255, 128, 128, 1), // Dialog title text color
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: TextStyle(
            color: Colors.black, // Dialog content text color
            fontSize: 16.0,
          ),
        ),
      ),
      home: ImageClassificationScreen(),
    );
  }
}

class ImageClassificationScreen extends StatefulWidget {
  @override
  _ImageClassificationScreenState createState() =>
      _ImageClassificationScreenState();
}

class _ImageClassificationScreenState extends State<ImageClassificationScreen> {
  File? _image;
  String _classificationResult = '';
  final picker = ImagePicker();

  Future getImageAndNavigate() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageDisplayScreen(imageFile: File(pickedFile.path)),
        ),
      );
    }
  }

  void showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Information'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Take a picture of a mole, or a skin lesion of concern. Ensure it is a skin lesion, as our model is designed to classify lesions only. Always consult with your physician if you are concerned.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color.fromRGBO(255, 128, 128, 1), // Appbar color
          title: Center(
            child: Container(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    //margin: EdgeInsets.only(top: 10), // Lower image by 10 pixels
                    width: size.width * 0.125,
                    height: size.width * 0.125,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/Skincancer1.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'LesionCheckr',
                    style: TextStyle(
                      fontSize: size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: GestureDetector(
              onTap: getImageAndNavigate,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(255, 111, 78, 1),
                      Color.fromRGBO(255, 128, 128, 1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Take Picture',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: size.width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => showInfoDialog(context),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(255, 128, 128, 1), // Circle color
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white, // Icon color
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageDisplayScreen extends StatefulWidget {
  final File imageFile;

  const ImageDisplayScreen({required this.imageFile});

  @override
  _ImageDisplayScreenState createState() => _ImageDisplayScreenState();
}

class _ImageDisplayScreenState extends State<ImageDisplayScreen> {
  String _classificationResult = ''; // Declare classification result variable

  Future<void> classifyImage() async {
    // Convert the image to base64
    List<int> imageBytes = await widget.imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    
    // Send the image to the backend
    try {
      print('Sending image to the server...');
    final response = await http.post(
      Uri.parse('https://final-project-backend-group7-a195d5bde686.herokuapp.com/classify'), // Update the URL accordingly
      body: jsonEncode({'image': base64Image}),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json'},

    );
    print(response.body);
    // Check if the request was successful
    if (response.statusCode == 200) {
      // Parse the response JSON
      Map<String, dynamic> data = jsonDecode(response.body);

      // Update the classification result using setState
      setState(() {
        _classificationResult = data['result'];
      });
    } else {
      // Handle errors
      print('Failed to classify image: ${response.statusCode}');
    }
    } catch (e) {
      print('Failed to connect to the server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(255, 128, 128, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Lesion'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _classificationResult == "" ? "" : "Classification:\n $_classificationResult",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: _classificationResult == "Melanocytic Nevi" ? const Color.fromRGBO(255, 128, 128, 1) : const Color.fromRGBO(243, 32, 32, 1) ,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: _classificationResult == "" ? size.width * 0.6 : size.width * 0.5,
              height: _classificationResult == "" ? size.height * 0.5 : size.height * 0.4,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(widget.imageFile),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton( 
              onPressed: classifyImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(255, 128, 128, 1),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ), 
              child: const Wrap(
                children: <Widget>[
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Classify',
                    style: TextStyle(
                    color: Colors.white,
              ),),
          ])),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

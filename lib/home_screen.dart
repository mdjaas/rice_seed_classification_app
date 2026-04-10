import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final ValueChanged<File?> onImagePicked;
  final title;

  const HomeScreen({Key? key, required this.onImagePicked, required this.title}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  Uint8List? _resultImage;
  bool _isLoading = false;
  String? _errorMessage;

  void _pickImage({ImageSource source = ImageSource.gallery}) async {
    final imagePicker = ImagePicker();
    final XFile? pickedImage = await imagePicker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
        _resultImage = null; // clear previous result
        _errorMessage = null;
      });
      widget.onImagePicked(_image);
    }
  }

  Future<void> _predict() async {
    if (_image == null) {
      setState(() => _errorMessage = "Please select an image first.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultImage = null;
    });

    try {
      final uri = Uri.parse("https://mdjaasir-rice-seed-btp-latest.hf.space/predict");
      final request = http.MultipartRequest("POST", uri);
      request.files.add(await http.MultipartFile.fromPath("file", _image!.path));

      final response = await request.send().timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        setState(() {
          _resultImage = bytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Input Image ──
                const Text("Selected Image", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _image != null
                    ? Image.file(_image!, height: 200)
                    : const Text("No image selected"),

                const SizedBox(height: 16),

                // ── Pick Image Buttons ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _pickImage(source: ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      tooltip: "Pick from gallery",
                    ),
                    IconButton(
                      onPressed: () => _pickImage(source: ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      tooltip: "Take a photo",
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Predict Button ──
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _predict,
                  icon: const Icon(Icons.search),
                  label: const Text("Predict"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Loading ──
                if (_isLoading)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.orange),
                      SizedBox(height: 8),
                      Text("Analyzing seeds... please wait"),
                    ],
                  ),

                // ── Error ──
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),

                // ── Result Image ──
                if (_resultImage != null) ...[
                  const Text(
                    "Classification Result",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Image.memory(_resultImage!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
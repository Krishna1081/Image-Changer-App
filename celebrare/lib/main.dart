// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:splash_view/splash_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:widget_mask/widget_mask.dart';

void main() {
  runApp(const MyApp());
}

WidgetMask? _widgetMask;
File? _selectedImage;
String? _croppedImagePath;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool checkingOnTap = false;
File? _previousSelectedImage;
WidgetMask? _previousWidgetMask;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashView(
        logo: const FlutterLogo(
          size: 300,
        ),
        loadingIndicator: const CircularProgressIndicator(),
        done: Done(const HomePage()),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            exit(0);
          },
        ),
        title: const Text("Add Image/ Icon"),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                ),
              ),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Upload Image"),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        _pickImageFromGallery();
                      },
                      child: const Text("Choose from Device"))
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          _buildImageWidget(),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_widgetMask != null && _previousWidgetMask == null) {
      _previousWidgetMask = _widgetMask;
      return _widgetMask!;
    } else if (_selectedImage != null &&
        checkingOnTap == false &&
        _previousWidgetMask == null) {
      _previousSelectedImage = _selectedImage;
      return Image.file(_selectedImage!);
    } else if (_previousSelectedImage != null) {
      return Image.file(_previousSelectedImage!);
    } else if (_previousWidgetMask != null) {
      return _previousWidgetMask!;
    } else {
      return const Text("Please Select an Image");
    }
  }

  Future<void> _pickImageFromGallery() async {
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (returnImage == null) return;

    File? img = await _cropImage(imageFile: File(returnImage.path));

    setState(() {
      _selectedImage = img;
    });
  }

  Future<File?> _cropImage({required File imageFile}) async {
    CroppedFile? croppedImage =
        await ImageCropper().cropImage(sourcePath: imageFile.path);
    if (croppedImage == null) return null;

    _croppedImagePath = croppedImage.path;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomImageDialog(
          croppedImagePath: _croppedImagePath!,
          onUseImage: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
    return File(_croppedImagePath!);
  }
}

class CustomImageDialog extends StatefulWidget {
  final String croppedImagePath;
  final VoidCallback onUseImage;

  const CustomImageDialog({
    super.key,
    required this.croppedImagePath,
    required this.onUseImage,
  });

  @override
  State<CustomImageDialog> createState() => _CustomImageDialogState();
}

class _CustomImageDialogState extends State<CustomImageDialog> {
  String currentFramePath = "asset/user_image_frame_1.png";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      content: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                _widgetMask = null;
                _selectedImage = null;
                checkingOnTap = true;
                Navigator.of(context).pop();
              },
              child: const Align(
                alignment: Alignment.topRight,
                child: CircleAvatar(
                  radius: 14.0,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close, color: Colors.red),
                ),
              ),
            ),
          ),
          const Text(
            "Upload the image",
            style: TextStyle(
              fontSize: 21,
            ),
          ),
          _widgetMask ??
              Image.file(File(widget
                  .croppedImagePath)), // Display WidgetMask or the original Image
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildTextButton("Original"),
              buildIconButton("asset/user_image_frame_1.png"),
              buildIconButton("asset/user_image_frame_2.png"),
              buildIconButton("asset/user_image_frame_3.png"),
              buildIconButton("asset/user_image_frame_4.png"),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _previousWidgetMask = null;
                  _previousSelectedImage = null;
                  widget.onUseImage();
                },
                child: const Text("Use this image"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildIconButton(String framePath) {
    return SizedBox(
      width: 50,
      height: 50,
      child: IconButton(
        onPressed: () {
          setState(() {
            currentFramePath = framePath;
            _widgetMask = WidgetMask(
              // Update the WidgetMask
              blendMode: BlendMode.srcATop,
              childSaveLayer: true,
              mask:
                  Image.file(File(widget.croppedImagePath), fit: BoxFit.cover),
              child: Image.asset(currentFramePath),
            );
          });
        },
        icon: Image(image: AssetImage(framePath)),
      ),
    );
  }

  Widget buildTextButton(String text) {
    return SizedBox(
      width: 50,
      height: 50,
      child: TextButton(
        child: Text(text),
        onPressed: () {
          setState(() {
            _widgetMask = null;
          });
        },
      ),
    );
  }
}

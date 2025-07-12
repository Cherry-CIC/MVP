import 'dart:io';

import 'package:cherry_mvp/core/config/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_colors.dart';

class PhotoUpload extends StatefulWidget {
  const PhotoUpload({super.key});

  @override
  State<PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<PhotoUpload> {
  XFile? selectedImage;

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: double.infinity,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          selectedImage = picked;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _pickProductImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text(AppStrings.cameraPhoto),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(AppStrings.galleryPhoto),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Text(
            AppStrings.take_photo_instruction,
            style: GoogleFonts.instrumentSans(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                height: 26 / 18,
                letterSpacing: -0.75,
                color: AppColors.greyTextColor,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: GestureDetector(
            onTap: _pickProductImage,
            child: Container(
              height: selectedImage != null ? 406 : 140,
              width: 460,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.lightGreyTextColor,
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(selectedImage!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library,
                    color: AppColors.greyTextColor,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.take_photo,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.instrumentSans(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 20 / 16,
                        color: AppColors.greyTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


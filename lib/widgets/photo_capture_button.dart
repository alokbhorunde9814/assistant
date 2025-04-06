import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhotoCaptureButton extends StatelessWidget {
  final Function(String) onFileSelected;
  final bool isLoading;

  const PhotoCaptureButton({
    super.key,
    required this.onFileSelected,
    this.isLoading = false,
  });

  Future<void> _capturePhoto(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        onFileSelected(photo.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : () => _capturePhoto(context),
      icon: const Icon(Icons.camera_alt),
      label: Text(isLoading ? 'Processing...' : 'Take Photo'),
    );
  }
} 
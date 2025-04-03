import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:convert';
import 'dart:js' as js;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
      if (kIsWeb) {
        // For web platform, use our custom camera implementation
        final completer = Completer<List<String>>();
        
        // Set up event listener for photos
        js.context['onPhotosCaptured'] = (List<dynamic> photos) {
          if (photos != null) {
            completer.complete(photos.cast<String>());
          } else {
            completer.complete([]);
          }
        };

        // Call the camera function
        js.context.callMethod('openCamera');
        
        // Wait for photos to be captured
        final result = await completer.future;
        
        if (result.isNotEmpty) {
          // Show loading indicator with message
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Converting ${result.length} photos to PDF...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          try {
            // Create PDF document
            final pdf = pw.Document();
            
            // Convert each photo to PDF page
            for (var photoBase64 in result) {
              // Convert base64 to bytes
              final base64Data = photoBase64.toString().split(',').last;
              final bytes = base64Decode(base64Data);
              final uint8List = Uint8List.fromList(bytes);

              // Add page to PDF
              pdf.addPage(
                pw.Page(
                  build: (pw.Context context) {
                    return pw.Center(
                      child: pw.Image(pw.MemoryImage(uint8List)),
                    );
                  },
                ),
              );
            }

            // Generate PDF bytes
            final pdfBytes = await pdf.save();

            // Close the loading dialog
            if (context.mounted) {
              Navigator.pop(context);
            }

            // Show PDF preview dialog
            if (context.mounted) {
              final shouldUpload = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.8,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Preview PDF (${result.length} pages)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: SfPdfViewer.memory(
                              pdfBytes,
                              enableDoubleTapZooming: true,
                              pageLayoutMode: PdfPageLayoutMode.single,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Download PDF'),
                              onPressed: () {
                                // Create blob and download link
                                final blob = html.Blob([pdfBytes], 'application/pdf');
                                final url = html.Url.createObjectUrlFromBlob(blob);
                                final anchor = html.AnchorElement(href: url)
                                  ..setAttribute('download', 'photos_${DateTime.now().millisecondsSinceEpoch}.pdf')
                                  ..click();
                                html.Url.revokeObjectUrl(url);
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('Upload PDF'),
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (shouldUpload == true) {
                // Show upload progress
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Uploading PDF...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Upload to Firebase Storage
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final storageRef = FirebaseStorage.instance.ref();
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final uploadRef = storageRef.child('assignments/${user.uid}/photos_$timestamp.pdf');
                  
                  await uploadRef.putData(
                    pdfBytes,
                    SettableMetadata(contentType: 'application/pdf'),
                  );
                  
                  final downloadUrl = await uploadRef.getDownloadURL();
                  
                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  onFileSelected(downloadUrl);
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Successfully uploaded!'),
                                  Text(
                                    '${result.length} photos → 1 PDF',
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              }
            }
          } catch (e) {
            // Close loading dialog if it's showing
            if (context.mounted) {
              Navigator.pop(context);
            }
            
            // Show error message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Error processing images'),
                            Text(
                              e.toString(),
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 6),
                ),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No photos were captured or camera access was denied.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // For mobile platforms
        final ImagePicker picker = ImagePicker();
        final List<XFile> photos = await picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (photos.isNotEmpty) {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            // Create PDF document
            final pdf = pw.Document();
            
            // Convert each photo to PDF page
            for (var photo in photos) {
              final bytes = await photo.readAsBytes();
              final uint8List = Uint8List.fromList(bytes);
              
              pdf.addPage(
                pw.Page(
                  build: (pw.Context context) {
                    return pw.Center(
                      child: pw.Image(pw.MemoryImage(uint8List)),
                    );
                  },
                ),
              );
            }

            // Generate PDF bytes
            final pdfBytes = await pdf.save();

            // Close the loading dialog
            if (context.mounted) {
              Navigator.pop(context);
            }

            // Show PDF preview dialog
            if (context.mounted) {
              final shouldUpload = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.8,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Preview PDF (${photos.length} pages)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: SfPdfViewer.memory(
                              pdfBytes,
                              enableDoubleTapZooming: true,
                              pageLayoutMode: PdfPageLayoutMode.single,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Download PDF'),
                              onPressed: () {
                                // Create blob and download link
                                final blob = html.Blob([pdfBytes], 'application/pdf');
                                final url = html.Url.createObjectUrlFromBlob(blob);
                                final anchor = html.AnchorElement(href: url)
                                  ..setAttribute('download', 'photos_${DateTime.now().millisecondsSinceEpoch}.pdf')
                                  ..click();
                                html.Url.revokeObjectUrl(url);
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('Upload PDF'),
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (shouldUpload == true) {
                // Show upload progress
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Uploading PDF...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Upload to Firebase Storage
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final storageRef = FirebaseStorage.instance.ref();
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final uploadRef = storageRef.child('assignments/${user.uid}/photos_$timestamp.pdf');
                  
                  await uploadRef.putData(
                    pdfBytes,
                    SettableMetadata(contentType: 'application/pdf'),
                  );
                  
                  final downloadUrl = await uploadRef.getDownloadURL();
                  
                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  onFileSelected(downloadUrl);
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Successfully uploaded!'),
                                  Text(
                                    '${photos.length} photos → 1 PDF',
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              }
            }
          } catch (e) {
            // Close loading dialog
            if (context.mounted) {
              Navigator.pop(context);
            }
            
            // Show error message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Error processing images'),
                            Text(
                              e.toString(),
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 6),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error in _capturePhoto: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.add_a_photo,
        color: isLoading ? Colors.grey : Theme.of(context).primaryColor,
      ),
      onPressed: isLoading ? null : () => _capturePhoto(context),
      tooltip: 'Take Photos',
    );
  }
} 
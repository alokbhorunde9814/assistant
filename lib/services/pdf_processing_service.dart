import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:pdf_render/pdf_render.dart' as pdf_render;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'gemini_service.dart';

class PdfProcessingService {
  final GeminiService geminiService;

  PdfProcessingService({required this.geminiService});

  Future<Map<String, dynamic>> processPdf(Uint8List pdfBytes) async {
    final document = syncfusion.PdfDocument(inputBytes: pdfBytes);
    final pageCount = document.pages.count;
    final Map<String, dynamic> result = {
      'pageCount': pageCount,
      'images': <Map<String, dynamic>>[],
      'texts': <String>[],
      'textFilePath': '',
      'feedback': null,
    };

    // First, extract text using Syncfusion
    final List<String> allTexts = [];
    for (int i = 0; i < pageCount; i++) {
      final page = document.pages[i];
      try {
        final textExtractor = syncfusion.PdfTextExtractor(document);
        final text = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
        if (text.isNotEmpty) {
          final pageText = 'Page ${i + 1} Text:\n$text\n\n';
          result['texts'].add(pageText);
          allTexts.add(pageText);
        }
      } catch (e) {
        print('Error extracting text from page ${i + 1}: $e');
        allTexts.add('Page ${i + 1}: Error extracting text\n\n');
      }
    }
    document.dispose();

    // Save all text to a file
    try {
      final tempDir = await getTemporaryDirectory();
      final textFilePath = path.join(tempDir.path, 'extracted_text.txt');
      final textFile = File(textFilePath);
      
      // Join all texts with newlines and write to file
      await textFile.writeAsString(allTexts.join('\n'));
      result['textFilePath'] = textFilePath;
      print('Text saved to: $textFilePath');

      // Generate feedback using Gemini
      print('\nGenerating feedback using Gemini...');
      final feedback = await geminiService.generateFeedback(textFilePath);
      result['feedback'] = feedback;
    } catch (e) {
      print('Error saving text file: $e');
    }

    // Then, extract images using pdf_render
    try {
      final doc = await pdf_render.PdfDocument.openData(pdfBytes);
      
      for (int i = 1; i <= doc.pageCount; i++) {
        try {
          final page = await doc.getPage(i);
          final pageImage = await page.render(
            width: (page.width * 2).toInt(), // Convert to int
            height: (page.height * 2).toInt(), // Convert to int
          );
          
          if (pageImage != null) {
            // Get the image data
            final ui.Image image = await pageImage.createImageDetached();
            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            final pngBytes = byteData?.buffer.asUint8List();
            
            if (pngBytes != null) {
              final tempDir = await getTemporaryDirectory();
              final imagePath = path.join(tempDir.path, 'page_$i.png');
              final imageFile = File(imagePath);
              
              // Save the image data directly to a file
              await imageFile.writeAsBytes(pngBytes);
              
              result['images'].add({
                'page': i,
                'path': imagePath,
                'width': pageImage.width,
                'height': pageImage.height,
              });
              
              print('Page $i: Image extracted (${pageImage.width}x${pageImage.height})');
            }
          }
          
        } catch (e) {
          print('Error processing page $i: $e');
          result['texts'].add('Page $i: Error processing page');
        }
      }
      
    } catch (e) {
      print('Error opening PDF document: $e');
    }

    return result;
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'gemini_service.dart';

class PdfProcessingService {
  final GeminiService geminiService;

  PdfProcessingService({required this.geminiService});

  Future<Map<String, dynamic>> processPdf(Uint8List pdfBytes) async {
    final document = PdfDocument(inputBytes: pdfBytes);
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
        final textExtractor = PdfTextExtractor(document);
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
      final textFilePath = '${tempDir.path}/extracted_text.txt';
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

    return result;
  }

  Future<String> extractTextFromPdf(String filePath) async {
    try {
      // Load the PDF document
      final File file = File(filePath);
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from all pages
      String text = '';
      for (int i = 0; i < document.pages.count; i++) {
        text += PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
      }

      // Dispose the document
      document.dispose();

      return text;
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      rethrow;
    }
  }

  Future<String> extractTextFromPdfBytes(Uint8List pdfBytes) async {
    try {
      // Load the PDF document from bytes
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      // Extract text from all pages
      String text = '';
      for (int i = 0; i < document.pages.count; i++) {
        text += PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
      }

      // Dispose the document
      document.dispose();

      return text;
    } catch (e) {
      debugPrint('Error extracting text from PDF bytes: $e');
      rethrow;
    }
  }

  Future<String> savePdfToTemp(Uint8List pdfBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(tempPath);
      await file.writeAsBytes(pdfBytes);
      return tempPath;
    } catch (e) {
      debugPrint('Error saving PDF to temp: $e');
      rethrow;
    }
  }
}
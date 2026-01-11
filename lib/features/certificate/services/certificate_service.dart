import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class CertificateService {
  /// Generate and display print/save dialog for certificate
  static Future<void> generateAndPrintCertificate(String userName) async {
    final pdf = pw.Document();

    // Load certificate template image
    final imageData = await rootBundle.load('assets/images/certificates/certificate.png');
    final imageBytes = imageData.buffer.asUint8List();
    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Background certificate image
              pw.Positioned.fill(
                child: pw.Image(image, fit: pw.BoxFit.fill),
              ),
              
              // Overlay user name on top of the image
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(50),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Space to position the name where "Your Name" was
                      pw.SizedBox(height: 290),

                      // User Name - positioned at "Your Name" location
                      pw.Container(
                        width: 350,
                        child: pw.Text(
                          userName,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF1E3A8A), // Navy blue
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Show print/save dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'CyberGuard_Certificate_$userName.pdf',
    );
  }
}

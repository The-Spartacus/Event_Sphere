import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class CertificateViewer extends StatelessWidget {
  final String fileUrl;

  const CertificateViewer({
    super.key,
    required this.fileUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate'),
      ),
      body: SfPdfViewer.network(fileUrl),
    );
  }
}

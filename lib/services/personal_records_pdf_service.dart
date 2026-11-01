// ============================================================
// personal_records_pdf_service.dart
// Builds a printable/downloadable PDF summary of a member's Personal
// Records, with their Age/Gender/current BMI shown as context at the
// top. Uses the same pdf + printing pattern as the Admin app's
// EarningsPdfService so behavior (print/share/save dialog) is
// consistent across both apps.
// ============================================================

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PersonalRecordsPdfService {
  PersonalRecordsPdfService._();

  /// Builds the PDF document bytes.
  ///
  /// [rows] is one list per PR in the order: Exercise, Muscle, Weight (kg),
  /// Sets, Reps, Duration, Date -- matching the on-screen table.
  static Future<Uint8List> _buildPdf({
    required String memberName,
    required String generatedDate,
    required String? ageLabel,
    required String? genderLabel,
    required String? bmiLabel,
    required List<List<String>> rows,
  }) async {
    // NotoSans via the pdf package's Google Fonts loader, same as the
    // Admin app's earnings PDF -- keeps rendering consistent, and it's
    // needed if any future label uses a non-ASCII glyph (e.g. peso sign).
    pw.ThemeData? theme;
    try {
      final regularFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);
    } catch (_) {
      theme = null; // no internet / fetch failed -- falls back to default font
    }

    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('PrimeFit Gym',
                style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Personal Records Summary',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text('Member: $memberName',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text('Generated: $generatedDate',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildContextRow(ageLabel: ageLabel, genderLabel: genderLabel, bmiLabel: bmiLabel),
          pw.SizedBox(height: 16),
          pw.Text('Personal Records',
              style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _buildTable(rows),
        ],
      ),
    );

    return doc.save();
  }

  /// A row of small info chips: Age / Gender / Current BMI. Any that are
  /// null/empty are skipped rather than shown as "Not set" -- a PDF is a
  /// finished document, not a form.
  static pw.Widget _buildContextRow({
    required String? ageLabel,
    required String? genderLabel,
    required String? bmiLabel,
  }) {
    final chips = <pw.Widget>[];

    pw.Widget chip(String label, String value) => pw.Container(
          margin: const pw.EdgeInsets.only(right: 10),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFE0F7FA),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text('$label: $value',
              style: const pw.TextStyle(fontSize: 9.5, color: PdfColor.fromInt(0xFF00838F))),
        );

    if (ageLabel != null && ageLabel.isNotEmpty) chips.add(chip('Age', ageLabel));
    if (genderLabel != null && genderLabel.isNotEmpty) chips.add(chip('Gender', genderLabel));
    if (bmiLabel != null && bmiLabel.isNotEmpty) chips.add(chip('Current BMI', bmiLabel));

    if (chips.isEmpty) return pw.SizedBox();
    return pw.Wrap(children: chips);
  }

  static pw.Widget _buildTable(List<List<String>> rows) {
    const headers = ['Exercise', 'Muscle', 'Weight (kg)', 'Sets', 'Reps', 'Duration', 'Date'];

    if (rows.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Text(
          'No personal records logged yet.',
          style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 9),
        ),
      );
    }

    pw.Widget cell(String text, {required bool isHeader}) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 6, vertical: isHeader ? 6 : 5),
        child: pw.Text(
          text,
          style: isHeader
              ? const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)
              : const pw.TextStyle(fontSize: 9),
        ),
      );
    }

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF00B4D8)),
      children: [for (final h in headers) cell(h, isHeader: true)],
    );

    final dataRows = <pw.TableRow>[
      for (int r = 0; r < rows.length; r++)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: r.isOdd ? const PdfColor.fromInt(0xFFF8FAFC) : PdfColors.white,
            border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
          ),
          children: [for (final v in rows[r]) cell(v, isHeader: false)],
        ),
    ];

    return pw.Table(children: [headerRow, ...dataRows]);
  }

  /// Opens the OS print/share/save dialog for the PR summary. On desktop
  /// browsers and native apps alike, `Printing.layoutPdf` lets the member
  /// print a physical copy or save it as a PDF file -- covering both the
  /// "print" and "download" asks with one dialog.
  static Future<void> printOrDownload({
    required String memberName,
    required String? ageLabel,
    required String? genderLabel,
    required String? bmiLabel,
    required List<List<String>> rows,
  }) async {
    final now = DateTime.now();
    final generatedDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final bytes = await _buildPdf(
      memberName: memberName,
      generatedDate: generatedDate,
      ageLabel: ageLabel,
      genderLabel: genderLabel,
      bmiLabel: bmiLabel,
      rows: rows,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'PrimeFit_Personal_Records.pdf',
    );
  }
}

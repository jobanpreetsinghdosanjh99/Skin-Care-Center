import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/clinic.dart';
import '../models/patient.dart';
import '../models/prescription.dart';

/// Builds a printable, professionally formatted PDF for a single
/// prescription: clinic letterhead, patient details block, a table of
/// prescribed medicines, and the clinic's footer note / signature line.
///
/// This mirrors the "Print Prescription" feature of the original
/// third-party app, which always rendered prescriptions on a fixed A5
/// letterhead layout with the clinic name/address/phone at the top.
class PrescriptionPdf {
  static pw.Font? _gurmukhiFont;

  /// Loads (and caches) the Noto Sans Gurmukhi font so Punjabi text in
  /// footer notes / instructions renders correctly instead of showing
  /// as empty boxes — the default PDF fonts only cover Latin glyphs.
  static Future<pw.Font> _loadGurmukhiFont() async {
    final cached = _gurmukhiFont;
    if (cached != null) return cached;
    final data = await rootBundle.load('assets/fonts/NotoSansGurmukhi.ttf');
    final font = pw.Font.ttf(data);
    _gurmukhiFont = font;
    return font;
  }

  static Future<pw.Document> build({
    required Clinic clinic,
    required Patient patient,
    required Prescription prescription,
  }) async {
    final doc = pw.Document();
    final gurmukhiFont = await _loadGurmukhiFont();

    final dateStr =
        '${prescription.createdAt.day.toString().padLeft(2, '0')}/'
        '${prescription.createdAt.month.toString().padLeft(2, '0')}/'
        '${prescription.createdAt.year}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(fontFallback: [gurmukhiFont]),
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Watermark.text(
                  clinic.name,
                  angle: 0.6,
                  style: pw.TextStyle(
                    color: PdfColors.grey300,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 36,
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(clinic),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 1.2, color: PdfColors.blueGrey700),
                  pw.SizedBox(height: 8),
                  _buildPatientBlock(patient, dateStr, prescription),
                  pw.SizedBox(height: 12),
                  if (prescription.diseases.isNotEmpty ||
                      (prescription.diagnosisNotes ?? '').isNotEmpty) ...[
                    pw.Text(
                      'Diagnosis: '
                      '${prescription.diseases.map((d) => d.shortName).join(', ')}'
                      '${prescription.diseases.isNotEmpty && (prescription.diagnosisNotes ?? '').isNotEmpty ? ' — ' : ''}'
                      '${prescription.diagnosisNotes ?? ''}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                  ],
                  pw.Text(
                    'Rx',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  _buildItemsTable(prescription),
                  pw.SizedBox(height: 6),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Total Amount: Rs. ${prescription.totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                  ),
                  if ((prescription.generalInstructions ?? '').isNotEmpty) ...[
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Instructions:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(prescription.generalInstructions!),
                  ],
                  pw.Spacer(),
                  pw.Divider(thickness: 0.6, color: PdfColors.grey400),
                  if ((prescription.footerNote ?? '').isNotEmpty)
                    pw.Text(
                      prescription.footerNote!,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Signature: ______________________',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return doc;
  }

  static pw.Widget _buildHeader(Clinic clinic) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(
            clinic.name,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if ((clinic.address ?? '').isNotEmpty)
              pw.Text(
                clinic.address!,
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 8),
              ),
            if ((clinic.phone ?? '').isNotEmpty)
              pw.Text(
                'Ph: ${clinic.phone}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            if ((clinic.email ?? '').isNotEmpty)
              pw.Text(clinic.email!, style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPatientBlock(
    Patient patient,
    String dateStr,
    Prescription prescription,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                patient.fullName,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${patient.ageLabel != '-' ? '${patient.ageLabel} / ' : ''}${patient.gender}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Ph: ${patient.phone}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                'Patient #: ${patient.patientNumber}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              if ((prescription.duration ?? '').isNotEmpty)
                pw.Text(
                  'Duration: ${prescription.duration}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Prescription prescription) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        '#',
        'Medicine',
        'Dosage',
        'Qty',
        'Instructions',
        'Price',
        'Amount',
      ],
      data: prescription.items.asMap().entries.map((entry) {
        final item = entry.value;
        return [
          '${entry.key + 1}',
          item.medicineName,
          item.dosage,
          '${item.quantity}',
          item.instructions ?? '-',
          item.unitPrice.toStringAsFixed(2),
          item.totalPrice.toStringAsFixed(2),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.center,
        3: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(16),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FixedColumnWidth(20),
        4: const pw.FlexColumnWidth(1.6),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1.1),
      },
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    );
  }
}

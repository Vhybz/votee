import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/election_models.dart';
import 'package:intl/intl.dart';

class ReportService {
  static Future<void> generateElectionReport({
    required String title,
    required List<Position> positions,
    required List<Candidate> candidates,
    required ElectionStats stats,
  }) async {
    final pdf = pw.Document();

    // Load logo if possible
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/logo/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Fallback if logo not found
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(title, logo),
          pw.SizedBox(height: 20),
          _buildStatsSection(stats),
          pw.SizedBox(height: 30),
          pw.Text('Detailed Results by Position', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.SizedBox(height: 10),
          ...positions.map((pos) => _buildPositionResults(pos, candidates)),
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${title.replaceAll(' ', '_')}_Report.pdf',
    );
  }

  static pw.Widget _buildHeader(String title, pw.ImageProvider? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text('OFFICIAL ELECTION CERTIFICATION', style: pw.TextStyle(fontSize: 10, letterSpacing: 2, color: PdfColors.grey700)),
            pw.Text('Date Generated: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        if (logo != null)
          pw.Container(
            width: 60,
            height: 60,
            child: pw.Image(logo),
          ),
      ],
    );
  }

  static pw.Widget _buildStatsSection(ElectionStats stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Voters', stats.totalVoters.toString()),
          _buildStatItem('Votes Cast', stats.totalVotesCast.toString()),
          _buildStatItem('Turnout', '${stats.turnoutPercentage}%'),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildPositionResults(Position position, List<Candidate> allCandidates) {
    final posCandidates = allCandidates.where((c) => c.positionId == position.id).toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(position.title.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Rank', 'Candidate Name', 'Votes', 'Percentage'],
            data: List<List<String>>.generate(posCandidates.length, (index) {
              final c = posCandidates[index];
              final total = posCandidates.fold(0, (sum, item) => sum + item.voteCount);
              final pct = total > 0 ? (c.voteCount / total * 100).toStringAsFixed(1) : '0';
              return [
                (index + 1).toString(),
                c.fullName,
                c.voteCount.toString(),
                '$pct%',
              ];
            }),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 150, height: 1, color: PdfColors.black),
                pw.Text('Electoral Commissioner Signature', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Text('RavenVote Security Verified', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey500)),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(width: 150, height: 1, color: PdfColors.black),
                pw.Text('Official Stamp', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

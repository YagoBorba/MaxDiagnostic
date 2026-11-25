import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:maxt_diagnostic/core/config/demo_mode.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';

/// Builds the diagnostic PDF report and shares it through the native share sheet.
class ReportService {
  ReportService._();

  static const PdfColor _primary = PdfColor.fromInt(0xFF4F46E5);
  static const PdfColor _secondary = PdfColor.fromInt(0xFF374151);
  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _error = PdfColor.fromInt(0xFFEF4444);

  static Future<bool> shareReportFile(FinalResultsEntity results) async {
    try {
      final Uint8List bytes = await buildReport(results);

      final Directory tempDir = await getTemporaryDirectory();
      final File pdf = File(
        '${tempDir.path}/diagnostic_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await pdf.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(pdf.path, mimeType: 'application/pdf')],
          subject: 'Relatório de diagnóstico de rede · MaxDiagnostic',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('ReportService: Error generating or sharing the PDF: $e');
      return false;
    }
  }

  /// Renders the report as PDF bytes.
  @visibleForTesting
  static Future<Uint8List> buildReport(FinalResultsEntity results) {
    final speed = results.speedTestResult;
    final net = results.networkInfo;
    final initialNet = results.initialNetworkInfo;
    final device = results.deviceInfo;
    final String timestamp =
        DateFormat.yMMMMd('pt_BR').add_Hm().format(results.timestamp);

    final document = pw.Document(
      title: 'Relatório de diagnóstico de rede',
      creator: 'MaxDiagnostic',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Relatório gerado pelo MaxDiagnostic · página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ),
        build: (context) => [
          _header(timestamp),
          _section('Resultados do teste de velocidade', [
            pw.Row(children: [
              _metricCard('Download', _value(speed.downloadSpeed.toStringAsFixed(2), ' Mbps')),
              pw.SizedBox(width: 12),
              _metricCard('Upload', _value(speed.uploadSpeed.toStringAsFixed(2), ' Mbps')),
            ]),
            pw.SizedBox(height: 12),
            pw.Row(children: [
              _metricCard('Latência (ping)', _value(speed.ping.toStringAsFixed(1), ' ms')),
              pw.SizedBox(width: 12),
              _metricCard('Jitter', _value(speed.jitter.toStringAsFixed(1), ' ms')),
            ]),
          ]),
          _section('Informações da conexão', [
            _details({
              'IP externo': _value(net.externalIP),
              'Provedor (ISP)': _value(net.isp),
              'Servidor do teste': _value(speed.serverLocation),
              'IP interno': _value(net.internalIP),
            }),
          ]),
          _section('Análise do Wi-Fi', [
            _details({
              'SSID (nome da rede)': _value(net.wifiName),
              'BSSID': _value(net.wifiBSSID),
              'Sinal (início)': _value(initialNet.wifiSignalStrength?.toString(), ' dBm'),
              'Sinal (final)': _value(net.wifiSignalStrength?.toString(), ' dBm'),
              'Banda': _value(net.wifiFrequency),
              'Padrão': _value(net.wifiStandard),
              'Canal': _value(net.wifiChannel?.toString()),
              'Velocidade do link': _value(net.wifiLinkSpeed?.toString(), ' Mbps'),
            }),
          ]),
          _section('Informações do dispositivo', [
            _details({
              'Dispositivo': _value('${device.deviceBrand} ${device.deviceModel}'.trim()),
              'Sistema operacional': _value('${device.operatingSystem} ${device.osVersion}'.trim()),
            }),
          ]),
          if (speed.errorMessage != null && speed.errorMessage!.isNotEmpty)
            _section('Alertas e erros', [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _error),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Falha no teste de velocidade',
                        style: pw.TextStyle(color: _error, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(speed.errorMessage!),
                  ],
                ),
              ),
            ]),
        ],
      ),
    );

    return document.save();
  }

  static String _value(String? value, [String unit = '']) {
    if (value == null || value.isEmpty) {
      return 'N/A';
    }
    return '$value$unit';
  }

  static pw.Widget _header(String timestamp) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      margin: const pw.EdgeInsets.only(bottom: 24),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Relatório de diagnóstico de rede',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.SizedBox(height: 4),
          pw.Text('Gerado em $timestamp', style: const pw.TextStyle(fontSize: 11, color: _muted)),
          if (kDemoMode) ...[
            pw.SizedBox(height: 6),
            pw.Text('Dados simulados (modo demonstração): este relatório não mede uma conexão real.',
                style: pw.TextStyle(fontSize: 11, color: _error, fontWeight: pw.FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.only(bottom: 6),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _border)),
            ),
            child: pw.Text(title,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _secondary)),
          ),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _metricCard(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: _surface,
          border: pw.Border.all(color: _border),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _secondary)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _details(Map<String, String> rows) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(3),
      },
      border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _border)),
      children: [
        for (final entry in rows.entries)
          pw.TableRow(children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Text(entry.key, style: const pw.TextStyle(color: _muted)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Text(entry.value),
            ),
          ]),
      ],
    );
  }
}

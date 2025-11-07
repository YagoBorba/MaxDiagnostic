import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:flutter/material.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';

class ReportService {
  ReportService._();

  static Future<bool> shareReportFile(
    FinalResultsEntity results,
  ) async {
    try {
      final String logoBase64 = await _getLogoBase64();

      final String html = _generateHtmlReport(results, logoBase64);

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'diagnostic_report_${DateTime.now().millisecondsSinceEpoch}';

      final generatedPdf =
          await FlutterHtmlToPdf.convertFromHtmlContent(
        html,
        tempDir.path,
        fileName,
      );

      if (generatedPdf.path.isEmpty) {
        debugPrint('ReportService: PDF generation failed.');
        return false;
      }

      final XFile pdfFile = XFile(generatedPdf.path);

      await SharePlus.instance.share(
        ShareParams(
          files: [pdfFile],
          subject: 'Relatório de Diagnóstico Max Internet',
        ),
      );

      return true;
    } catch (e) {
      debugPrint('ReportService: Error generating or sharing the PDF: $e');
      return false;
    }
  }

  static Future<String> _getLogoBase64() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      final List<int> bytes = data.buffer.asUint8List();
      final String base64 = base64Encode(bytes);
      return 'data:image/png;base64,$base64';
    } catch (error) {
      debugPrint('ReportService: Error loading logo for the report: $error');
      return '';
    }
  }

  static String _generateHtmlReport(
    FinalResultsEntity results,
    String logoBase64,
  ) {
    String formatValue(String? value, [String unit = '']) {
      if (value == null || value.isEmpty || value == '0.0') {
        return '<span class="not-available">N/A</span>';
      }
      return '$value$unit';
    }

    final String timestamp =
        DateFormat.yMMMMd('pt_BR').add_Hm().format(results.timestamp);

    const icons = {
      'download':
          'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWRvd25sb2FkIj48cGF0aCBkPSJNMjEgMTV2NGExIDIgMCAwIDEtMiAyaC0xNGExIDIgMCAwIDEtMi0ydi00Ii8+PHBvbHlsaW5lIHBvaW50cz0iNyAxMCAxMiAxNSAxNyAxMCIvPjxsaW5lIHgxPSIxMiIgeDI9IjEyIiB5MT0iMTUiIHkyPSIzIi8+PC9zdmc+',
      'upload':
          'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXVwbG9hZCI+PHBhdGggZD0iTTIxIDE1djRhMiAyIDAgMCAxLTIgMmgtMTRhMiAyIDAgMCAxLTItMnYtNCIvPjxwb2x5bGluZSBwb2ludHM9IjE3IDEwIDEyIDUgNyAxMCIvPjxsaW5lIHgxPSIxMiIgeDI9IjEyIiB5MT0iNSIgeTI9IjE1Ii8+PC9zdmc+',
      'ping':
          'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWdhdWdlLWNpcmNsZSI+PHBhdGggZD0iTTExIDE1aDIiLz48cGF0aCBkPSJNMTQuMiAxMC44IDEzIDEzIi8+PHBhdGggZD0iTTkuOCAxMC44IDExIDEzIi8+PHBhdGggZD0iTTEwIDIxSDZBMiAyIDAgMCAxIDQgMTlWNUExIDIgMCAwIDEgNiAzaDQiLz48cGF0aCBkPSJNMTQgM2g0YTIgMiAwIDAgMSA0IDJ2MTRhMiAyIDAgMCAxLTQgMmgtdjAiLz48cGF0aGcgZD0iTTE4IDIxdi0zLjMiPjwvcGF0aD48L3N2Zz4=',
      'jitter':
          'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXdhdmVzIj48cGF0aCBkPSJNMCA4YzAgMCAxLjUgMS41IDMgMFM2IDggOSA4Ii8+PHBhdGggZD0iTTIgOGMwIDAgMS41IDEuNSAzIDBTOCA4IDExIDgiLz48cGF0aCBkPSJNMjIgOGMwIDAgLTEuNSAxLjUtMyAwcy0zLTEuNS0zLTEuNSIvPjxwYXRoIGQ9Ik0xNiA4YzAgMCAxLjUgMS41IDMgMFM1MjIgOCAyMiA4Ii8+PHBhdGggZD0iTTUgMThjMCAwIDEuNS0xLjUgMyAwczMtMS41IDMtMS41Ii8+PHBhdGggZD0iTTE5IDE4YzAgMCAxLjUtMS41IDMgMFMxOSAxOCAxOSA4Ii8+PHBhdGggZD0ibTEzIDE4Yy0yIDAtMy0xLjUtMy0xLjUiLz48L3N2Zz4=',
    };

    const String styles = '''
    <style>
      :root { --primary-color: #4F46E5; --secondary-color: #374151; --border-color: #E5E7EB; --background-light: #F9FAFB; --text-color: #374151; --text-light: #6B7280; --error-color: #EF4444; }
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 40px; color: var(--text-color); background-color: #fff; font-size: 14px; line-height: 1.6; }
      .header { display: flex; align-items: center; border-bottom: 2px solid var(--border-color); padding-bottom: 20px; margin-bottom: 30px; }
      .logo { width: 60px; height: auto; margin-right: 20px; }
      .header-text h1 { margin: 0; color: var(--primary-color); font-size: 24px; font-weight: 700; }
      .header-text p { margin: 4px 0 0; color: var(--text-light); font-size: 14px; }
      .section { margin-bottom: 30px; page-break-inside: avoid; }
      h2 { font-size: 20px; color: var(--secondary-color); padding-bottom: 10px; margin-top: 0; margin-bottom: 20px; border-bottom: 1px solid var(--border-color); }
      .summary-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 30px; }
      .card { background-color: var(--background-light); border: 1px solid var(--border-color); border-radius: 8px; padding: 20px; display: flex; align-items: center; }
      .card-icon { width: 32px; height: 32px; margin-right: 15px; color: var(--primary-color); }
      .card-content .label { font-size: 14px; color: var(--text-light); margin: 0 0 5px 0; }
      .card-content .value { font-size: 22px; font-weight: 600; color: var(--secondary-color); margin: 0; }
      .details-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0 30px; }
      .detail-item { display: flex; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid var(--border-color); }
      .detail-item:last-child { border-bottom: none; }
      .detail-item .label { font-weight: 500; color: var(--text-light); }
      .detail-item .value { font-weight: 600; text-align: right; }
      .not-available { color: #9CA3AF; font-style: italic; }
      .error-section h2 { color: var(--error-color); }
      .error-item { padding: 10px; border: 1px solid #FECACA; background-color: #FEF2F2; border-radius: 6px; margin-bottom: 10px; }
      .error-item .label { font-weight: bold; color: #B91C1C; }
      .error-item .message { color: #991B1B; }
      .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid var(--border-color); font-size: 12px; color: #9CA3AF; }
      @media print { body { -webkit-print-color-adjust: exact; print-color-adjust: exact; } }
    </style>''';

    final speed = results.speedTestResult;
    final net = results.networkInfo;
    final device = results.deviceInfo;

    final String body = '''
    <div class="header">
      ${logoBase64.isNotEmpty ? '<img src="$logoBase64" class="logo" alt="Logo">' : ''}
      <div class="header-text">
        <h1>Relatório de Diagnóstico de Rede</h1>
        <p>Gerado em: $timestamp</p>
      </div>
    </div>
    
    <div class="section">
      <div class="summary-grid">
        <div class="card"><img src="${icons['download']}" class="card-icon" /><div class="card-content"><p class="label">Download</p><p class="value">${formatValue(speed.downloadSpeed.toStringAsFixed(2), ' Mbps')}</p></div></div>
        <div class="card"><img src="${icons['upload']}" class="card-icon" /><div class="card-content"><p class="label">Upload</p><p class="value">${formatValue(speed.uploadSpeed.toStringAsFixed(2), ' Mbps')}</p></div></div>
        <div class="card"><img src="${icons['ping']}" class="card-icon" /><div class="card-content"><p class="label">Latência (Ping)</p><p class="value">${formatValue(speed.ping.toStringAsFixed(1), ' ms')}</p></div></div>
        <div class="card"><img src="${icons['jitter']}" class="card-icon" /><div class="card-content"><p class="label">Jitter</p><p class="value">${formatValue(speed.jitter.toStringAsFixed(1), ' ms')}</p></div></div>
      </div>
    </div>
    
    <div class="section">
      <h2>Análise Wi-Fi</h2>
      <div class="details-grid">
        <div class="detail-item"><span class="label">Sinal (RSSI)</span><span class="value">${formatValue(net.wifiSignalStrength?.toString(), ' dBm')}</span></div>
        <div class="detail-item"><span class="label">Banda</span><span class="value">${formatValue(net.wifiFrequency)}</span></div>
        <div class="detail-item"><span class="label">Velocidade do Link</span><span class="value">${formatValue(net.wifiLinkSpeed?.toString(), ' Mbps')}</span></div>
        <div class="detail-item"><span class="label">SSID (Nome da Rede)</span><span class="value">${formatValue(net.wifiName)}</span></div>
        <div class="detail-item"><span class="label">BSSID</span><span class="value">${formatValue(net.wifiBSSID)}</span></div>
      </div>
    </div>
    
    <div class="section">
      <h2>Detalhes Técnicos</h2>
      <div class="details-grid">
        <div class="detail-item"><span class="label">IP Externo</span><span class="value">${formatValue(net.externalIP)}</span></div>
        <div class="detail-item"><span class="label">IP Interno</span><span class="value">${formatValue(net.internalIP)}</span></div>
        <div class="detail-item"><span class="label">Dispositivo</span><span class="value">${formatValue('${device.deviceBrand} ${device.deviceModel}')}</span></div>
        <div class="detail-item"><span class="label">Sistema Operacional</span><span class="value">${formatValue('${device.operatingSystem} ${device.osVersion}')}</span></div>
        <div class="detail-item"><span class="label">Servidor do Teste</span><span class="value">${formatValue(speed.serverLocation)}</span></div>
      </div>
    </div>

    ${(speed.errorMessage != null && speed.errorMessage!.isNotEmpty) ? '''
    <div class="section error-section">
      <h2>Alertas e Erros</h2>
      <div class="error-item">
        <div class="label">Speed Test Failure</div>
        <div class="message">${speed.errorMessage}</div>
      </div>
    </div>
    ''' : ''}
    
    <div class="footer">
      Relatório gerado pelo aplicativo Max Diagnóstico
    </div>
    ''';

    return '''<!DOCTYPE html><html><head><title>Relatório de Diagnóstico</title>$styles</head><body>$body</body></html>''';
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/domain/services/advice_service.dart';
import 'package:maxt_diagnostic/features/results/presentation/view/widgets/advice_card.dart';

class ResultsScreen extends StatelessWidget {
  final FinalResultsEntity results;

  const ResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final adviceList = AdviceService().getAdvice(results);
    final timestamp = results.timestamp;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/'), // Sempre volta para a Home
        ),
        title: const Text('MAX INTERNET',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Diagnóstico Concluído',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(timestamp),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                _ResultSection(
                  title: 'Velocidade da Internet',
                  children: [
                    _ResultTile(
                        icon: LucideIcons.arrowDownToLine,
                        label: 'Download',
                        value: results.speedTestResult.downloadSpeed,
                        unit: 'Mbps'),
                    _ResultTile(
                        icon: LucideIcons.arrowUpFromLine,
                        label: 'Upload',
                        value: results.speedTestResult.uploadSpeed,
                        unit: 'Mbps'),
                  ],
                ),
                const SizedBox(height: 12),
                _ResultSection(
                  title: 'Qualidade da Conexão',
                  children: [
                    _ResultTile(
                        icon: LucideIcons.activity,
                        label: 'Latência',
                        value: results.speedTestResult.ping,
                        unit: 'ms'),
                    _ResultTile(
                        icon: LucideIcons.activity,
                        label: 'Jitter',
                        value: results.speedTestResult.jitter,
                        unit: 'ms'),
                  ],
                ),
                const SizedBox(height: 16),
                ...adviceList.map((advice) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: AdviceCard(advice: advice),
                    )),
              ],
            ),
          ),
          _FooterActions(),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ResultSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? value;
  final String unit;

  const _ResultTile(
      {required this.icon,
      required this.label,
      this.value,
      required this.unit});

  @override
  Widget build(BuildContext context) {
    final displayValue =
        (value != null) ? '${value!.toStringAsFixed(2)} $unit' : 'Falha';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              Text(displayValue,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.share2),
              label: const Text('Exportar Relatório'),
              onPressed: () {/* TODO */},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.repeat),
              label: const Text('Novo Teste'),
              onPressed: () => context.go('/diagnostic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0E7FF),
                foregroundColor: const Color(0xFF4338CA),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

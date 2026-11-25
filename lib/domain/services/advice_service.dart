import 'package:maxt_diagnostic/domain/entities/advice_entity.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';

class _Rule {
  final String id;
  final bool Function(FinalResultsEntity r) condition;
  final AdviceEntity Function(FinalResultsEntity r) advice;

  _Rule({required this.id, required this.condition, required this.advice});
}

class AdviceService {
  List<AdviceEntity> getAdvice(FinalResultsEntity results) {
    final allTriggeredRules = _rules
        .where((rule) => rule.condition(results))
        .map((rule) => rule.advice(results))
        .toList();

    final problems = allTriggeredRules
        .where((advice) =>
            advice.severity == AdviceSeverity.critical ||
            advice.severity == AdviceSeverity.warning)
        .toList();

    if (problems.isNotEmpty) {
      problems.sort((a, b) => a.severity.index.compareTo(b.severity.index));
      return problems;
    }

    final info = allTriggeredRules
        .where((advice) => advice.severity == AdviceSeverity.info)
        .toList();

    if (info.isNotEmpty) {
      info.sort((a, b) => a.severity.index.compareTo(b.severity.index));
      return info;
    }

    final good = allTriggeredRules
        .where((advice) => advice.severity == AdviceSeverity.good)
        .toList();

    if (good.isNotEmpty) {
      good.sort((a, b) => a.severity.index.compareTo(b.severity.index));
      return good;
    }

    return const [
      AdviceEntity(
        id: 'no_issues_detected',
        title: 'Nenhum Problema Específico Detectado',
        description:
            'Não encontramos nenhum gargalo ou problema óbvio em sua rede durante o teste. A conexão parece estar funcionando normalmente.',
        severity: AdviceSeverity.good,
      ),
    ];
  }

  static final List<_Rule> _rules = [
    _Rule(
      id: 'bottleneck_wifi_environment',
      condition: (r) =>
          r.networkInfo.wifiLinkSpeed != null &&
          (r.speedTestResult.downloadSpeed) <
              r.networkInfo.wifiLinkSpeed! * 0.5,
      advice: (r) => AdviceEntity(
        id: 'bottleneck_wifi_environment',
        title: 'Otimize seu Ambiente Wi-Fi',
        description:
            'Sua conexão Wi-Fi com o roteador tem um potencial de ${r.networkInfo.wifiLinkSpeed} Mbps, mas a velocidade de internet medida foi bem menor. Isso sugere que o gargalo está no seu ambiente (interferência, distância, obstáculos).',
        severity: AdviceSeverity.critical,
      ),
    ),
    _Rule(
      id: 'high_jitter_and_ping',
      condition: (r) =>
          (r.speedTestResult.ping) > 100 && (r.speedTestResult.jitter) > 40,
      advice: (r) => const AdviceEntity(
        id: 'high_jitter_and_ping',
        title: 'Conexão Lenta e Instável',
        description:
            'Sua conexão apresenta tanto um tempo de resposta alto (ping) quanto alta variação (jitter). Isso afeta negativamente jogos, vídeos e navegação. Reiniciar o roteador pode ajudar.',
        severity: AdviceSeverity.warning,
      ),
    ),
    _Rule(
      id: 'performance_tier_analysis',
      condition: (r) => r.speedTestResult.downloadSpeed >= 0,
      advice: (r) {
        final speed = r.speedTestResult.downloadSpeed;
        String desc;
        if (speed > 30) {
          desc =
              'Sua velocidade de ${speed.toStringAsFixed(0)} Mbps é excelente para múltiplas tarefas simultâneas, como streaming em 4K, jogos e downloads.';
        } else if (speed > 10) {
          desc =
              'Sua velocidade de ${speed.toStringAsFixed(0)} Mbps é ótima para streaming de vídeos em alta definição (HD) e para o uso diário da maioria das famílias.';
        } else {
          desc =
              'Sua velocidade de ${speed.toStringAsFixed(0)} Mbps é adequada para tarefas como navegação em redes sociais, e-mails e streaming de vídeo em qualidade padrão (SD).';
        }
        return AdviceEntity(
            id: 'performance_tier_analysis',
            title: 'Análise de Performance',
            description: desc,
            severity: AdviceSeverity.info);
      },
    ),
  ];
}

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
    final triggeredAdvice = <AdviceEntity>[];

    for (final rule in _rules) {
      if (rule.condition(results)) {
        triggeredAdvice.add(rule.advice(results));
      }
    }

    if (triggeredAdvice.isEmpty) {
      triggeredAdvice.add(
        const AdviceEntity(
          id: 'no_issues_detected',
          title: 'Nenhum Problema Específico Detectado',
          description:
              'Não encontramos nenhum gargalo ou problema óbvio em sua rede durante o teste. A conexão parece estar funcionando normalmente.',
          severity: AdviceSeverity.good,
        ),
      );
    }

    triggeredAdvice
        .sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return triggeredAdvice;
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
      id: 'high_latency_and_jitter',
      condition: (r) =>
          (r.pingResult.averageLatencyMs) > 100 &&
          (r.pingResult.jitterMs) > 20,
      advice: (r) => AdviceEntity(
        id: 'high_latency_and_jitter',
        title: 'Conexão Lenta e Instável',
        description:
            'Sua conexão apresenta tempo de resposta alto (${r.pingResult.averageLatencyMs.toStringAsFixed(0)} ms) e grande variação (jitter de ${r.pingResult.jitterMs.toStringAsFixed(0)} ms). Isso compromete jogos online e chamadas de vídeo. Reinicie o modem/roteador e verifique interferências.',
        severity: AdviceSeverity.warning,
      ),
    ),
    _Rule(
      id: 'packet_loss_detected',
      condition: (r) => r.pingResult.packetLossPercentage > 5,
      advice: (r) => AdviceEntity(
        id: 'packet_loss_detected',
        title: 'Perda de Pacotes Elevada',
        description:
            'Detectamos perda de pacotes de ${r.pingResult.packetLossPercentage.toStringAsFixed(1)}%. Isso causa travamentos e instabilidade. Certifique-se de que os cabos estejam firmes e que não haja muita distância do roteador.',
        severity: AdviceSeverity.critical,
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

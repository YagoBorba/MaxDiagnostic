// lib/features/diagnostic/presentation/view/diagnostic_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/cubit/diagnostic_cubit.dart';

class DiagnosticScreen extends StatelessWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DiagnosticCubit>()..startTest(), // Cria e inicia o teste
      child: Scaffold(
        appBar: AppBar(title: const Text('Diagnóstico em Andamento')),
        body: BlocBuilder<DiagnosticCubit, DiagnosticState>(
          builder: (context, state) {
            // UI básica para provar que funciona
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Progresso Geral: ${(state.overallProgress * 100).toStringAsFixed(0)}%'),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text('Status: ${state.globalStatus.name}'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

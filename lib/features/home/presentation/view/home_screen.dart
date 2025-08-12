// lib/features/home/presentation/view/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maxt_diagnostic/features/home/presentation/cubit/home_cubit.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/diagnostic_button.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/network_info_card.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/quick_tips_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status da Rede'), // TODO: Usar logo aqui
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeInitial) {
            context.read<HomeCubit>().fetchInitialInfo();
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is HomeError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Erro ao carregar: ${state.message}', 
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.read<HomeCubit>().fetchInitialInfo(),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          if (state is HomeLoaded) {
            // A UI principal quando os dados estão carregados
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NetworkInfoCard(networkInfo: state.networkInfo),
                  const SizedBox(height: 16),
                  const QuickTipsCard(),
                  const SizedBox(height: 20),
                  DiagnosticButton(
                    isEnabled: state.networkInfo.connectionType != 'None',
                    onPressed: () {
                      context.go('/diagnostic');
                    },
                  ),
                ],
              ),
            );
          }
          
          return const Center(child: Text('Estado não reconhecido.'));
        },
      ),
    );
  }
}

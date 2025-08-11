import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxt_diagnostic/features/speed_test/cubit/speed_test_cubit.dart';
import 'package:maxt_diagnostic/features/speed_test/cubit/speed_test_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SpeedTestScreen extends StatelessWidget {
  const SpeedTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.app_title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: BlocBuilder<SpeedTestCubit, SpeedTestState>(
          builder: (context, state) {
            if (state is SpeedTestLoading) {
              return const CircularProgressIndicator();
            }
            if (state is SpeedTestError) {
               return Text('Erro: ${state.message}');
            }
            return ElevatedButton(
              onPressed: () => context.read<SpeedTestCubit>().startTest(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text(AppLocalizations.of(context)!.start_diagnostic_button),
            );
          },
        ),
      ),
    );
  }
}
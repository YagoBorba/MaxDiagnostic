import 'package:flutter_test/flutter_test.dart';
import 'package:maxt_diagnostic/features/home/presentation/cubit/home_cubit.dart';

void main() {
  group('HomeCubit Basic Tests', () {
    test('HomeCubit should exist and be properly defined', () {
      expect(HomeCubit, isA<Type>());
    });

    test('HomeState hierarchy should be properly defined', () {
      expect(HomeInitial, isA<Type>());
      expect(HomeLoading, isA<Type>());
      expect(HomeLoaded, isA<Type>());
      expect(HomeError, isA<Type>());
      expect(HomePermissionDenied, isA<Type>());
    });

    test('HomeInitial should be a valid state', () {
      const state = HomeInitial();
      expect(state, isA<HomeState>());
      expect(state.props, isEmpty);
    });

    test('HomeLoading should be a valid state', () {
      const state = HomeLoading();
      expect(state, isA<HomeState>());
      expect(state.props, isEmpty);
    });

    test('HomeError should contain error message', () {
      const errorMessage = 'Test error';
      const state = HomeError(message: errorMessage);
      expect(state, isA<HomeState>());
      expect(state.message, errorMessage);
      expect(state.props, contains(errorMessage));
    });
  });
}

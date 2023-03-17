// ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:sample_bloc_weather/weather/cubit/weather_cubit.dart';
import 'package:sample_bloc_weather/weather/models/weather.dart';
import 'package:sample_bloc_weather/weather/weather.dart' as weather_sub;
import 'package:mocktail/mocktail.dart';
import 'package:sample_bloc_weather/weather/weather.dart';
import 'package:test/test.dart';
import 'package:weather_repository/weather_repository.dart'
as weather_repository;

import 'helper.dart';



const weatherLocation = 'London';
const weatherCondition = weather_repository.WeatherCondition.rainy;
const weatherTemperature = 9.8;

class MockWeatherRepository extends Mock
    implements weather_repository.WeatherRepository {}

class MockWeather extends Mock implements weather_repository.WeatherRepo {}

void main() {
  initHydratedStorage();

  group('WeatherCubit', () {
    late weather_repository.WeatherRepo weather;
    late weather_repository.WeatherRepository weatherRepository;
    late weather_sub.WeatherCubit weatherCubit;

    setUp(() async {
      weather = MockWeather();
      weatherRepository = MockWeatherRepository();
      when(() => weather.condition).thenReturn(weatherCondition);
      when(() => weather.location).thenReturn(weatherLocation);
      when(() => weather.temperature).thenReturn(weatherTemperature);
      when(
            () => weatherRepository.getWeather(any()),
      ).thenAnswer((_) async => weather);
      weatherCubit = weather_sub.WeatherCubit(weatherRepository);
    });

    test('initial state is correct', () {
      final weatherCubit = weather_sub.WeatherCubit(weatherRepository);
      expect(weatherCubit.state, weather_sub.WeatherState());
    });

    group('toJson/fromJson', () {
      test('work properly', () {
        final weatherCubit =weather_sub.WeatherCubit(weatherRepository);
        expect(
          weatherCubit.fromJson(weatherCubit.toJson(weatherCubit.state)),
          weatherCubit.state,
        );
      });
    });

    group('fetchWeather', () {
      blocTest<weather_sub.WeatherCubit, weather_sub.WeatherState>(
        'emits nothing when city is null',
        build: () => weatherCubit,
        act: (cubit) => cubit.fetchWeather(null),
        expect: () => <weather_sub.WeatherState>[],
      );

      blocTest<weather_sub.WeatherCubit, weather_sub.WeatherState>(
        'emits nothing when city is empty',
        build: () => weatherCubit,
        act: (cubit) => cubit.fetchWeather(''),
        expect: () => <weather_sub.WeatherState>[],
      );

      blocTest<weather_sub.WeatherCubit, weather_sub.WeatherState>(
        'calls getWeather with correct city',
        build: () => weatherCubit,
        act: (cubit) => cubit.fetchWeather(weatherLocation),
        verify: (_) {
          verify(() => weatherRepository.getWeather(weatherLocation)).called(1);
        },
      );

      blocTest<weather_sub.WeatherCubit, weather_sub.WeatherState>(
        'emits [loading, failure] when getWeather throws',
        setUp: () {
          when(
                () => weatherRepository.getWeather(any()),
          ).thenThrow(Exception('oops'));
        },
        build: () => weatherCubit,
        act: (cubit) => cubit.fetchWeather(weatherLocation),
        expect: () => <weather_sub.WeatherState>[
          weather_sub.WeatherState(status: weather_sub.WeatherStatus.loading),
          weather_sub.WeatherState(status: weather_sub.WeatherStatus.failure),
        ],
      );

      blocTest<weather_sub.WeatherCubit, weather_sub.WeatherState>(
        'emits [loading, success] when getWeather returns (celsius)',
        build: () => weatherCubit,
        act: (cubit) => cubit.fetchWeather(weatherLocation),
        expect: () => <dynamic>[
          weather_sub.WeatherState(status: weather_sub.WeatherStatus.loading),
          isA<weather_sub.WeatherState>()
              .having((w) => w.status, 'status', weather_sub.WeatherStatus.success)
              .having(
                (w) => w.weather,
            'weather',
            isA<weather_sub.Weather>()
                .having((w) => w.lastUpdated, 'lastUpdated', isNotNull)
                .having((w) => w.condition, 'condition', weatherCondition)
                .having(
                  (w) => w.temperature,
              'temperature',
              Temperature(value: weatherTemperature),
            )
                .having((w) => w.location, 'location', weatherLocation),
          ),
        ],
      );

      blocTest<weather_sub.WeatherCubit, weather_sub.WeatherState>(
        'emits [loading, success] when getWeather returns (fahrenheit)',
        build: () => weatherCubit,
        seed: () => weather_sub.WeatherState(temperatureUnits: weather_sub.TemperatureUnits.fahrenheit),
        act: (cubit) => cubit.fetchWeather(weatherLocation),
        expect: () => <dynamic>[
          weather_sub.WeatherState(
            status: weather_sub.WeatherStatus.loading,
            temperatureUnits: weather_sub.TemperatureUnits.fahrenheit,
          ),
          isA<weather_sub.WeatherState>()
              .having((w) => w.status, 'status', weather_sub.WeatherStatus.success)
              .having(
                (w) => w.weather,
            'weather',
            isA<weather_sub.Weather>()
                .having((w) => w.lastUpdated, 'lastUpdated', isNotNull)
                .having((w) => w.condition, 'condition', weatherCondition)
                .having(
                  (w) => w.temperature,
              'temperature',
              weather_sub.Temperature(value: weatherTemperature.toFahrenheit()),
            )
                .having((w) => w.location, 'location', weatherLocation),
          ),
        ],
      );
    });

    group('refreshWeather', () {
      blocTest<weather_sub.WeatherCubit, weather_sub.WeatherState>(
        'emits nothing when status is not success',
        build: () => weatherCubit,
        act: (cubit) => cubit.refreshWeather(),
        expect: () => <weather_sub.WeatherState>[],
        verify: (_) {
          verifyNever(() => weatherRepository.getWeather(any()));
        },
      );

      blocTest<weather_sub.WeatherCubit, weather_sub.WeatherState>(
        'emits nothing when location is null',
        build: () => weatherCubit,
        seed: () => weather_sub.WeatherState(status: weather_sub.WeatherStatus.success),
        act: (cubit) => cubit.refreshWeather(),
        expect: () => <weather_sub.WeatherState>[],
        verify: (_) {
          verifyNever(() => weatherRepository.getWeather(any()));
        },
      );

      blocTest<weather_sub.WeatherCubit, weather_sub.WeatherState>(
        'invokes getWeather with correct location',
        build: () => weatherCubit,
        seed: () => weather_sub.WeatherState(
          status: weather_sub.WeatherStatus.success,
          weather: weather_sub.Weather(
            location: weatherLocation,
            temperature: Temperature(value: weatherTemperature),
            lastUpdated: DateTime(2020),
            condition: weatherCondition,
          ),
        ),
        act: (cubit) => cubit.refreshWeather(),
        verify: (_) {
          verify(() => weatherRepository.getWeather(weatherLocation)).called(1);
        },
      );

      blocTest<WeatherCubit, WeatherState>(
        'emits nothing when exception is thrown',
        setUp: () {
          when(
                () => weatherRepository.getWeather(any()),
          ).thenThrow(Exception('oops'));
        },
        build: () => weatherCubit,
        seed: () => WeatherState(
          status: WeatherStatus.success,
          weather: Weather(
            location: weatherLocation,
            temperature: Temperature(value: weatherTemperature),
            lastUpdated: DateTime(2020),
            condition: weatherCondition,
          ),
        ),
        act: (cubit) => cubit.refreshWeather(),
        expect: () => <WeatherState>[],
      );

      blocTest<WeatherCubit, WeatherState>(
        'emits updated weather (celsius)',
        build: () => weatherCubit,
        seed: () => WeatherState(
          status: WeatherStatus.success,
          weather: Weather(
            location: weatherLocation,
            temperature: Temperature(value: 0),
            lastUpdated: DateTime(2020),
            condition: weatherCondition,
          ),
        ),
        act: (cubit) => cubit.refreshWeather(),
        expect: () => <Matcher>[
          isA<WeatherState>()
              .having((w) => w.status, 'status', WeatherStatus.success)
              .having(
                (w) => w.weather,
            'weather',
            isA<Weather>()
                .having((w) => w.lastUpdated, 'lastUpdated', isNotNull)
                .having((w) => w.condition, 'condition', weatherCondition)
                .having(
                  (w) => w.temperature,
              'temperature',
              Temperature(value: weatherTemperature),
            )
                .having((w) => w.location, 'location', weatherLocation),
          ),
        ],
      );

      blocTest<WeatherCubit, WeatherState>(
        'emits updated weather (fahrenheit)',
        build: () => weatherCubit,
        seed: () => WeatherState(
          temperatureUnits: TemperatureUnits.fahrenheit,
          status: WeatherStatus.success,
          weather: Weather(
            location: weatherLocation,
            temperature: Temperature(value: 0),
            lastUpdated: DateTime(2020),
            condition: weatherCondition,
          ),
        ),
        act: (cubit) => cubit.refreshWeather(),
        expect: () => <Matcher>[
          isA<WeatherState>()
              .having((w) => w.status, 'status', WeatherStatus.success)
              .having(
                (w) => w.weather,
            'weather',
            isA<Weather>()
                .having((w) => w.lastUpdated, 'lastUpdated', isNotNull)
                .having((w) => w.condition, 'condition', weatherCondition)
                .having(
                  (w) => w.temperature,
              'temperature',
              Temperature(value: weatherTemperature.toFahrenheit()),
            )
                .having((w) => w.location, 'location', weatherLocation),
          ),
        ],
      );
    });

    group('toggleUnits', () {
      blocTest<WeatherCubit, WeatherState>(
        'emits updated units when status is not success',
        build: () => weatherCubit,
        act: (cubit) => cubit.toggleUnits(),
        expect: () => <WeatherState>[
          WeatherState(temperatureUnits: TemperatureUnits.fahrenheit),
        ],
      );

      blocTest<WeatherCubit, WeatherState>(
        'emits updated units and temperature '
            'when status is success (celsius)',
        build: () => weatherCubit,
        seed: () => WeatherState(
          status: WeatherStatus.success,
          temperatureUnits: TemperatureUnits.fahrenheit,
          weather: Weather(
            location: weatherLocation,
            temperature: Temperature(value: weatherTemperature),
            lastUpdated: DateTime(2020),
            condition: WeatherCondition.rainy,
          ),
        ),
        act: (cubit) => cubit.toggleUnits(),
        expect: () => <WeatherState>[
          WeatherState(
            status: WeatherStatus.success,
            weather: Weather(
              location: weatherLocation,
              temperature: Temperature(value: weatherTemperature.toCelsius()),
              lastUpdated: DateTime(2020),
              condition: WeatherCondition.rainy,
            ),
          ),
        ],
      );

      blocTest<WeatherCubit, WeatherState>(
        'emits updated units and temperature '
            'when status is success (fahrenheit)',
        build: () => weatherCubit,
        seed: () => WeatherState(
          status: WeatherStatus.success,
          weather: Weather(
            location: weatherLocation,
            temperature: Temperature(value: weatherTemperature),
            lastUpdated: DateTime(2020),
            condition: WeatherCondition.rainy,
          ),
        ),
        act: (cubit) => cubit.toggleUnits(),
        expect: () => <WeatherState>[
          WeatherState(
            status: WeatherStatus.success,
            temperatureUnits: TemperatureUnits.fahrenheit,
            weather: Weather(
              location: weatherLocation,
              temperature: Temperature(
                value: weatherTemperature.toFahrenheit(),
              ),
              lastUpdated: DateTime(2020),
              condition: WeatherCondition.rainy,
            ),
          ),
        ],
      );
    });
  });
}

extension on double {
  double toFahrenheit() => (this * 9 / 5) + 32;
  double toCelsius() => (this - 32) * 5 / 9;
}

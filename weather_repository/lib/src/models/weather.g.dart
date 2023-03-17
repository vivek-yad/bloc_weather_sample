// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherRepo _$WeatherFromJson(Map<String, dynamic> json) => WeatherRepo(
      location: json['location'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      condition: $enumDecode(_$WeatherConditionEnumMap, json['condition']),
    );

Map<String, dynamic> _$WeatherToJson(WeatherRepo instance) => <String, dynamic>{
      'location': instance.location,
      'temperature': instance.temperature,
      'condition': _$WeatherConditionEnumMap[instance.condition]!,
    };

const _$WeatherConditionEnumMap = {
  WeatherCondition.clear: 'clear',
  WeatherCondition.rainy: 'rainy',
  WeatherCondition.cloudy: 'cloudy',
  WeatherCondition.snowy: 'snowy',
  WeatherCondition.unknown: 'unknown',
};

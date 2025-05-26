import 'package:intl/intl.dart';

// Помощна функция за конвертиране на икони
String getWeatherEmoji(String iconCode) {
  switch (iconCode.substring(0, 2)) {
    case '01': return '☀️'; // clear sky
    case '02': return '🌤️'; // few clouds
    case '03': return '☁️'; // scattered clouds
    case '04': return '☁️'; // broken clouds
    case '09': return '🌧️'; // shower rain
    case '10': return '🌦️'; // rain
    case '11': return '⛈️'; // thunderstorm
    case '13': return '❄️'; // snow
    case '50': return '🌫️'; // mist
    default: return '🤷';
  }
}

class CurrentWeather {
  final double temp;
  final String description;
  final String icon;

  CurrentWeather({required this.temp, required this.description, required this.icon});

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temp: (json['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: getWeatherEmoji(json['weather'][0]['icon'] ?? '01d'),
    );
  }
}

class HourlyForecast {
  final DateTime time;
  final double temp;
  final String icon;

  HourlyForecast({required this.time, required this.temp, required this.icon});

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      temp: (json['temp'] as num).toDouble(),
      icon: getWeatherEmoji(json['weather'][0]['icon'] ?? '01d'),
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String icon;
  final String description;

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.icon,
    required this.description,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      minTemp: (json['temp']['min'] as num).toDouble(),
      maxTemp: (json['temp']['max'] as num).toDouble(),
      icon: getWeatherEmoji(json['weather'][0]['icon'] ?? '01d'),
      description: json['weather'][0]['description'] ?? '',
    );
  }
}

class FullWeatherForecast {
  final String cityName;
  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  FullWeatherForecast({
    required this.cityName,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  factory FullWeatherForecast.fromJson(Map<String, dynamic> json) {
    final hourlyData = (json['hourly'] as List)
        .map((item) => HourlyForecast.fromJson(item))
        .toList();

    final dailyData = (json['daily'] as List)
        .map((item) => DailyForecast.fromJson(item))
        .toList();

    return FullWeatherForecast(
      cityName: json['timezone']?.toString().split('/').last.replaceAll('_', ' ') ?? 'Вашето място',
      current: CurrentWeather.fromJson(json['current']),
      hourly: hourlyData,
      daily: dailyData,
    );
  }
}
// lib/models/weather_model.dart
class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final String iconCode;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.iconCode,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'] ?? 'Неизвестен град',
      temperature: (json['main']['temp'] as num?)?.toDouble() ?? 0.0,
      description: json['weather'][0]['description'] ?? 'Няма описание',
      iconCode: json['weather'][0]['icon'] ?? '01d',
    );
  }

  // Помощна функция за получаване на емоджи икона
  String getWeatherEmoji() {
    switch (iconCode.substring(0, 2)) {
      case '01': // clear sky
        return '☀️';
      case '02': // few clouds
        return '🌤️';
      case '03': // scattered clouds
        return '☁️';
      case '04': // broken clouds
        return '☁️';
      case '09': // shower rain
        return '🌧️';
      case '10': // rain
        return '🌦️';
      case '11': // thunderstorm
        return '⛈️';
      case '13': // snow
        return '❄️';
      case '50': // mist
        return '🌫️';
      default:
        return '🤷';
    }
  }
}
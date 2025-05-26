import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peak_seeker/models/weather_model.dart';
import 'package:peak_seeker/models/weather_forecast_model.dart';
import 'package:peak_seeker/config.dart';

class WeatherService {
  final String _apiKey = '${Config.openWeatherApiKey}';
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String _oneCallUrl = 'https://api.openweathermap.org/data/3.0/onecall';

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Услугите за местоположение са изключени.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Правата за достъп до местоположението са отказани.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Правата за достъп до местоположението са отказани завинаги.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
  }

  Future<Weather> fetchWeather({GeoPoint? coordinates, String? cityName}) async {
    try {
      final String lang = 'bg';
      final String units = 'metric';
      String url;

      if (cityName != null && cityName.isNotEmpty) {
        url = '$_baseUrl?q=$cityName&appid=$_apiKey&units=$units&lang=$lang';
      } else if (coordinates != null) {
        url = '$_baseUrl?lat=${coordinates.latitude}&lon=${coordinates.longitude}&appid=$_apiKey&units=$units&lang=$lang';
      } else {
        Position position = await _getCurrentLocation();
        url = '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=$units&lang=$lang';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        String errorMessage = 'Грешка при извличане на времето: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody != null && errorBody['message'] != null) {
            errorMessage += ' - ${errorBody['message']}';
          }
        } catch (e) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Неуспешно зареждане на данни за времето: ${e.toString()}');
    }
  }

  Future<FullWeatherForecast> fetchFullForecast({GeoPoint? coordinates, String? cityName}) async {
    try {
      final String lang = 'bg';
      final String units = 'metric';
      final String exclude = 'minutely,alerts';
      String url;
      String displayCityName;

      if (cityName != null && cityName.isNotEmpty) {
        // Извличаме координати за града
        final response = await http.get(Uri.parse(
            '$_baseUrl?q=$cityName&appid=$_apiKey&units=$units&lang=$lang'));
        if (response.statusCode != 200) {
          throw Exception('Грешка при извличане на координати за града: ${response.statusCode}');
        }
        final coords = jsonDecode(response.body)['coord'];
        url = '$_oneCallUrl?lat=${coords['lat']}&lon=${coords['lon']}&exclude=$exclude&appid=$_apiKey&units=$units&lang=$lang';
        displayCityName = cityName;
      } else if (coordinates != null) {
        url = '$_oneCallUrl?lat=${coordinates.latitude}&lon=${coordinates.longitude}&exclude=$exclude&appid=$_apiKey&units=$units&lang=$lang';
        // Извличаме името на града от API за времето, за да го покажем
        final weatherResponse = await http.get(Uri.parse(
            '$_baseUrl?lat=${coordinates.latitude}&lon=${coordinates.longitude}&appid=$_apiKey&units=$units&lang=$lang'));
        if (weatherResponse.statusCode == 200) {
          displayCityName = jsonDecode(weatherResponse.body)['name'] ?? 'Вашето място';
        } else {
          displayCityName = 'Вашето място';
        }
      } else {
        Position position = await _getCurrentLocation();
        url = '$_oneCallUrl?lat=${position.latitude}&lon=${position.longitude}&exclude=$exclude&appid=$_apiKey&units=$units&lang=$lang';
        final weatherResponse = await http.get(Uri.parse(
            '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=$units&lang=$lang'));
        if (weatherResponse.statusCode == 200) {
          displayCityName = jsonDecode(weatherResponse.body)['name'] ?? 'Вашето място';
        } else {
          displayCityName = 'Вашето място';
        }
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return FullWeatherForecast(
          cityName: displayCityName, // Предаваме името на града директно
          current: CurrentWeather.fromJson(json['current']),
          hourly: (json['hourly'] as List)
              .map((item) => HourlyForecast.fromJson(item))
              .toList(),
          daily: (json['daily'] as List)
              .map((item) => DailyForecast.fromJson(item))
              .toList(),
        );
      } else {
        throw Exception('Грешка при извличане на прогнозата: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Неуспешно зареждане на данни: ${e.toString()}');
    }
  }
}
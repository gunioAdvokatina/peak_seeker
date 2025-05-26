import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peak_seeker/models/weather_forecast_model.dart';
import 'package:peak_seeker/services/weather_service.dart';
import 'package:peak_seeker/theme.dart';

class WeatherScreen extends StatefulWidget {
  final GeoPoint? coordinates; // За координатите на пътеката

  const WeatherScreen({super.key, this.coordinates});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<FullWeatherForecast> _forecastFuture;
  final TextEditingController _searchController = TextEditingController();
  String? _searchCity;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('bg_BG', null);
    _loadForecast();
  }

  void _loadForecast() {
    setState(() {
      _forecastFuture = WeatherService().fetchFullForecast(
        coordinates: widget.coordinates,
        cityName: _searchCity,
      );
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _searchCity = query;
        _loadForecast();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pastelGreen,
      appBar: AppBar(
        title: const Text('Прогноза за времето'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Търси град...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _performSearch,
                  tooltip: 'Търси',
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<FullWeatherForecast>(
              future: _forecastFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Грешка: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('Няма налични данни.'));
                }

                final forecast = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentWeather(forecast),
                    const SizedBox(height: 24),
                    _buildHourlyForecast(forecast.hourly),
                    const SizedBox(height: 24),
                    _buildDailyForecast(forecast.daily),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeather(FullWeatherForecast forecast) {
    return Center(
      child: Column(
        children: [
          Text(forecast.cityName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(forecast.current.icon, style: const TextStyle(fontSize: 80)),
          Text(
            '${forecast.current.temp.round()}°C',
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300),
          ),
          Text(
            toBeginningOfSentenceCase(forecast.current.description) ?? '',
            style: const TextStyle(fontSize: 20, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast(List<HourlyForecast> hourly) {
    final next24Hours = hourly.take(24).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Почасова прогноза', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: next24Hours.length,
            itemBuilder: (context, index) {
              final item = next24Hours[index];
              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(DateFormat('HH:mm').format(item.time), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(item.icon, style: const TextStyle(fontSize: 24)),
                    Text('${item.temp.round()}°', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecast(List<DailyForecast> daily) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Дневна прогноза', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daily.length,
          itemBuilder: (context, index) {
            final item = daily[index];
            return Card(
              color: AppColors.pastelGreenLight,
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        index == 0 ? 'Днес' : toBeginningOfSentenceCase(DateFormat('EEEE', 'bg_BG').format(item.date)) ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(item.icon, style: const TextStyle(fontSize: 22)),
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${item.minTemp.round()}° / ${item.maxTemp.round()}°',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
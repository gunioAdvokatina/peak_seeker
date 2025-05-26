// lib/screens/search_results_screen.dart

import 'package:flutter/material.dart';
import 'package:peak_seeker/models/trail.dart';
import 'package:peak_seeker/models/weather_model.dart';
import 'package:peak_seeker/screens/trail_detail_screen.dart';
import 'package:peak_seeker/screens/weather_screen.dart';
import 'package:peak_seeker/services/trail_service.dart';
import 'package:peak_seeker/services/weather_service.dart';
import 'package:peak_seeker/theme.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late Future<List<Trail>> _resultsFuture;
  final WeatherService _weatherService = WeatherService();
  Future<Weather>? _weatherFuture;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
    _resultsFuture = _fetchAndFilterResults();
  }

  void _loadWeatherData() {
    setState(() {
      _weatherFuture = _weatherService.fetchWeather();
    });
  }

  /// Извлича всички пътеки и ги филтрира на базата на заявката
  Future<List<Trail>> _fetchAndFilterResults() async {
    final allTrails = await TrailService().getTrails();
    final queryLower = widget.query.toLowerCase();

    final filtered = allTrails.where((trail) {
      final nameLower = trail.name.toLowerCase();
      final locationLower = trail.location.toLowerCase();
      return nameLower.contains(queryLower) || locationLower.contains(queryLower);
    }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pastelGreen,
      appBar: AppBar(
        title: Text('Резултати за "${widget.query}"'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeatherWidget(),
            const SizedBox(height: 16),
            const Text(
              'Намерени резултати:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: FutureBuilder<List<Trail>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Грешка: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Няма намерени резултати.'));
                  }

                  final results = snapshot.data!;
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final trail = results[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.landscape,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                          title: Text(trail.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${trail.length} км'),
                              Text(trail.location),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrailDetailScreen(trail: trail),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeatherScreen()),
        );
      },
      child: FutureBuilder<Weather>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pastelGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primaryGreen)),
                  SizedBox(width: 10),
                  Text('Зареждане на времето...', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pastelGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Грешка при зареждане на времето.',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasData) {
            final weather = snapshot.data!;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pastelGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${weather.getWeatherEmoji()} ${weather.temperature.round()}°C в ${weather.cityName}',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppColors.primaryGreen)
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
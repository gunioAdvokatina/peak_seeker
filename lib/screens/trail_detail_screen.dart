import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peak_seeker/models/trail.dart';
import 'package:peak_seeker/models/weather_model.dart';
import 'package:peak_seeker/services/weather_service.dart';
import 'package:peak_seeker/screens/weather_screen.dart';
import 'package:peak_seeker/screens/navigation_screen.dart';
import 'package:peak_seeker/theme.dart';

class TrailDetailScreen extends StatelessWidget {
  final Trail trail;

  const TrailDetailScreen({super.key, required this.trail});

  @override
  Widget build(BuildContext context) {
    final String description = trail.description ?? 'Няма описание';
    final bool isStartPointValid = trail.startPoint != null &&
        trail.startPoint!.latitude >= -90 &&
        trail.startPoint!.latitude <= 90 &&
        trail.startPoint!.longitude >= -180 &&
        trail.startPoint!.longitude < 180;

    return Scaffold(
      backgroundColor: AppColors.pastelGreen,
      appBar: AppBar(
        title: Text(trail.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(null),
              const SizedBox(height: 16),
              _buildWeatherWidget(context, WeatherService()),
              const SizedBox(height: 16),
              _buildInfoRow(
                context: context,
                icon: Icons.straighten,
                label: 'Дължина:',
                value: '${trail.length} км',
              ),
              _buildInfoRow(
                context: context,
                icon: Icons.location_on,
                label: 'Местоположение:',
                value: trail.location,
              ),
              _buildInfoRow(
                context: context,
                icon: Icons.trending_up,
                label: 'Трудност:',
                value: trail.difficulty,
              ),
              const SizedBox(height: 16),
              Text(
                'Описание:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_walk, color: Colors.white),
                label: const Text(
                  'Навигирай до пътеката',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isStartPointValid ? AppColors.primaryGreen : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isStartPointValid
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationScreen(
                        startPoint: trail.startPoint,
                        trailName: trail.name,
                      ),
                    ),
                  );
                }
                    : null,
              ),
              if (!isStartPointValid)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Няма валидна начална точка за навигация.',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherWidget(BuildContext context, WeatherService weatherService) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherScreen(coordinates: trail.startPoint),
          ),
        );
      },
      child: FutureBuilder<Weather>(
        future: weatherService.fetchWeather(coordinates: trail.startPoint),
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
                      size: 16, color: AppColors.primaryGreen),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildImageSection(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.pastelGreenLight,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _defaultImagePlaceholder();
          },
        ),
      );
    } else {
      return _defaultImagePlaceholder();
    }
  }

  Widget _defaultImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.pastelGreenLight.withOpacity(0.5)),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildInfoRow({required BuildContext context, required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black, fontStyle: FontStyle.italic),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
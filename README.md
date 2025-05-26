# PeakSeeker

Курсова работа по дисциплината Мобилни приложения. Peak Seeker е Flutter приложение за намиране и навигиране до туристически пътеки в България.

## Функционалности
- Показване на списък с екопътеки с дължина, трудност и местоположение.
- Филтриране на списъка по дадени параметри.
- Подбробен изглед за дадена екопътека с данни и навигация.
- Метереологичната обстановка в местоположението на устройството.
- Метереологичната обстановка в началната точка на пътеката.
- Навигация до избрана екопътека.
- Цялостна навигация до избран обект с Google Maps (пеша, с кола, обществен транспорт).

## Инсталация
1. Клонирайте репозиторито: `git clone https://github.com/gunioAdvokatina/peak_seeker.git`
2. Инсталирайте зависимости: `flutter pub get`
3. Добавете Google Maps API ключ в `lib/config.dart`.
4. Стартирайте: `flutter run`

## Зависимости
- `flutter`
- `google_maps_flutter`
- `geolocator`
- `cloud_firestore`
- `http`
- `google_places_flutter`

## Бележки
- Проектът изисква Open Weather API ключ.
- Проектът изисква Google Maps API ключ с активирани Places API, Directions API, Maps SDK за Android.
- Тестван на Android.

## Автор на реализацията
- Добромир Денчев

## Автор на дизайна
- Виктория Томова


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

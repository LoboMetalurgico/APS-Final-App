import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const EcoMobileApp());
}

class EcoMobileApp extends StatelessWidget {
  const EcoMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoMobile - Clima & IQAr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WeatherDashboard(),
    );
  }
}

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  final TextEditingController _controller = TextEditingController();
  final String apiUrl = 'https://api.apsfinal.facul.allonsve.com';
  bool loading = false;
  Map<String, dynamic>? weatherData;

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return null;
    }

    // Get current position with new LocationSettings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  String? errorMessage; // null = sem erro

  Future<void> fetchCityOrCoords() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    final city = _controller.text.trim();
    String queryParam = '';

    try {
      if (city.isEmpty) {
        final position = await getCurrentPosition();
        if (position == null) {
          setState(() {
            errorMessage = 'Não foi possível obter sua localização.';
            loading = false;
          });
          return;
        }
        queryParam = '?lat=${position.latitude}&lon=${position.longitude}';
      } else {
        queryParam = '?location=${Uri.encodeComponent(city)}';
      }

      final url = Uri.parse('$apiUrl/locationData$queryParam');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final iqar = {
          'valor': data['airQuality']['index'],
          'classificacao':
              '${data['airQuality']['category']} - Poluente Principal: ${data['airQuality']['mainPollutant']}',
          'cor': parseIQArColor(data['airQuality']['index']),
        };

        switch (data['condition']) {
          case 'Sun':
            data['condition'] = '☀️ Ensolarado';
            break;
          case 'Clear':
            data['condition'] = '🌞 Céu Limpo';
          case 'Rain':
            data['condition'] = '🌧️ Chuvoso';
            break;
          case 'Drizzle':
            data['condition'] = '🌦️ Garoa';
          case 'Clouds':
            data['condition'] = '☁️ Nublado';
            break;
          case 'Fog':
            data['condition'] = '🌫️ Neblina';
            break;
          default:
            data['condition'] = '❓ Desconhecido (${data['condition']})';
        }

        setState(() {
          weatherData = {
            'city': data['location'],
            'temperature': data['temperature'],
            'humidity': data['humidity'],
            'condition': data['condition'],
            'windSpeed': data['windSpeed'],
            'windDirection': data['windDirection'],
            'uvIndex': data['uvData']['uvi'],
            'iqar': iqar,
          };
          errorMessage = null;
          loading = false;
        });
      } else {
        setState(() {
          if (response.statusCode == 404) {
            errorMessage =
                'Dados climáticos não encontrados para esta localização.';
          } else {
            errorMessage =
                'Erro ao obter dados climáticos: ${response.statusCode}';
          }
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro: $e';
        loading = false;
      });
    }
  }

  Color parseIQArColor(int iqar) {
    Color cor;

    if (iqar <= 40) {
      cor = Colors.green;
    } else if (iqar <= 80) {
      cor = Colors.yellow[700]!;
    } else if (iqar <= 120) {
      cor = Colors.orange;
    } else if (iqar <= 200) {
      cor = Colors.red;
    } else {
      cor = Colors.purple;
    }

    return cor;
  }

  /// 🔹 Widget para o gráfico circular (gauge)
  Widget buildGauge({
    required double value,
    required String label,
    required Color color,
    double max = 100,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 40.0, right: 40.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 90, // Width of each circle
            height: 90, // Height of each circle
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 35,
                    sectionsSpace: 0,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: value,
                        color: color,
                        showTitle: false,
                        radius: 45,
                      ),
                      PieChartSectionData(
                        value: (max - value).clamp(0, max),
                        color: Colors.grey[300],
                        showTitle: false,
                        radius: 45,
                      ),
                    ],
                  ),
                ),
                // ✅ Center text overlay
                Text(
                  '${value.toStringAsFixed(0)}%', // Display percentage
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label, // Display label under each gauge
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weather = weatherData;

    return Scaffold(
      appBar: AppBar(title: const Text('EcoMobile - Clima & IQAr')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Input de cidade
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Digite o nome da cidade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loading ? null : fetchCityOrCoords,
              icon: const Icon(Icons.search),
              label: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Buscar'),
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // 🔹 Exibe dados se disponíveis
            if (weather != null)
              Expanded(
                child: ListView(
                  children: [
                    Center(
                      child: Text(
                        '${weather['city']} - ${weather['condition']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 🔹 Três gráficos principais (lado a lado)
                    Column(
                      children: [
                        // First Row - Left alignment
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .start, // Align first gauge to the left
                          children: [
                            buildGauge(
                              value: (weather['iqar']['valor'] / 4).clamp(
                                0,
                                100,
                              ),
                              label:
                                  'IQAR\n${weather['iqar']['classificacao']}',
                              color: weather['iqar']['cor'],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Space between rows
                        // Second Row - Right alignment
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .end, // Align second gauge to the right
                          children: [
                            buildGauge(
                              value: ((weather['uvIndex'] as num) / 11 * 100)
                                  .clamp(0, 100),
                              label: 'Índice UV',
                              color: Colors.deepOrange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Space between rows
                        // Third Row - Left alignment
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .start, // Align third gauge to the left
                          children: [
                            buildGauge(
                              value: (weather['humidity'] as num).toDouble(),
                              label: 'Umidade',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 🔹 Outras informações
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.thermostat, color: Colors.red),
                            Text(
                              '${(weather['temperature'] as num).toStringAsFixed(1)}°C',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Text('Temperatura'),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.air, color: Colors.blueGrey),
                            Text(
                              '${(weather['windSpeed'] as num).toStringAsFixed(1)} km/h',
                            ),
                            Text(
                              weather['windDirection'] != null
                                  ? 'Direção: ${weather['windDirection']}'
                                  : 'Sem direção',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

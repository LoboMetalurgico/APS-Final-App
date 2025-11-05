import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Painel Clima & IQAR',
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
  bool loading = false;
  Map<String, dynamic>? weatherData;

  /// 🔹 Simula uma chamada de API com delay
  Future<void> fetchMockData() async {
    final city = _controller.text.trim();
    if (city.isEmpty) return;

    setState(() => loading = true);

    await Future.delayed(const Duration(seconds: 1)); // simula delay da API
    final rand = Random();

    final mock = {
      'city': city,
      'temperature': 18 + rand.nextInt(15) + rand.nextDouble(),
      'humidity': 40 + rand.nextInt(60),
      'uvIndex': rand.nextDouble() * 12,
      'condition': [
        '☀️ Ensolarado',
        '🌧️ Chuvoso',
        '☁️ Nublado',
        '🌫️ Neblina',
      ][rand.nextInt(4)],
      'windSpeed': (rand.nextDouble() * 20) + 2,
      'windDirection': [
        'N',
        'NE',
        'E',
        'SE',
        'S',
        'SW',
        'W',
        'NW',
      ][rand.nextInt(8)],
      'airQuality': {
        'pm2_5': (rand.nextDouble() * 150).toStringAsFixed(1),
        'pm10': (rand.nextDouble() * 250).toStringAsFixed(1),
      },
    };

    final air = mock['airQuality'] as Map<String, dynamic>;
    final iqar = calcularIQAR(
      double.parse(air['pm2_5']),
      double.parse(air['pm10']),
    );

    setState(() {
      weatherData = {...mock, 'iqar': iqar};
      loading = false;
    });
  }

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

      final url = Uri.parse('http://localhost:3000/location$queryParam');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response data: $data');
        // TODO: update your weatherData here
      } else {
        setState(() {
          errorMessage = 'Erro na API: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }


  /// 🔹 Calcula o índice IQAR conforme tabela do MMA
  Map<String, dynamic> calcularIQAR(double pm25, double pm10) {
    double indicePM25, indicePM10;

    if (pm25 <= 15) {
      indicePM25 = 40;
    } else if (pm25 <= 50)
      indicePM25 = 80;
    else if (pm25 <= 75)
      indicePM25 = 120;
    else if (pm25 <= 125)
      indicePM25 = 200;
    else
      indicePM25 = 400;

    if (pm10 <= 45) {
      indicePM10 = 40;
    } else if (pm10 <= 100)
      indicePM10 = 80;
    else if (pm10 <= 150)
      indicePM10 = 120;
    else if (pm10 <= 250)
      indicePM10 = 200;
    else
      indicePM10 = 400;

    final iqar = max(indicePM25, indicePM10);

    String classificacao;
    Color cor;

    if (iqar <= 40) {
      classificacao = 'Boa';
      cor = Colors.green;
    } else if (iqar <= 80) {
      classificacao = 'Moderada';
      cor = Colors.yellow[700]!;
    } else if (iqar <= 120) {
      classificacao = 'Ruim';
      cor = Colors.orange;
    } else if (iqar <= 200) {
      classificacao = 'Muito Ruim';
      cor = Colors.red;
    } else {
      classificacao = 'Péssima';
      cor = Colors.purple;
    }

    return {'valor': iqar, 'classificacao': classificacao, 'cor': cor};
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
      appBar: AppBar(title: const Text('Painel Clima & IQAR')),
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
              onPressed: loading ? null : fetchMockData,
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
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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

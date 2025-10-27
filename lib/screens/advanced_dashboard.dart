import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';

class AdvancedDashboard extends StatefulWidget {
  const AdvancedDashboard({super.key});

  @override
  _AdvancedDashboardState createState() => _AdvancedDashboardState();
}

class _AdvancedDashboardState extends State<AdvancedDashboard> {
  DashboardStats _stats = DashboardStats(
    totalAppointments: 0,
    upcomingAppointments: 0,
    completedToday: 0,
    monthlyRevenue: 0,
    loyalCustomers: 0,
    satisfactionRate: 0,
    serviceDistribution: {},
    revenueTrend: [],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Avancé'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // KPI Principaux
            Row(
              children: [
                _buildKpiCard('RDV Aujourd\'hui',
                    _stats.completedToday.toString(), Colors.green),
                const SizedBox(width: 12),
                _buildKpiCard('Revenu Mois', '${_stats.monthlyRevenue} FCFA',
                    Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildKpiCard('Clients Fidèles',
                    _stats.loyalCustomers.toString(), Colors.orange),
                const SizedBox(width: 12),
                _buildKpiCard('Satisfaction', '${_stats.satisfactionRate}%',
                    Colors.purple),
              ],
            ),

            const SizedBox(height: 24),

            // Graphique de revenus simulé
            _buildRevenueChart(),

            const SizedBox(height: 24),

            // Distribution des services
            _buildServiceDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenus Mensuels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Graphique de revenus'),
                    Text('(Données simulées)',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services les Plus Demandés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._stats.serviceDistribution.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: entry.value / 100, // Simulation
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}%'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

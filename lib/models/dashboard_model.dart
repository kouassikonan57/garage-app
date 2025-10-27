class DashboardStats {
  final int totalAppointments;
  final int upcomingAppointments;
  final int completedToday;
  final double monthlyRevenue;
  final int loyalCustomers;
  final double satisfactionRate;
  final Map<String, int> serviceDistribution;
  final List<MonthlyRevenue> revenueTrend;

  DashboardStats({
    required this.totalAppointments,
    required this.upcomingAppointments,
    required this.completedToday,
    required this.monthlyRevenue,
    required this.loyalCustomers,
    required this.satisfactionRate,
    required this.serviceDistribution,
    required this.revenueTrend,
  });
}

class MonthlyRevenue {
  final String month;
  final double revenue;

  MonthlyRevenue({required this.month, required this.revenue});
}

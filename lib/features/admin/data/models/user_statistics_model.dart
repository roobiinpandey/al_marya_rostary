/// User statistics model for admin dashboard
class UserStatistics {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final Map<String, int> usersByRole;
  final Map<String, int> usersByRegistrationMonth;

  const UserStatistics({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.usersByRole,
    required this.usersByRegistrationMonth,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      inactiveUsers: json['inactiveUsers'] ?? 0,
      newUsersToday: json['newUsersToday'] ?? 0,
      newUsersThisWeek: json['newUsersThisWeek'] ?? 0,
      newUsersThisMonth: json['newUsersThisMonth'] ?? 0,
      usersByRole: Map<String, int>.from(json['usersByRole'] ?? {}),
      usersByRegistrationMonth: Map<String, int>.from(
        json['usersByRegistrationMonth'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': inactiveUsers,
      'newUsersToday': newUsersToday,
      'newUsersThisWeek': newUsersThisWeek,
      'newUsersThisMonth': newUsersThisMonth,
      'usersByRole': usersByRole,
      'usersByRegistrationMonth': usersByRegistrationMonth,
    };
  }

  // Helper methods
  double get activeUserPercentage =>
      totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0;
  double get inactiveUserPercentage =>
      totalUsers > 0 ? (inactiveUsers / totalUsers) * 100 : 0;

  String get mostCommonRole {
    if (usersByRole.isEmpty) return 'None';
    return usersByRole.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

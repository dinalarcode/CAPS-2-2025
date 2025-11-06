class UserProfileDraft {
  String? name;
  String? target;
  String? healthGoal;
  List<String> challenges = [];
  double? heightCm;
  double? weightKg;
  double? targetWeightKg;
  DateTime? birthDate;
  String? sex;
  String? activityLevel;
  List<String> allergies = [];
  int? eatFrequency;
  double? sleepHours;

  UserProfileDraft();

  UserProfileDraft copy() {
    final c = UserProfileDraft();
    c
      ..name = name
      ..target = target
      ..healthGoal = healthGoal
      ..challenges = List.of(challenges)
      ..heightCm = heightCm
      ..weightKg = weightKg
      ..targetWeightKg = targetWeightKg
      ..birthDate = birthDate
      ..sex = sex
      ..activityLevel = activityLevel
      ..allergies = List.of(allergies)
      ..eatFrequency = eatFrequency
      ..sleepHours = sleepHours;
    return c;
  }
}

/// Canonical membership-plan catalogue, shared by the Membership page and
/// the "Submit Payment Receipt" screen so both read the same durations,
/// prices, PlanIDs and feature lists.
class MembershipPlan {
  final int planId;
  final String duration;
  final int price;
  final List<String> features;

  const MembershipPlan({
    required this.planId,
    required this.duration,
    required this.price,
    required this.features,
  });
}

const List<String> _kStandardFeatures = [
  'Unlimited time',
  'Free Coach',
  'Free Drinking Water',
  'Clean Facility & Toilets',
];

const List<MembershipPlan> kMembershipPlans = [
  MembershipPlan(
      planId: 1, duration: '4 Months', price: 2400, features: _kStandardFeatures),
  MembershipPlan(
      planId: 2, duration: '5 Months', price: 2800, features: _kStandardFeatures),
  MembershipPlan(
      planId: 3, duration: '7 Months', price: 3500, features: _kStandardFeatures),
  MembershipPlan(
      planId: 4, duration: '1 Year', price: 4800, features: _kStandardFeatures),
];

/// Formats an integer peso amount with thousands separators, e.g. 4800 -> "4,800".
String formatPeso(int price) {
  final str = price.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i != 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return buffer.toString();
}

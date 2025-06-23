String generateRequestId() {
  final now = DateTime.now();
  final timestamp = now.millisecondsSinceEpoch.toString();
  final randomPart = (100000 + (now.microsecondsSinceEpoch % 900000))
      .toString();
  return '$timestamp-$randomPart';
}

import '../entities/season.dart';

abstract class AppIconService {
  Future<void> applySeason(Season season);
}

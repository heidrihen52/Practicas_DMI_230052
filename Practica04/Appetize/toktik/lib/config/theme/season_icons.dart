import '../../domain/entities/app_icon.dart';
import '../../domain/entities/season.dart';

class SeasonIcons {
  static String assetFor(Season season) => switch (appIconForSeason(season)) {
    AppIcon.normal => 'assets/icons/vdry_launcher.png',
    AppIcon.halloween => 'assets/icons/vdry-halloween.png',
    AppIcon.christmas => 'assets/icons/vdry-Christmas.png',
    AppIcon.valentines => 'assets/icons/vdry-valentines.png',
  };
}

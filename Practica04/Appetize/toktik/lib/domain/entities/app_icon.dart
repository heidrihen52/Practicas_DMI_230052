import 'season.dart';

enum AppIcon { normal, halloween, christmas, valentines }

AppIcon appIconForSeason(Season season) => switch (season) {
  Season.halloween => AppIcon.halloween,
  Season.christmas => AppIcon.christmas,
  Season.valentines => AppIcon.valentines,
  Season.normal => AppIcon.normal,
};

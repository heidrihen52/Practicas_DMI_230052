enum Season { normal, halloween, christmas, valentines }

Season seasonForDate(DateTime date) {
  if (date.month == 10) return Season.halloween;
  if (date.month == 12) return Season.christmas;
  if (date.month == 2 && date.day <= 14) return Season.valentines;
  return Season.normal;
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_providers.g.dart';

@riverpod
class BookingDate extends _$BookingDate {
  @override
  DateTime build() => DateTime.now();
  void update(DateTime date) => state = date;
}

@riverpod
class HomeTab extends _$HomeTab {
  @override
  int build() => 0;
  void setTab(int index) => state = index;
}

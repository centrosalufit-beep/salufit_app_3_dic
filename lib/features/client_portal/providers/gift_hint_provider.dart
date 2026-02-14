import 'package:flutter_riverpod/flutter_riverpod.dart';

class GiftHintState {
  const GiftHintState({
    this.isActive = false,
    this.suggestedCategory = '',
    this.message = '',
  });

  final bool isActive;
  final String suggestedCategory;
  final String message;
}

class GiftHintNotifier extends Notifier<GiftHintState> {
  @override
  GiftHintState build() => const GiftHintState();

  void activate(String category, String msg) => state =
      GiftHintState(isActive: true, suggestedCategory: category, message: msg);

  void clear() => state = const GiftHintState();
}

final giftHintProvider =
    NotifierProvider<GiftHintNotifier, GiftHintState>(GiftHintNotifier.new);

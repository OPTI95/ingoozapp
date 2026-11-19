import '../../domain/entities/waybill_quote.dart';

class WaybillQuoteModel extends WaybillQuote {
  const WaybillQuoteModel({
    required super.cost,
    required super.balance,
    required super.promoWaybillsLeft,
  });

  factory WaybillQuoteModel.fromJson(Map<String, dynamic> json) {
    return WaybillQuoteModel(
      cost: double.tryParse('${json['cost']}') ?? 0,
      balance: double.tryParse('${json['balance']}') ?? 0,
      promoWaybillsLeft: (json['promo_waybills_left'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppSettings {
  bool stopOrdering;
  double maximumOrderPrice;
  double minimumOrderPrice;
  double deliveryFeeUnderMaximumOrderPrice;
  AppSettings();
  Map<String, dynamic> toJson() {
    return {
      'stopOrdering': stopOrdering,
      'maximumOrderPrice': maximumOrderPrice,
      'minimumOrderPrice': minimumOrderPrice,
      'deliveryFeeUnderMaximumOrderPrice': deliveryFeeUnderMaximumOrderPrice
    };
  }

  AppSettings.fromJson(Map<String, dynamic> json) {
    stopOrdering = json['stopOrdering'] as bool;
    maximumOrderPrice = (json['maximumOrderPrice'] as num)?.toDouble();
    minimumOrderPrice = (json['minimumOrderPrice'] as num)?.toDouble();
    deliveryFeeUnderMaximumOrderPrice =
        (json['deliveryFeeUnderMaximumOrderPrice'] as num)?.toDouble();
  }
}

class CreatePaypalOrderResult {
  final String approveUrl;
  final String providerOrderId;

  CreatePaypalOrderResult({
    required this.approveUrl,
    required this.providerOrderId,
  });

  factory CreatePaypalOrderResult.fromJson(Map<String, dynamic> json) {
    return CreatePaypalOrderResult(
      approveUrl: json['approveUrl'] as String,
      providerOrderId: json['providerOrderId'] as String,
    );
  }
}

/// Shape backend returns for PaymentResponse — keep fields optional & forgiving.
class PaymentResponse {
  final int? id;
  final int? orderId;
  final double? amount;
  final String? currency;
  final String? status; // "Pending", "Completed", "Failed"
  final String? provider;
  final String? providerOrderId;
  final String? providerCaptureId;
  final DateTime? paidAt;

  PaymentResponse({
    this.id,
    this.orderId,
    this.amount,
    this.currency,
    this.status,
    this.provider,
    this.providerOrderId,
    this.providerCaptureId,
    this.paidAt,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      return double.tryParse(v.toString());
    }

    return PaymentResponse(
      id: json['id'] as int?,
      orderId: json['orderId'] as int?,
      amount: parseDouble(json['amount']),
      currency: json['currency'] as String?,
      status: json['status']?.toString(),
      provider: json['provider']?.toString(),
      providerOrderId: json['providerOrderId']?.toString(),
      providerCaptureId: json['providerCaptureId']?.toString(),
      paidAt: parseDate(json['paidAt']),
    );
  }
}

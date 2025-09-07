import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../providers/payment_provider.dart';
import '../models/payment_models.dart';

class PaypalApproveScreen extends StatefulWidget {
  final String approveUrl;
  final String providerOrderId;

  const PaypalApproveScreen({
    super.key,
    required this.approveUrl,
    required this.providerOrderId,
  });

  @override
  State<PaypalApproveScreen> createState() => _PaypalApproveScreenState();
}

class _PaypalApproveScreenState extends State<PaypalApproveScreen> {
  late final WebViewController _ctrl;
  bool _loading = true;
  bool _done = false; // guard to avoid multiple captures

  @override
  void initState() {
    super.initState();

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _log('onPageStarted', url);
            setState(() => _loading = true);
          },
          onPageFinished: (url) {
            _log('onPageFinished', url);
            setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            _log('onWebResourceError', '${err.errorCode} ${err.description}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Web error: ${err.description}')),
              );
            }
          },
          onNavigationRequest: (req) {
            final url = req.url;
            _log('onNavigationRequest', url);

            // Deep-links from backend:
            //   restoranow://paypal-return?token=...
            //   restoranow://paypal-cancel?token=...
            if (url.startsWith('restoranow://paypal-return') ||
                url.startsWith('restoranow://paypal-cancel')) {
              if (_done) return NavigationDecision.prevent;
              _done = true;

              final uri = Uri.parse(url);
              final token = uri.queryParameters['token'];
              _log(
                'deeplink',
                'token=$token payer=${uri.queryParameters['PayerID']}',
              );

              // Cancel or missing token -> canceled
              if (url.startsWith('restoranow://paypal-cancel') ||
                  token == null ||
                  token.isEmpty) {
                Navigator.of(context).pop<PaymentResponse?>(null);
              } else {
                _capture(token);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approveUrl));
  }

  Future<void> _capture(String token) async {
    try {
      setState(() => _loading = true);
      final pr = context.read<PaymentProvider>();
      _log('CAPTURE', 'start token=$token');
      final result = await pr.capturePaypalOrder(token);
      _log(
        'CAPTURE',
        'done status=${result.status} amount=${result.amount} ${result.currency}',
      );
      if (!mounted) return;
      Navigator.of(context).pop<PaymentResponse?>(result);
    } catch (e) {
      _log('CAPTURE', 'error $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      Navigator.of(context).pop<PaymentResponse?>(null);
    }
  }

  void _log(String tag, String msg) {
    const debug = true; // flip to false to silence logs
    if (debug) debugPrint('WV [$tag] -> $msg');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop && mounted) {
          Navigator.of(context).pop<PaymentResponse?>(null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PayPal Approval'),
          actions: [
            IconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close),
              onPressed: () =>
                  Navigator.of(context).pop<PaymentResponse?>(null),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _ctrl),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }
}

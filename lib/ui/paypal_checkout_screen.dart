import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Hosts PayPal's own approval page (the `approve_url` returned by
/// `POST /shop/orders`) inside a regular (visible) WebView, and watches
/// navigation for the return/cancel URLs configured server-side in
/// `PayPalService::createOrder` to know when the user is done — without
/// ever actually loading those URLs. Pops with `true` (approved) or
/// `false` (cancelled/closed).
class PaypalCheckoutScreen extends StatefulWidget {
  const PaypalCheckoutScreen({super.key, required this.approveUrl});

  final String approveUrl;

  @override
  State<PaypalCheckoutScreen> createState() => _PaypalCheckoutScreenState();
}

class _PaypalCheckoutScreenState extends State<PaypalCheckoutScreen> {
  static const _returnPrefix = 'https://disfracescharos.com/api_turret/paypal/return';
  static const _cancelPrefix = 'https://disfracescharos.com/api_turret/paypal/cancel';

  bool _loading = true;
  bool _finished = false;

  void _finish(bool approved) {
    if (_finished) return;
    _finished = true;
    Navigator.of(context).pop(approved);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finish(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF3A2A1C),
          foregroundColor: Colors.white,
          title: const Text('PayPal'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _finish(false),
          ),
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.approveUrl)),
              shouldOverrideUrlLoading: (controller, action) async {
                final url = action.request.url?.toString() ?? '';
                if (url.startsWith(_returnPrefix)) {
                  _finish(true);
                  return NavigationActionPolicy.CANCEL;
                }
                if (url.startsWith(_cancelPrefix)) {
                  _finish(false);
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) {
                if (mounted) setState(() => _loading = false);
              },
            ),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFCB7B2A))),
          ],
        ),
      ),
    );
  }
}

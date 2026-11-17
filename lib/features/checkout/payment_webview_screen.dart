import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Hosts the SSLCommerz payment page. The backend redirects the buyer to
/// `/payments/sslcommerz/result/{success|fail|cancel}` when finished; we watch
/// for that URL and pop. The caller must still verify the result with the
/// server — this screen's result is only a hint.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.url});
  final String url;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _done = false;

  static final _resultPath = RegExp(r'/payments/sslcommerz/result/(success|fail|cancel)');

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final m = _resultPath.firstMatch(request.url);
            if (m != null) {
              _finish(m.group(1) == 'success');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );
    if (widget.url.isNotEmpty) _controller.loadRequest(Uri.parse(widget.url));
  }

  void _finish(bool success) {
    if (_done || !mounted) return;
    _done = true;
    context.pop(success);
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel payment?'),
        content: const Text('Your order will not be placed if you leave now.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    if (leave == true) _finish(false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure payment'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

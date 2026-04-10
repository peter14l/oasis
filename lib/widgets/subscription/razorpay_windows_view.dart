import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:oasis/services/pricing_service.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/core/config/app_config.dart';

class RazorpayWindowsView extends StatefulWidget {
  final PricingPlan plan;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const RazorpayWindowsView({
    super.key,
    required this.plan,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<RazorpayWindowsView> createState() => _RazorpayWindowsViewState();
}

class _RazorpayWindowsViewState extends State<RazorpayWindowsView> {
  final _controller = WebviewController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  Future<void> _initWebview() async {
    try {
      await _controller.initialize();
      _controller.url.listen((url) {
        debugPrint('Webview URL: $url');
        if (url.contains('success')) {
          widget.onSuccess();
        } else if (url.contains('cancel') || url.contains('error')) {
          widget.onCancel();
        }
      });

      final userId = SupabaseService().client.auth.currentUser?.id;
      final checkoutUrl = AppConfig.getWebUrl(
        '/checkout?user_id=$userId&plan=${widget.plan.name}&currency=${widget.plan.currency.name.toUpperCase()}&platform=windows',
      );

      await _controller.loadUrl(checkoutUrl);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Webview initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Webview(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

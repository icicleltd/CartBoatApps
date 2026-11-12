import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/toast.dart';
import '../auth/auth_widgets.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const _length = 6;
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _cooldown = 60;
  bool _verifying = false;
  bool _verified = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) t.cancel();
      setState(() => _cooldown = (_cooldown - 1).clamp(0, 60));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != _length || _verifying) return;
    setState(() => _verifying = true);
    try {
      await ref.read(authRepositoryProvider).verifySellerOtp(email: widget.email, otp: _code.text);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _verifying = false;
        _verified = true;
      });
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _verifying = false;
        _shake++;
        _code.clear();
      });
      AppToast.error(context, e);
    }
  }

  Future<void> _resend() async {
    try {
      final msg = await ref.read(authRepositoryProvider).resendOtp(widget.email);
      if (!mounted) return;
      _startCooldown();
      AppToast.success(context, msg);
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (_verified) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.page),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(color: p.successSoft, shape: BoxShape.circle),
                  child: AppIcon(PhosphorIconsFill.sealCheck, color: p.success, size: 64),
                ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 26),
                Text(
                  'Your shop is ready!',
                  style: context.text.headlineMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, curve: Motion.emphasized),
                const SizedBox(height: 10),
                Text(
                  'Sign in with ${widget.email} to start listing products. Manage inventory, orders and POS sales from the seller dashboard.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: p.muted),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, curve: Motion.emphasized),
                const Spacer(),
                PrimaryButton(
                  label: 'Sign in',
                  onPressed: () => context.go(Paths.login),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
    }

    return AuthScaffold(
      title: 'Check your inbox',
      subtitle: 'Enter the 6-digit code we sent to ${widget.email.isEmpty ? 'your email' : widget.email}.',
      headerIcon: PhosphorIconsDuotone.envelopeOpen,
      closeIcon: PhosphorIconsBold.arrowLeft,
      onClose: () => context.popOrHome(),
      children: [
        _CodeBoxes(
          controller: _code,
          focus: _focus,
          length: _length,
          shake: _shake,
          onChanged: (_) {
            setState(() {});
            if (_code.text.length == _length) _verify();
          },
        ),
        const SizedBox(height: 26),
        PrimaryButton(
          label: 'Verify & open shop',
          loading: _verifying,
          onPressed: _code.text.length == _length ? _verify : null,
        ),
        const SizedBox(height: 20),
        Center(
          child: AnimatedSwitcher(
            duration: Motion.medium,
            child: _cooldown > 0
                ? Text(
                    'Resend code in 0:${_cooldown.toString().padLeft(2, '0')}',
                    key: const ValueKey('wait'),
                    style: context.text.bodyMedium?.copyWith(color: p.muted),
                  )
                : Pressable(
                    key: const ValueKey('resend'),
                    onTap: _resend,
                    child: Text('Resend code', style: context.text.labelLarge?.copyWith(color: p.primary)),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Six boxes backed by one invisible field — supports paste and SMS/email
/// one-time-code autofill.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focus,
    required this.length,
    required this.shake,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final int length;
  final int shake;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = controller.text;
    final boxes = Row(
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: Motion.fast,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: i == text.length && focus.hasFocus
                      ? p.primary
                      : (i < text.length ? p.primary.withValues(alpha: 0.4) : p.line),
                  width: i == text.length && focus.hasFocus ? 2 : 1.4,
                ),
              ),
              child: AnimatedSwitcher(
                duration: Motion.fast,
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Text(
                  i < text.length ? text[i] : '',
                  key: ValueKey('$i-${i < text.length ? text[i] : ''}'),
                  style: context.text.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            ),
          ),
        ],
      ],
    );
    return GestureDetector(
      onTap: () => focus.requestFocus(),
      child: Stack(
        children: [
          boxes.animate(key: ValueKey(shake), target: shake > 0 ? 1 : 0).shakeX(hz: 5, amount: 6, duration: 420.ms),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: length,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
                decoration: const InputDecoration(counterText: '', border: InputBorder.none, filled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/toast.dart';
import '../../state/auth_controller.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _close() => context.canPop() ? context.pop() : context.go(Paths.home);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await ref.read(authControllerProvider.notifier).login(_email.text, _password.text);
      if (!mounted) return;
      AppToast.success(context, user == null ? 'Signed in' : 'Welcome back, ${user.firstName}!');
      _close();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to track orders, sync your details and check out faster.',
      onClose: _close,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                AuthField(
                  controller: _email,
                  label: 'Email',
                  icon: PhosphorIconsRegular.envelopeSimple,
                  keyboard: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email, AutofillHints.username],
                  validator: emailValidator,
                ),
                AuthField(
                  controller: _password,
                  label: 'Password',
                  icon: PhosphorIconsRegular.lockSimple,
                  password: true,
                  autofill: const [AutofillHints.password],
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Sign in', loading: _loading, onPressed: _submit),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('New to CartBoat? ', style: context.text.bodyMedium),
            Pressable(
              onTap: () => context.pushReplacement(Paths.register),
              child: Text('Create an account', style: context.text.labelLarge?.copyWith(color: p.primary)),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Pressable(
          onTap: () => context.push(Paths.becomeSeller),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                AppIcon(PhosphorIconsDuotone.storefront, color: p.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Have something to sell?', style: context.text.titleSmall),
                      Text('Open your shop on CartBoat', style: context.text.bodySmall),
                    ],
                  ),
                ),
                AppIcon(PhosphorIconsBold.arrowRight, color: p.accentInk, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

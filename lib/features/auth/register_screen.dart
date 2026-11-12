import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/toast.dart';
import '../../state/auth_controller.dart';
import 'auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agreed = false;
  bool _loading = false;
  bool _agreeError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _form.currentState!.validate();
    setState(() => _agreeError = !_agreed);
    if (!valid || !_agreed) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(name: _name.text, email: _email.text, password: _password.text);
      if (!mounted) return;
      AppToast.success(context, 'Welcome aboard, ${_name.text.trim().split(' ').first}!');
      context.go(Paths.account);
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
      title: 'Create your account',
      subtitle: 'Join CartBoat to save your details, follow every order and get the best deals first.',
      closeIcon: PhosphorIconsBold.arrowLeft,
      onClose: () => context.canPop() ? context.pop() : context.go(Paths.home),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                AuthField(
                  controller: _name,
                  label: 'Full name',
                  icon: PhosphorIconsRegular.user,
                  autofill: const [AutofillHints.name],
                  capitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Tell us your name' : null,
                ),
                AuthField(
                  controller: _email,
                  label: 'Email',
                  icon: PhosphorIconsRegular.envelopeSimple,
                  keyboard: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                  validator: emailValidator,
                ),
                AuthField(
                  controller: _password,
                  label: 'Password',
                  icon: PhosphorIconsRegular.lockSimple,
                  password: true,
                  autofill: const [AutofillHints.newPassword],
                  action: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  validator: strongPasswordValidator,
                ),
                PasswordStrength(password: _password.text),
              ],
            ),
          ),
        ),
        Pressable(
          onTap: () => setState(() {
            _agreed = !_agreed;
            if (_agreed) _agreeError = false;
          }),
          child: AnimatedContainer(
            duration: Motion.medium,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _agreeError ? p.dangerSoft : p.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: Motion.fast,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _agreed ? p.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _agreed ? p.primary : (_agreeError ? p.danger : p.muted), width: 1.6),
                  ),
                  child: _agreed ? AppIcon(PhosphorIconsBold.check, size: 14, color: p.onPrimary) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I agree to CartBoat\'s Terms of Service and Privacy Policy.',
                    style: context.text.bodySmall?.copyWith(color: _agreeError ? p.danger : p.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Create account', loading: _loading, onPressed: _submit),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Already have an account? ', style: context.text.bodyMedium),
            Pressable(
              onTap: () => context.pushReplacement(Paths.login),
              child: Text('Sign in', style: context.text.labelLarge?.copyWith(color: p.primary)),
            ),
          ],
        ),
      ],
    );
  }
}

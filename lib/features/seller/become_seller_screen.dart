import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/toast.dart';
import '../auth/auth_widgets.dart';

class BecomeSellerScreen extends ConsumerStatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  ConsumerState<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends ConsumerState<BecomeSellerScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _shop = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _shop, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _loading = true);
    try {
      final msg = await ref
          .read(authRepositoryProvider)
          .becomeSeller(
            name: _name.text.trim(),
            email: _email.text.trim(),
            shopName: _shop.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.success(context, msg);
      context.push(Paths.verifyOtp, extra: _email.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget perk(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall?.copyWith(color: Colors.white)),
                Text(body, style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
        ],
      ),
    );

    return AuthScaffold(
      title: 'Open your shop',
      subtitle: 'Sell to shoppers across CartBoat. Setup takes about two minutes.',
      headerIcon: PhosphorIconsDuotone.storefront,
      closeIcon: PhosphorIconsBold.arrowLeft,
      onClose: () => context.popOrHome(),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [BrandColors.tide600, BrandColors.tide900],
            ),
          ),
          child: Column(
            children: [
              perk(
                PhosphorIconsBold.usersThree,
                'Reach more customers',
                'Your products appear alongside every shop on CartBoat.',
              ),
              perk(
                PhosphorIconsBold.package,
                'Inventory & POS built in',
                'Track stock, variants and in-store sales in one place.',
              ),
              perk(
                PhosphorIconsBold.receipt,
                'Orders routed to you',
                'Every order for your items lands straight in your dashboard.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text('Shop details', style: context.text.titleMedium),
        const SizedBox(height: 14),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                AuthField(
                  controller: _name,
                  label: 'Your name',
                  icon: PhosphorIconsRegular.user,
                  capitalization: TextCapitalization.words,
                  autofill: const [AutofillHints.name],
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Name is required' : null,
                ),
                AuthField(
                  controller: _email,
                  label: 'Business email',
                  icon: PhosphorIconsRegular.envelopeSimple,
                  keyboard: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                  validator: emailValidator,
                ),
                AuthField(
                  controller: _shop,
                  label: 'Shop name',
                  icon: PhosphorIconsRegular.storefront,
                  capitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Give your shop a name' : null,
                ),
                AuthField(
                  controller: _password,
                  label: 'Password',
                  icon: PhosphorIconsRegular.lockSimple,
                  password: true,
                  autofill: const [AutofillHints.newPassword],
                  action: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
                ),
                PasswordStrength(password: _password.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        PrimaryButton(
          label: 'Send verification code',
          icon: PhosphorIconsBold.paperPlaneTilt,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 14),
        Text(
          'We\'ll email a 6-digit code to confirm it\'s you.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: p.muted),
        ),
      ],
    );
  }
}

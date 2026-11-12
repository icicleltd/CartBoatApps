import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../../core/router/routes.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../shared/widgets/animated_money.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/toast.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/preferences.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _recipient = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _zip = TextEditingController();
  final _note = TextEditingController();

  bool _sameAsContact = true;
  String _payment = PaymentMethodOption.all.first.value;
  bool _placing = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final last = ref.read(lastCheckoutProvider);
    final user = ref.read(currentUserProvider);
    _name.text = (last['name'] as String?) ?? user?.name ?? '';
    _phone.text = (last['phone'] as String?) ?? user?.phone ?? '';
    _email.text = (last['email'] as String?) ?? user?.email ?? '';
    _address.text = (last['address'] as String?) ?? '';
    _city.text = (last['city'] as String?) ?? '';
    _zip.text = (last['zip'] as String?) ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _recipient, _recipientPhone, _address, _city, _zip, _note]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  BuildContext? _firstInvalid(BuildContext? root) {
    BuildContext? found;
    void visit(Element e) {
      if (found != null) return;
      if (e is StatefulElement && e.state is FormFieldState && (e.state as FormFieldState).hasError) {
        found = e;
        return;
      }
      e.visitChildren(visit);
    }

    (root as Element?)?.visitChildren(visit);
    return found;
  }

  String? _required(String? v, String label) => (v == null || v.trim().isEmpty) ? '$label is required' : null;

  String? _phoneRule(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) return 'Enter a valid phone number';
    return null;
  }

  String? _emailRule(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      HapticFeedback.heavyImpact();
      // Bring the first invalid field into view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final field = _firstInvalid(_form.currentContext);
        if (field != null) {
          Scrollable.ensureVisible(field, duration: Motion.slow, curve: Motion.emphasized, alignment: 0.2);
        }
      });
      AppToast.show(
        context,
        message: 'Please fix the highlighted fields',
        icon: PhosphorIconsFill.warningCircle,
        tone: ToastTone.error,
        bottomOffset: 110,
      );
      return;
    }
    final summary = ref.read(cartSummaryProvider);
    if (summary.groups.isEmpty) return;

    setState(() => _placing = true);
    final user = ref.read(currentUserProvider);
    final shipping = {
      'name': _sameAsContact ? _name.text.trim() : _recipient.text.trim(),
      'phone': _sameAsContact ? _phone.text.trim() : _recipientPhone.text.trim(),
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'zip': _zip.text.trim().isEmpty ? null : _zip.text.trim(),
    };
    final repo = ref.read(orderRepositoryProvider);

    // One order per seller, exactly like the web storefront.
    final results = await Future.wait(
      summary.groups.map((g) async {
        try {
          final placed = await repo.create({
            'sellerId': g.sellerId,
            'userId': user?.id,
            'phone': _phone.text.trim(),
            'name': _name.text.trim(),
            'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
            'items': [
              for (final i in g.items) {'variant_id': i.variantId, 'quantity': i.quantity},
            ],
            'shippingAddress': shipping,
            'discountAmount': 0,
            'taxAmount': 0,
            'shippingCharge': Env.shippingPerSeller,
            'paidAmount': 0,
            'paymentMethod': _payment,
            'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
          });
          return (group: g, order: placed, error: null as ApiException?);
        } catch (e) {
          return (group: g, order: null as PlacedOrder?, error: ApiException.from(e));
        }
      }),
    );

    if (!mounted) return;
    final ok = results.where((r) => r.order != null).toList();
    final failed = results.where((r) => r.order == null).toList();

    if (ok.isEmpty) {
      setState(() => _placing = false);
      HapticFeedback.heavyImpact();
      AppToast.error(context, failed.first.error ?? 'Could not place your order. Please try again.');
      return;
    }

    ref.read(prefsProvider).writeJsonList(PrefKeys.lastCheckout, [
      {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'zip': _zip.text.trim(),
      },
    ]);
    ref.invalidate(lastCheckoutProvider);

    final cart = ref.read(cartProvider.notifier);
    for (final r in ok) {
      for (final i in r.group.items) {
        cart.remove(i.variantId);
      }
    }
    HapticFeedback.heavyImpact();
    if (failed.isNotEmpty) {
      AppToast.error(
        context,
        '${ok.length} of ${results.length} orders placed. ${failed.first.error?.message ?? ''} The rest are still in your cart.',
      );
    }
    context.go(Paths.orderSuccess, extra: ok.map((r) => r.order!).toList());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final summary = ref.watch(cartSummaryProvider);

    if (summary.groups.isEmpty && !_placing) {
      return Scaffold(
        appBar: _appBar(context),
        body: EmptyState(
          title: 'Nothing to check out',
          message: 'Your cart is empty. Add a few things and come back.',
          actionLabel: 'Browse products',
          onAction: () => context.go(Paths.home),
        ),
      );
    }

    Widget section(int i, String title, IconData icon, Widget child) =>
        Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: SurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(10)),
                          child: AppIcon(icon, size: 17, color: p.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(title, style: context.text.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(delay: (60 * i).ms, duration: 360.ms)
            .slideY(begin: 0.05, delay: (60 * i).ms, duration: 480.ms, curve: Motion.emphasized);

    return Scaffold(
      appBar: _appBar(context),
      body: Form(
        key: _form,
        autovalidateMode: _autovalidate,
        // Not a lazy ListView: every field must stay mounted so validation
        // covers sections that are scrolled off-screen.
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              section(
                0,
                'Contact',
                PhosphorIconsBold.user,
                Column(
                  children: [
                    _Field(
                      controller: _name,
                      label: 'Full name',
                      icon: PhosphorIconsRegular.user,
                      validator: (v) => _required(v, 'Name'),
                      textCapitalization: TextCapitalization.words,
                      autofill: const [AutofillHints.name],
                    ),
                    _Field(
                      controller: _phone,
                      label: 'Phone',
                      icon: PhosphorIconsRegular.phone,
                      validator: _phoneRule,
                      keyboard: TextInputType.phone,
                      autofill: const [AutofillHints.telephoneNumber],
                      hint: '+8801XXXXXXXXX',
                    ),
                    _Field(
                      controller: _email,
                      label: 'Email (optional)',
                      icon: PhosphorIconsRegular.envelopeSimple,
                      validator: _emailRule,
                      keyboard: TextInputType.emailAddress,
                      autofill: const [AutofillHints.email],
                      last: true,
                    ),
                  ],
                ),
              ),
              section(
                1,
                'Delivery address',
                PhosphorIconsBold.mapPin,
                Column(
                  children: [
                    _ToggleRow(
                      title: 'Deliver to me',
                      subtitle: 'Use my contact details for the recipient',
                      value: _sameAsContact,
                      onChanged: (v) => setState(() => _sameAsContact = v),
                    ),
                    AnimatedSize(
                      duration: Motion.medium,
                      curve: Motion.emphasized,
                      alignment: Alignment.topCenter,
                      child: _sameAsContact
                          ? const SizedBox(width: double.infinity, height: 14)
                          : Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Column(
                                children: [
                                  _Field(
                                    controller: _recipient,
                                    label: 'Recipient name',
                                    icon: PhosphorIconsRegular.userCircle,
                                    validator: (v) => _required(v, 'Recipient name'),
                                    textCapitalization: TextCapitalization.words,
                                  ),
                                  _Field(
                                    controller: _recipientPhone,
                                    label: 'Recipient phone',
                                    icon: PhosphorIconsRegular.phone,
                                    validator: _phoneRule,
                                    keyboard: TextInputType.phone,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    _Field(
                      controller: _address,
                      label: 'Street address',
                      icon: PhosphorIconsRegular.house,
                      validator: (v) => _required(v, 'Address'),
                      maxLines: 2,
                      autofill: const [AutofillHints.fullStreetAddress],
                      hint: 'House, road, area',
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _Field(
                            controller: _city,
                            label: 'City',
                            icon: PhosphorIconsRegular.buildings,
                            validator: (v) => _required(v, 'City'),
                            textCapitalization: TextCapitalization.words,
                            autofill: const [AutofillHints.addressCity],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _Field(
                            controller: _zip,
                            label: 'ZIP',
                            keyboard: TextInputType.number,
                            autofill: const [AutofillHints.postalCode],
                            last: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              section(
                2,
                'Payment',
                PhosphorIconsBold.wallet,
                Column(
                  children: [
                    for (final m in PaymentMethodOption.all)
                      _PaymentTile(
                        option: m,
                        selected: _payment == m.value,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _payment = m.value);
                        },
                      ),
                  ],
                ),
              ),
              section(
                3,
                'Order note',
                PhosphorIconsBold.notePencil,
                _Field(controller: _note, label: 'Anything the shop should know? (optional)', maxLines: 3, last: true),
              ),
              section(4, 'Review', PhosphorIconsBold.receipt, _Review(summary: summary)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(PhosphorIconsFill.shieldCheck, size: 15, color: p.muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Your details are only shared with the shops you buy from',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(Gap.page, 12, Gap.page, MediaQuery.paddingOf(context).bottom + 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To pay', style: context.text.bodySmall),
                  AnimatedMoney(summary.total, style: context.text.titleLarge),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: summary.groups.length > 1 ? 'Place ${summary.groups.length} orders' : 'Place order',
                loading: _placing,
                onPressed: _placeOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    final p = context.palette;
    return AppBar(
      leadingWidth: 64,
      leading: Center(
        child: CircleIconButton(
          icon: PhosphorIconsBold.arrowLeft,
          size: 40,
          iconSize: 18,
          onTap: () => context.popOrHome(),
        ),
      ),
      title: const Text('Checkout'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Pill('Secure', icon: PhosphorIconsFill.lockSimple, color: p.success, background: p.successSoft),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.icon,
    this.validator,
    this.keyboard,
    this.maxLines = 1,
    this.hint,
    this.textCapitalization = TextCapitalization.none,
    this.autofill,
    this.last = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final int maxLines;
  final String? hint;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofill;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: maxLines > 1 ? TextInputType.multiline : keyboard,
        maxLines: maxLines,
        minLines: 1,
        textCapitalization: textCapitalization,
        autofillHints: autofill,
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        style: context.text.bodyLarge?.copyWith(color: context.palette.ink),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : AppIcon(icon, size: 20),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, required this.subtitle, required this.value, required this.onChanged});

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleSmall),
              Text(subtitle, style: context.text.bodySmall),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.option, required this.selected, required this.onTap});

  final PaymentMethodOption option;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (option.value) {
    'cash_on_delivery' => PhosphorIconsDuotone.money,
    'mobile_banking' => PhosphorIconsDuotone.deviceMobileCamera,
    'card' => PhosphorIconsDuotone.creditCard,
    _ => PhosphorIconsDuotone.globe,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? p.primarySoft : p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? p.primary : p.line, width: selected ? 1.8 : 1.2),
        ),
        child: Row(
          children: [
            AppIcon(_icon, color: selected ? p.primary : p.inkSoft, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label, style: context.text.titleSmall),
                  Text(option.hint, style: context.text.bodySmall),
                ],
              ),
            ),
            AnimatedContainer(
              duration: Motion.medium,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? p.primary : p.line, width: selected ? 6.5 : 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.summary});
  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < summary.groups.length; i++) ...[
          Row(
            children: [
              AppIcon(PhosphorIconsFill.storefront, size: 14, color: p.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  summary.groups[i].sellerName ?? 'Shop ${i + 1}',
                  style: context.text.labelMedium?.copyWith(color: p.muted),
                ),
              ),
              Text(
                '${summary.groups[i].items.length} item${summary.groups[i].items.length == 1 ? '' : 's'}',
                style: context.text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: summary.groups[i].items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, j) {
                final item = summary.groups[i].items[j];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(width: 54, height: 54, child: NetImage(item.image, decodeWidth: 80)),
                    ),
                    if (item.quantity > 1)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Pill('×${item.quantity}', color: Colors.white, background: p.ink, dense: true),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],
        Divider(color: p.line),
        const SizedBox(height: 6),
        SummaryRow('Subtotal', _m(summary.subtotal)),
        SummaryRow('Delivery (${summary.groups.length} × ${_m(Env.shippingPerSeller)})', _m(summary.shipping)),
        if (summary.savings > 0) SummaryRow('You save', '−${_m(summary.savings)}', valueColor: BrandColors.success),
        const SizedBox(height: 4),
        SummaryRow('Total', _m(summary.total), emphasize: true),
      ],
    );
  }

  String _m(double v) => money(v.roundToDouble());
}

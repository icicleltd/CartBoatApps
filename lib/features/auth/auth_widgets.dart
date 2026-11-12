import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/cartboat_logo.dart';
import '../../shared/widgets/common.dart';

/// Shared chrome for auth & seller flows: brand header, scrollable form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onClose,
    this.closeIcon = PhosphorIconsBold.x,
    this.headerIcon,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onClose;
  final IconData closeIcon;
  final IconData? headerIcon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, 32),
          children: [
            Row(
              children: [
                CircleIconButton(
                  icon: closeIcon,
                  size: 42,
                  iconSize: 18,
                  onTap: onClose ?? () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: headerIcon == null
                  ? const CartBoatMark(size: 60)
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(18)),
                      child: AppIcon(headerIcon, color: p.primary, size: 30),
                    ),
            ).animate().scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
            const SizedBox(height: 22),
            Text(
              title,
              style: context.text.headlineLarge,
            ).animate().fadeIn(delay: 80.ms, duration: 360.ms).slideY(begin: 0.25, curve: Motion.emphasized),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: context.text.bodyLarge?.copyWith(color: p.muted),
            ).animate().fadeIn(delay: 140.ms, duration: 360.ms).slideY(begin: 0.25, curve: Motion.emphasized),
            const SizedBox(height: 30),
            ...children
                .animate(interval: 50.ms, delay: 200.ms)
                .fadeIn(duration: 360.ms)
                .slideY(begin: 0.15, curve: Motion.emphasized),
          ],
        ),
      ),
    );
  }
}

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboard,
    this.password = false,
    this.autofill,
    this.action = TextInputAction.next,
    this.onSubmitted,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final bool password;
  final Iterable<String>? autofill;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboard,
        obscureText: widget.password && _hidden,
        autofillHints: widget.autofill,
        textInputAction: widget.action,
        onFieldSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        textCapitalization: widget.capitalization,
        autocorrect: !widget.password,
        enableSuggestions: !widget.password,
        style: context.text.bodyLarge?.copyWith(color: context.palette.ink),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: AppIcon(widget.icon, size: 20),
          suffixIcon: widget.password
              ? IconButton(
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: AnimatedSwitcher(
                    duration: Motion.fast,
                    child: AppIcon(
                      _hidden ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                      key: ValueKey(_hidden),
                      size: 20,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email is required';
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()) ? null : 'Enter a valid email';
}

/// Matches the web store's rule: 8+ characters with a special character.
String? strongPasswordValidator(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  if (v.length < 8) return 'Use at least 8 characters';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Add at least one special character';
  return null;
}

int passwordScore(String v) {
  var s = 0;
  if (v.length >= 8) s++;
  if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) s++;
  if (RegExp(r'\d').hasMatch(v)) s++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;
  return s;
}

class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final score = passwordScore(password);
    final colors = [p.danger, p.danger, p.warning, BrandColors.tide500, p.success];
    final labels = ['Too short', 'Weak', 'Okay', 'Good', 'Strong'];
    return AnimatedOpacity(
      duration: Motion.medium,
      opacity: password.isEmpty ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        child: Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: Motion.medium,
                  curve: Motion.emphasized,
                  height: 5,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: i < score ? colors[score] : p.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: Text(labels[score], style: context.text.labelSmall?.copyWith(color: colors[score])),
            ),
          ],
        ),
      ),
    );
  }
}

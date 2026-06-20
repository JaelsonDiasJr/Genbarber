import 'package:flutter/material.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/models/models.dart';

// ─── Status Badge ────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case AppointmentStatus.confirmed:
        bg = const Color(0xFFE6F4EA);
        fg = AppColors.confirmed;
        label = 'Confirmado';
        break;
      case AppointmentStatus.pending:
        bg = const Color(0xFFFFF8E1);
        fg = AppColors.pending;
        label = 'Pendente';
        break;
      case AppointmentStatus.cancelled:
        bg = const Color(0xFFFCE8E6);
        fg = AppColors.cancelled;
        label = 'Cancelado';
        break;
      case AppointmentStatus.inProgress:
        bg = const Color(0xFFE8F3FF);
        fg = AppTheme.primary;
        label = 'Em andamento';
        break;
      case AppointmentStatus.finished:
        bg = const Color(0xFFEDEDED);
        fg = AppTheme.textSecondary;
        label = 'Finalizado';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary)),
          ),
      ],
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  const StatCard(
      {super.key,
      required this.icon,
      required this.value,
      required this.label,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor ?? AppTheme.primary, size: 20),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    );
  }
}

// ─── Info Tile ───────────────────────────────────────────────
class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoTile(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border)),
      child: Row(children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ]),
        ),
      ]),
    );
  }
}

class ShopCoverImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final BorderRadius borderRadius;
  final Widget? overlayChild;

  const ShopCoverImage({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.borderRadius,
    this.overlayChild,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(children: [
          hasValidUrl
              ? Image.network(
                  imageUrl!.trim(),
                  height: height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultBanner(),
                )
              : _defaultBanner(),
          // Gradient overlay for better readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          if (overlayChild != null) overlayChild!,
        ]),
      ),
    );
  }

  Widget _defaultBanner() => Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/banner_default.jpg',
            fit: BoxFit.cover,
          ),
          // Subtle dark overlay to soften the image
          Container(
            color: Colors.black.withOpacity(0.15),
          ),
        ],
      );
}

// ─── Loading Overlay ─────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay(
      {super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      child,
      if (isLoading)
        Positioned.fill(
          child: Container(
            color: Colors.black26,
            child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
          ),
        ),
    ]);
  }
}

// ─── Empty State ─────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 56, color: AppTheme.border),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Bottom Nav ──────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;
  const AppBottomNav(
      {super.key,
      required this.currentIndex,
      required this.items,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 44,
                    height: 32,
                    decoration: selected
                        ? BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20))
                        : null,
                    child: Icon(selected ? item.activeIcon : item.icon,
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: 22),
                  ),
                  const SizedBox(height: 2),
                  Text(item.label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textSecondary)),
                ]),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

// ─── Barbershop Card ─────────────────────────────────────────
class BarbershopCard extends StatelessWidget {
  final BarbershopModel shop;
  final VoidCallback onTap;
  const BarbershopCard({super.key, required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShopCoverImage(
            imageUrl: shop.coverUrl,
            height: 160,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            overlayChild: shop.rating > 0
                ? Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ]),
                      child: Row(children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFBBC04), size: 14),
                        const SizedBox(width: 3),
                        Text(shop.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(shop.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary))),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 36),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: const TextStyle(fontSize: 13)),
                        child: const Text('Agendar'),
                      ),
                    ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(
                      child: Text(
                          shop.address.isEmpty ? shop.subtitle : shop.address,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary))),
                ]),
                if (shop.rating > 0) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    ...List.generate(5, (i) {
                      final filled = i < shop.rating.floor();
                      final half =
                          !filled && i < shop.rating && shop.rating % 1 >= 0.5;
                      return Icon(
                        half
                            ? Icons.star_half_rounded
                            : filled
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                        color: const Color(0xFFFBBC04),
                        size: 16,
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(shop.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(width: 4),
                    Text('(${shop.ratingCount} avaliações)',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                ] else ...[
                  const SizedBox(height: 8),
                  const Row(children: [
                    Icon(Icons.star_border_rounded,
                        color: Color(0xFFD1D5DB), size: 14),
                    SizedBox(width: 4),
                    Text('Sem avaliações ainda',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

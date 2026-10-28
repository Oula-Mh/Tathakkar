import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Floating glass bottom navigation (pill) matching the design.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: GlassCard(
      radius: 35,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = i == index;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: items[i].label,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.iceBlue.withValues(
                            alpha: context.isDark ? 0.2 : 1,
                          )
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        color: selected
                            ? context.primaryColor
                            : context.inkSoftColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? context.primaryColor
                              : context.inkSoftColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

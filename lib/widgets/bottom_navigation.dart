import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../theme/app_theme.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  static const items = [
    (label: 'Markas', icon: Icons.apartment_rounded),
    (label: 'Peta', icon: Icons.public_rounded),
    (label: 'Kontrak', icon: Icons.assignment_rounded),
    (label: 'Armada', icon: Icons.local_shipping_rounded),
    (label: 'Staf', icon: Icons.groups_rounded),
    (label: 'Lainnya', icon: Icons.grid_view_rounded),
    (label: 'Chat', icon: Icons.chat_bubble_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final active = state.selectedTab == index;

            return Expanded(
              child: InkWell(
                onTap: () => state.setTab(index),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: active
                                ? AppColors.emerald
                                : AppColors.textSecondary,
                          ),
                          if (index == 1 && state.activeVehicles > 0)
                            Positioned(
                              right: -4,
                              top: -3,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.emerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (index == 6)
                            Positioned(
                              right: -7,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '2',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: active
                              ? AppColors.emerald
                              : AppColors.textSecondary,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

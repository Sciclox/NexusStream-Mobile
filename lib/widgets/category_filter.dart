import 'package:flutter/material.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../core/channel_categories.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ChannelCategories.list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = ChannelCategories.list[index];
          final isSelected = cat == state.selectedCategory;

          return Focus(
            child: Builder(builder: (ctx) {
              final isFocused = Focus.of(ctx).hasFocus;

              return InkWell(
                onTap: () => state.selectCategory(cat),
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.22)
                        : (isFocused ? AppColors.surfaceLight : AppColors.card),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isFocused
                          ? accent
                          : (isSelected ? accent.withValues(alpha: 0.7) : AppColors.border),
                      width: isFocused ? 2 : (isSelected ? 1.5 : 1),
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : (isSelected
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent,
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? accent : (isFocused ? Colors.white : AppColors.textSecondary),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

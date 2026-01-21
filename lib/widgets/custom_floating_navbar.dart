import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class CustomFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<CustomNavBarItem> items;
  final VoidCallback? onActionButtonTap;
  final IconData actionButtonIcon;

  const CustomFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onActionButtonTap,
    this.actionButtonIcon = Icons.shopping_cart_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding > 0 ? bottomPadding : 12),
      height: 90, // Increased height to 90
      child: Row(
        children: [
          // Nav Items Container
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(45), // More rounded for larger height
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8), // Tighter horizontal padding for more item space
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(45),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSelected = index == currentIndex;

                      return GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 12 : 8,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.grey.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected ? Colors.black : Colors.grey.shade600,
                                size: 26, // Slightly larger icon
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4), // Reduced spacing
                                Flexible(
                                  child: Text(
                                    item.label,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13, // Slightly smaller font to fit
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          
          if (onActionButtonTap != null) ...[
            const SizedBox(width: 12),
            // Action Button
            GestureDetector(
              onTap: onActionButtonTap,
              child: Container(
                width: 75, // Increased from 65
                height: 75, // Increased from 65
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9D6C), Color(0xFFFF5F3D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5F3D).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  actionButtonIcon,
                  color: Colors.white,
                  size: 32, // Increased from 28
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CustomNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  CustomNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

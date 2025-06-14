import 'package:flutter/material.dart';
import 'category_model.dart';

class CategoryChip extends StatelessWidget {
  final CharacterCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: isSelected ? Colors.white : category.color,
            ),
            const SizedBox(width: 4),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : category.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: category.color,
        backgroundColor: category.color.withOpacity(0.1),
        checkmarkColor: Colors.white,
        elevation: isSelected ? 4 : 1,
        shadowColor: category.color.withOpacity(0.5),
      ),
    );
  }
}

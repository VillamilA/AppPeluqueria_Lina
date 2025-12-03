import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class GenderSelector extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const GenderSelector({
    Key? key,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<GenderSelector> createState() => _GenderSelectorState();
}

class _GenderSelectorState extends State<GenderSelector> {
  late String selectedGender;

  @override
  void initState() {
    super.initState();
    selectedGender = widget.initialValue.isNotEmpty ? widget.initialValue : 'M';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedGender,
        isExpanded: true,
        underline: SizedBox(),
        dropdownColor: AppColors.charcoal,
        style: TextStyle(color: AppColors.gold, fontSize: 16),
        items: [
          DropdownMenuItem(
            value: 'M',
            child: Row(
              children: [
                Icon(Icons.male, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Hombre'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'F',
            child: Row(
              children: [
                Icon(Icons.female, color: Colors.pink, size: 20),
                SizedBox(width: 8),
                Text('Mujer'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'O',
            child: Row(
              children: [
                Icon(Icons.help, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('Otro'),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => selectedGender = value);
            widget.onChanged(value);
          }
        },
      ),
    );
  }
}

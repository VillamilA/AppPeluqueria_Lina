import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Widget de Calendario personalizado para seleccionar fecha
class BookingCalendarWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime? selectedDate;
  final List<String> unavailableDates;

  const BookingCalendarWidget({
    super.key,
    required this.onDateSelected,
    this.selectedDate,
    this.unavailableDates = const [],
  });

  @override
  State<BookingCalendarWidget> createState() => _BookingCalendarWidgetState();
}

class _BookingCalendarWidgetState extends State<BookingCalendarWidget> {
  late DateTime _displayMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate ?? DateTime.now();
    _displayMonth = DateTime(_selectedDay.year, _selectedDay.month, 1);
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    return List.generate(daysInMonth, (index) => DateTime(month.year, month.month, index + 1));
  }

  bool _isDateUnavailable(DateTime date) {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return widget.unavailableDates.contains(dateString);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_displayMonth);
    final firstDayOfWeek = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday % 7;
    final monthName = _getMonthName(_displayMonth.month);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: AppColors.gold),
                onPressed: _previousMonth,
              ),
              Text(
                '$monthName ${_displayMonth.year}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: AppColors.gold),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Días de la semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sab']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.gold.withOpacity(0.1), height: 1),
          const SizedBox(height: 8),
          // Calendario
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: firstDayOfWeek + days.length,
            itemBuilder: (context, index) {
              if (index < firstDayOfWeek) {
                return const SizedBox();
              }
              final dayIndex = index - firstDayOfWeek;
              final date = days[dayIndex];
              final isPast = date.isBefore(DateTime.now());
              final isSelected = _isSameDay(date, _selectedDay);
              final isToday = _isSameDay(date, DateTime.now());
              final isUnavailable = _isDateUnavailable(date);

              return GestureDetector(
                onTap: (isPast || isUnavailable)
                    ? null
                    : () {
                        setState(() => _selectedDay = date);
                        widget.onDateSelected(date);
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold
                        : isToday
                            ? AppColors.gold.withOpacity(0.2)
                            : Colors.transparent,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.gold, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : isPast || isUnavailable
                                    ? Colors.grey.shade700
                                    : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        if (isUnavailable)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Leyenda
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Seleccionado',
                    style: TextStyle(
                      color: AppColors.gray.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold, width: 1.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hoy',
                    style: TextStyle(
                      color: AppColors.gray.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sin disponibilidad',
                    style: TextStyle(
                      color: AppColors.gray.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[month - 1];
  }
}

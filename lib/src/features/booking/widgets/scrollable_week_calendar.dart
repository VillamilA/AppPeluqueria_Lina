import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ScrollableWeekCalendar extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;
  final DateTime? selectedDate;
  final List<String> workDays;

  const ScrollableWeekCalendar({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    this.selectedDate,
    required this.workDays,
  });

  @override
  State<ScrollableWeekCalendar> createState() => _ScrollableWeekCalendarState();
}

class _ScrollableWeekCalendarState extends State<ScrollableWeekCalendar> {
  late ScrollController _scrollController;
  late List<DateTime> _weekDates;
  late int _scrollIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateWeekDates();
    _findInitialScrollIndex();
    // Usar addPostFrameCallback de forma más segura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToInitialDate();
      }
    });
  }

  void _generateWeekDates() {
    _weekDates = [];
    // Generar 60 días a partir de hoy
    final today = DateTime.now();
    for (int i = 0; i < 60; i++) {
      _weekDates.add(today.add(Duration(days: i)));
    }
  }

  void _findInitialScrollIndex() {
    final today = DateTime.now();
    _scrollIndex = _weekDates.indexWhere((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);
    if (_scrollIndex == -1) _scrollIndex = 0;
  }

  void _scrollToInitialDate() {
    if (!mounted || !_scrollController.hasClients) return;
    
    final itemWidth = 75.0;
    final scrollOffset = (_scrollIndex * itemWidth) - 20;
    if (scrollOffset >= 0) {
      try {
        _scrollController.jumpTo(scrollOffset);
      } catch (e) {
        print('Error scrolling to initial date: $e');
      }
    }
  }

  bool _isWorkDay(DateTime date) {
    final dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final dayIndex = (date.weekday - 1) % 7;
    return widget.workDays.contains(dayNames[dayIndex]);
  }

  String _getDayName(DateTime date) {
    final names = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return names[date.weekday - 1];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: isMobile ? 90 : 100,
      color: AppColors.charcoal,
      child: _weekDates.isEmpty 
        ? Center(
            child: Text(
              'Cargando fechas...',
              style: TextStyle(color: AppColors.gray),
            ),
          )
        : ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _weekDates.length,
        itemBuilder: (context, index) {
          final date = _weekDates[index];
          final isSelected = widget.selectedDate != null &&
              date.year == widget.selectedDate!.year &&
              date.month == widget.selectedDate!.month &&
              date.day == widget.selectedDate!.day;
          final isWorkDay = _isWorkDay(date);

          return GestureDetector(
            onTap: isWorkDay
                ? () => widget.onDateSelected(date)
                : null,
            child: Container(
              width: isMobile ? 65 : 75,
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 4 : 5,
                vertical: isMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold
                    : isWorkDay
                        ? AppColors.charcoal
                        : AppColors.charcoal.withOpacity(0.5),
                border: Border.all(
                  color: isWorkDay ? AppColors.gold : AppColors.gray,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date),
                    style: TextStyle(
                      color: isSelected ? AppColors.charcoal : AppColors.gold,
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isMobile ? 2 : 3),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? AppColors.charcoal : Colors.white,
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isMobile ? 2 : 3),
                  Text(
                    _getMonthName(date.month).substring(0, 3),
                    style: TextStyle(
                      color: isSelected ? AppColors.charcoal : AppColors.gray,
                      fontSize: isMobile ? 9 : 10,
                    ),
                  ),
                  // Indicador de día no laborable
                  if (!isWorkDay)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.block,
                        size: isMobile ? 8 : 9,
                        color: AppColors.gray,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}

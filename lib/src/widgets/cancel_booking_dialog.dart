import 'package:flutter/material.dart';

/// Diálogo para cancelar reservas con validación de motivo
/// - Mínimo 10 palabras con sentido
/// - Censura groserías
/// - Límite de 100 palabras
/// - Botones predefinidos por rol (cliente/estilista)
class CancelBookingDialog extends StatefulWidget {
  final String bookingInfo; // Nombre del cliente o información de la reserva
  final bool isStylista; // true = estilista, false = cliente

  const CancelBookingDialog({
    super.key,
    required this.bookingInfo,
    this.isStylista = false,
  });

  @override
  State<CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<CancelBookingDialog> {
  final TextEditingController _motivoController = TextEditingController();
  String _errorMessage = '';
  int _wordCount = 0;

  // Botones predefinidos por rol
  static const List<String> _clientePredefinidos = [
    'Tuve un contratiempo',
    'Estoy mal de salud',
    'Voy a agendar otro día',
  ];

  static const List<String> _estilestaPredefinidos = [
    'Cliente no asistió',
    'Tuve una calamidad',
    'Fecha festiva',
  ];

  // Lista de palabras prohibidas (groserías y palabras ofensivas)
  static const List<String> _badWords = [
    'mierda', 'puta', 'puto', 'coño', 'cabrón', 'cabron', 'joder', 
    'pendejo', 'pendeja', 'culero', 'chingada', 'verga', 'idiota',
    'estúpido', 'estupido', 'imbécil', 'imbecil', 'maldito', 'maldita',
    'carajo', 'huevón', 'huevon', 'maricon', 'maricón', 'perra',
    'zorra', 'bastardo', 'bastarda', 'mamón', 'mamon', 'gonorrea',
  ];

  List<String> get _predefinidos => 
      widget.isStylista ? _estilestaPredefinidos : _clientePredefinidos;

  @override
  void initState() {
    super.initState();
    _motivoController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _motivoController.text;
    final words = text.trim().split(RegExp(r'\s+'));
    
    setState(() {
      _wordCount = text.trim().isEmpty ? 0 : words.length;
      
      // Validar mínimo 3 palabras
      if (_wordCount < 3 && text.trim().isNotEmpty) {
        _errorMessage = 'Mínimo 3 palabras requeridas ($_wordCount/3)';
        return;
      }
      
      // Validar límite de palabras
      if (_wordCount > 100) {
        _errorMessage = 'Máximo 100 palabras permitidas';
        return;
      }
      
      // Validar groserías
      final lowerText = text.toLowerCase();
      for (final badWord in _badWords) {
        if (lowerText.contains(badWord)) {
          _errorMessage = 'Por favor, usa un lenguaje respetuoso';
          return;
        }
      }
      
      // Validar campo no vacío
      if (text.trim().isEmpty) {
        _errorMessage = 'El motivo es obligatorio';
        return;
      }
      
      _errorMessage = '';
    });
  }

  bool get _isValid => 
      _errorMessage.isEmpty && 
      _motivoController.text.trim().isNotEmpty &&
      _wordCount >= 3;

  void _insertPredefinido(String texto) {
    final currentText = _motivoController.text.trim();
    if (currentText.isEmpty) {
      _motivoController.text = texto;
    } else {
      _motivoController.text = '$currentText. $texto';
    }
    _motivoController.selection = TextSelection.fromPosition(
      TextPosition(offset: _motivoController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF5F5F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.cancel, color: Colors.orange, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cancelar Reserva',
              style: TextStyle(
                color: const Color(0xFF3E3E3E),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vas a cancelar la reserva de:',
              style: TextStyle(
                color: const Color(0xFF6B6B6B),
                fontSize: 13,
              ),
            ),
            SizedBox(height: 4),
            Text(
              widget.bookingInfo,
              style: TextStyle(
                color: const Color(0xFF3E3E3E),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '¿Cuál es el motivo? (Mínimo 3 palabras)',
              style: TextStyle(
                color: const Color(0xFF3E3E3E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            
            // Botones predefinidos
            if (_predefinidos.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Razones frecuentes:',
                      style: TextStyle(
                        color: const Color(0xFF6B6B6B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _predefinidos.map((razon) {
                        return GestureDetector(
                          onTap: () => _insertPredefinido(razon),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.withOpacity(0.4)),
                            ),
                            child: Text(
                              razon,
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],

            // Campo de texto
            TextField(
              controller: _motivoController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Escribe el motivo aquí o haz clic en un botón arriba...',
                hintStyle: TextStyle(color: const Color(0xFFAAAAAA)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: const Color(0xFFCCCCCC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: const Color(0xFFCCCCCC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(12),
                counterText: '',
              ),
              style: TextStyle(color: const Color(0xFF3E3E3E)),
            ),
            SizedBox(height: 8),

            // Contador de palabras y mensajes de error
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_errorMessage.isNotEmpty)
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (_wordCount > 0)
                  Expanded(
                    child: Text(
                      _wordCount < 3 
                          ? '✓ Escribe más palabras' 
                          : '✓ Listo para enviar',
                      style: TextStyle(
                        color: _wordCount >= 3 ? Colors.green : const Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'Mínimo: 3 palabras',
                      style: TextStyle(
                        color: const Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                  ),
                Text(
                  '$_wordCount/100 palabras',
                  style: TextStyle(
                    color: _wordCount >= 3 ? Colors.green : 
                           (_wordCount > 100 ? Colors.red : const Color(0xFF888888)),
                    fontSize: 12,
                    fontWeight: _wordCount > 100 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Proporciona un motivo con sentido (mínimo 10 palabras)',
                      style: TextStyle(
                        color: const Color(0xFF6B6B6B),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Volver',
            style: TextStyle(color: const Color(0xFF6B6B6B)),
          ),
        ),
        ElevatedButton(
          onPressed: _isValid
              ? () => Navigator.pop(context, _motivoController.text.trim())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFCCCCCC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Confirmar Cancelación'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _scissorController;
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late AnimationController _particlesController;
  
  late Animation<double> _scissorAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _particlesAnimation;
  
  final List<HairParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    // Controlador para la animación de apertura/cierre de tijera (corte)
    _scissorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Controlador para el fade out
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Controlador para la rotación sutil
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Controlador para las partículas de pelo
    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Animación de tijera (0 = cerrada, 1 = abierta)
    _scissorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scissorController,
      curve: Curves.easeInOut,
    ));
    
    // Animación de fade para la salida
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    // Animación de rotación sutil
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: -0.1,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));
    
    // Animación de partículas cayendo
    _particlesAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particlesController,
      curve: Curves.easeOut,
    ));
    
    // Iniciar secuencia de animaciones
    _startAnimation();
  }
  
  void _startAnimation() async {
    // Repetir la animación de corte 3 veces
    for (int i = 0; i < 3; i++) {
      await _scissorController.forward();
      
      // Generar partículas en cada corte
      _generateHairParticles();
      _particlesController.forward(from: 0);
      
      await _scissorController.reverse();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Pequeña pausa
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Rotación sutil final
    await _rotateController.forward();
    
    // Fade out
    await _fadeController.forward();
    
    // Navegar a la página de bienvenida
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }
  
  void _generateHairParticles() {
    final random = math.Random();
    setState(() {
      _particles.clear();
      for (int i = 0; i < 8; i++) {
        _particles.add(HairParticle(
          startX: -20 + random.nextDouble() * 40,
          startY: -30.0,
          velocityX: -30 + random.nextDouble() * 60,
          velocityY: 40 + random.nextDouble() * 80,
          rotation: random.nextDouble() * math.pi * 4,
          length: 15 + random.nextDouble() * 25,
        ));
      }
    });
  }
  
  @override
  void dispose() {
    _scissorController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animación de la tijera con partículas
              Stack(
                alignment: Alignment.center,
                children: [
                  // Partículas de pelo cayendo
                  AnimatedBuilder(
                    animation: _particlesAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(200, 200),
                        painter: HairParticlesPainter(
                          particles: _particles,
                          progress: _particlesAnimation.value,
                        ),
                      );
                    },
                  ),
                  
                  // Tijera animada
                  AnimatedBuilder(
                    animation: Listenable.merge([_scissorAnimation, _rotateAnimation]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: CustomPaint(
                          size: const Size(200, 200),
                          painter: ScissorsPainter(
                            openAmount: _scissorAnimation.value,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Nombre de la peluquería con efecto shimmer
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [
                    AppColors.gold,
                    Colors.white,
                    AppColors.gold,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: const Text(
                  'Peluquería Lina',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hernandez',
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CustomPainter para dibujar tijeras clásicas tradicionales
class ScissorsPainter extends CustomPainter {
  final double openAmount;
  
  ScissorsPainter({required this.openAmount});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Colores tradicionales - plata/gris metálico
    final metalPaint = Paint()
      ..color = const Color(0xFFC0C0C0) // Plata
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final metalFillPaint = Paint()
      ..color = const Color(0xFFE0E0E0) // Plata claro
      ..style = PaintingStyle.fill;
    
    final darkMetalPaint = Paint()
      ..color = const Color(0xFF808080) // Gris oscuro
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final angle = openAmount * 0.4; // Apertura moderada
    
    final bladeLength = size.width * 0.30;
    final bladeWidth = 12.0;
    
    // ===== HOJA SUPERIOR =====
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-angle);
    
    // Hoja superior - estilo tradicional (alargada y puntiaguda)
    final topBlade = Path();
    topBlade.moveTo(0, 0);
    topBlade.lineTo(-bladeLength, -bladeWidth / 2);
    topBlade.lineTo(-bladeLength * 1.05, 0); // Punta
    topBlade.lineTo(-bladeLength, bladeWidth / 2);
    topBlade.close();
    
    canvas.drawPath(topBlade, metalFillPaint);
    canvas.drawPath(topBlade, metalPaint);
    
    // Línea de filo superior (brillo)
    canvas.drawLine(
      Offset(-bladeLength * 0.3, -bladeWidth / 2 + 1),
      Offset(-bladeLength * 1.05, 0),
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1.5,
    );
    
    // Mango superior - anillo ovalado clásico
    final topHandleRect = Rect.fromCenter(
      center: Offset(bladeLength * 0.25, 0),
      width: 28,
      height: 35,
    );
    canvas.drawOval(topHandleRect, metalFillPaint);
    canvas.drawOval(topHandleRect, metalPaint);
    
    // Hueco interno del anillo
    final topHandleInner = Rect.fromCenter(
      center: Offset(bladeLength * 0.25, 0),
      width: 18,
      height: 25,
    );
    canvas.drawOval(topHandleInner, Paint()..color = AppColors.charcoal);
    
    canvas.restore();
    
    // ===== HOJA INFERIOR =====
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    
    // Hoja inferior
    final bottomBlade = Path();
    bottomBlade.moveTo(0, 0);
    bottomBlade.lineTo(-bladeLength, -bladeWidth / 2);
    bottomBlade.lineTo(-bladeLength * 1.05, 0); // Punta
    bottomBlade.lineTo(-bladeLength, bladeWidth / 2);
    bottomBlade.close();
    
    canvas.drawPath(bottomBlade, metalFillPaint);
    canvas.drawPath(bottomBlade, metalPaint);
    
    // Línea de filo inferior (brillo)
    canvas.drawLine(
      Offset(-bladeLength * 0.3, bladeWidth / 2 - 1),
      Offset(-bladeLength * 1.05, 0),
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1.5,
    );
    
    // Mango inferior - anillo ovalado clásico
    final bottomHandleRect = Rect.fromCenter(
      center: Offset(bladeLength * 0.25, 0),
      width: 28,
      height: 35,
    );
    canvas.drawOval(bottomHandleRect, metalFillPaint);
    canvas.drawOval(bottomHandleRect, metalPaint);
    
    // Hueco interno del anillo
    final bottomHandleInner = Rect.fromCenter(
      center: Offset(bladeLength * 0.25, 0),
      width: 18,
      height: 25,
    );
    canvas.drawOval(bottomHandleInner, Paint()..color = AppColors.charcoal);
    
    canvas.restore();
    
    // Tornillo central - tradicional
    canvas.drawCircle(center, 7, darkMetalPaint);
    canvas.drawCircle(center, 7, metalPaint);
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF404040));
    
    // Cruz del tornillo (detalle tradicional)
    final screwPaint = Paint()
      ..color = const Color(0xFF404040)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(center.dx - 3, center.dy),
      Offset(center.dx + 3, center.dy),
      screwPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 3),
      Offset(center.dx, center.dy + 3),
      screwPaint,
    );
  }
  
  @override
  bool shouldRepaint(ScissorsPainter oldDelegate) {
    return oldDelegate.openAmount != openAmount;
  }
}

// Clase para representar una partícula de pelo
class HairParticle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double length;
  
  HairParticle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.length,
  });
}

// Painter para las partículas de pelo cayendo
class HairParticlesPainter extends CustomPainter {
  final List<HairParticle> particles;
  final double progress;
  
  HairParticlesPainter({
    required this.particles,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withOpacity(0.6 * (1 - progress))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    for (final particle in particles) {
      // Calcular posición actual basada en el progreso
      final x = center.dx + particle.startX + (particle.velocityX * progress);
      final y = center.dy + particle.startY + (particle.velocityY * progress);
      
      // Dibujar línea de pelo con rotación
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * progress);
      
      canvas.drawLine(
        Offset.zero,
        Offset(0, particle.length),
        paint,
      );
      
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(HairParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

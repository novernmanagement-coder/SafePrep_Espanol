import 'package:flutter/material.dart';
import 'constants.dart';
import 'home_page.dart';
import 'safe_prep_nav_bar.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  Widget _buildCard(String title, List<String> paragraphs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppFonts.subheader,
              color: AppColors.strongText,
            ),
          ),
          ...paragraphs.map(
            (p) => Text(
              p,
              style: TextStyle(
                fontSize: AppFonts.body,
                color: AppColors.bodyText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.servSafeBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Safe',
                          style: TextStyle(
                            fontSize: AppFonts.header,
                            fontWeight: FontWeight.w600,
                            color: AppColors.bodyText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset('Assets/splash.png', width: 36, height: 36),
                        const SizedBox(width: 6),
                        Text(
                          'Prep™',
                          style: TextStyle(
                            fontSize: AppFonts.header,
                            fontWeight: FontWeight.w600,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Cuerpo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _buildCard('Qué es un Proctor', [
                      'Un proctor es una persona certificada que supervisa tu examen ServSafe® para asegurarse de que todo se realice de manera justa y segura. Verifica tu identidad, monitorea el entorno de examen y garantiza que se sigan las reglas.',
                    ]),
                    _buildCard('Cómo Encontrar un Proctor', [
                      'Puedes encontrar un proctor certificado visitando ServSafe.com, seleccionando Exams, eligiendo Find a Proctor e ingresando tu código postal. Luego puedes contactar a un proctor o centro de examen directamente para programar tu cita.',
                      'Un proctor certificado debe estar físicamente presente contigo durante todo el examen. Esto garantiza la verificación de identidad, un entorno de examen adecuado y la entrega segura de tu examen.',
                      'Algunas áreas también ofrecen centros de examen aprobados, que cuentan con una sala de examen, un proctor certificado en el lugar y estaciones de computadora.',
                    ]),
                    _buildCard('Costo del Servicio de Proctor', [
                      'Las tarifas de proctoring varían según la ubicación y el proveedor. Los costos típicos oscilan entre 35 y 75 dólares. Algunos proctors incluyen el uso de sala, acceso a computadora o tarifas administrativas en su precio.',
                    ]),
                    _buildCard('Costo del Examen', [
                      'El precio del examen varía dependiendo de si compras solo el examen o un paquete de curso y examen. El precio típico solo del examen oscila entre 36 y 50 dólares.',
                    ]),
                    _buildCard('Cómo Comprar el Examen', [
                      'Los estudiantes pueden comprar su propio examen directamente en el sitio web de ServSafe®. Ve a ServSafe.com, selecciona Exams, elige ServSafe® Manager Exam y completa el proceso de pago. Recibirás un código de voucher para llevar el día del examen.',
                      'Algunos proctors ofrecen un paquete combinado que incluye el examen, los servicios de proctoring y el uso de una sala de examen o computadora. En estos casos, el estudiante no necesita comprar el examen por separado.',
                    ]),
                    _buildCard('Duración del Examen', [
                      'El examen ServSafe® Manager permite hasta 2 horas. La mayoría de las personas termina en 60 a 90 minutos. Tu proctor te informará cuándo comienza el examen y cuánto tiempo queda.',
                    ]),
                    _buildCard('Cuándo Recibes tus Resultados', [
                      'Los exámenes en línea generalmente se califican inmediatamente después de ser enviados. Los exámenes en papel pueden tardar entre 3 y 10 días hábiles dependiendo del tiempo de procesamiento.',
                    ]),
                    _buildCard('Qué Traer', [
                      'La mayoría de los proctors requieren una identificación con foto emitida por el gobierno y cualquier voucher de examen que se te haya proporcionado. No se permiten teléfonos, apuntes, libros ni dispositivos inteligentes durante el examen.',
                    ]),
                    _buildCard('Consejos para el Día del Examen', [
                      'Llega temprano, trae tu identificación, ve al baño antes de comenzar y haz cualquier pregunta antes de que empiece el examen. Mantén la calma y tómate tu tiempo. Puedes marcar preguntas y volver a ellas.',
                    ]),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const SafePrepNavBar(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orbit_defender/manager/game_manager.dart';
import 'package:orbit_defender/ui/game_screen.dart';
import 'package:orbit_defender/utils/parallax_starfield_painter.dart';
import 'package:orbit_defender/utils/responsive_utils.dart';
import 'package:orbit_defender/utils/audio_manager.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Inicializar animação para o fundo de estrelas
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(hours: 2), // Movimento lento
    );
    _animation = Tween<double>(begin: 0, end: 10).animate(_animationController);
    _animationController.forward();

    // Inicializar áudio e serviços de jogos
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Inicializar áudio
      await AudioManager().initialize();

      // Inicializar serviços de jogos
      await GameServicesManager().initialize();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Erro na inicialização: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context: context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fundo estrelado animado
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParallaxStarfieldPainter(
                  animationValue: _animation.value,
                  starCount: 120,
                  nearStarsSpeed: 0.002,
                  midStarsSpeed: 0.0008,
                  farStarsSpeed: 0.0002,
                ),
                size: MediaQuery.of(context).size,
              );
            },
          ),

          // Conteúdo do menu
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: responsive.dp(60)),

                // Logo do jogo - agora maior
                Container(
                  width: responsive.screenWidth * 0.85, // Aumentado de 0.7 para 0.85
                  height: responsive.dp(150), // Aumentado de 120 para 150
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                // Espaço após o logo
                SizedBox(height: responsive.dp(60)),

                // Botão COMEÇAR
                _buildMenuButton(
                  context: context,
                  text: 'COMEÇAR',
                  backgroundColor: Colors.blue.shade700,
                  icon: Icons.play_arrow,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const GameScreen()),
                    );
                  },
                ),

                SizedBox(height: responsive.dp(20)),

                // Botão RANKING
                _buildMenuButton(
                  context: context,
                  text: 'RANKING',
                  backgroundColor: Colors.amber.shade700,
                  icon: Icons.leaderboard,
                  onPressed: () {
                    GameServicesManager().showLeaderboard();
                  },
                ),

                SizedBox(height: responsive.dp(20)),

                // Botão CONQUISTAS
                _buildMenuButton(
                  context: context,
                  text: 'CONQUISTAS',
                  backgroundColor: Colors.green.shade700,
                  icon: Icons.emoji_events,
                  onPressed: () {
                    GameServicesManager().showAchievements();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String text,
    required Color backgroundColor,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final responsive = ResponsiveUtils(context: context);

    return Container(
      width: responsive.dp(200),
      height: responsive.dp(50),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.dp(25)),
          ),
          elevation: 8,
          shadowColor: backgroundColor.withOpacity(0.6),
        ),
        onPressed: _isInitialized ? onPressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Adicione esta linha
          children: [
            Icon(icon, size: responsive.dp(22)),  // Reduza um pouco o tamanho
            SizedBox(width: responsive.dp(8)),    // Reduza o espaçamento
            Flexible(                            // Envolva o texto com Flexible
              child: Text(
                text,
                style: TextStyle(
                  fontSize: responsive.dp(15),    // Reduza um pouco a fonte
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,             // Reduza o espaçamento de letras
                ),
                overflow: TextOverflow.ellipsis,  // Adicione esta linha
              ),
            ),
          ],
        ),
      ),
    );
  }
}

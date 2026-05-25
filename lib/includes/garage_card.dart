import 'dart:math';
import 'package:flutter/material.dart';
import 'package:oil_gid/themes/app_colors.dart';

class GarageCard extends StatefulWidget {
  const GarageCard({super.key});

  @override
  State<GarageCard> createState() => _GarageCardState();
}

class _GarageCardState extends State<GarageCard> with TickerProviderStateMixin {
  late final AnimationController _gradCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _sparkleCtrl;
  late final Animation<double> _gradAnim;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    _gradCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _gradAnim = CurvedAnimation(parent: _gradCtrl, curve: Curves.easeInOut);

    // Shimmer идёт независимо от градиента, чуть медленнее
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shimmerAnim = CurvedAnimation(
      parent: _shimmerCtrl,
      curve: Curves.easeInOut,
    );
    _shimmerLoop();

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  Future<void> _shimmerLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 8));
      if (!mounted) break;
      await _shimmerCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) break;
      await _shimmerCtrl.reverse();
      _shimmerCtrl.reset();
    }
  }

  @override
  void dispose() {
    _gradCtrl.dispose();
    _shimmerCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_gradAnim, _shimmerAnim, _sparkleCtrl]),
      builder: (context, child) {
        final t = _gradAnim.value;
        final sh = _shimmerAnim.value;
        final sp = _sparkleCtrl.value;

        // Центр яркого пятна shimmer движется по вертикали
        final shCenter = sh.clamp(0.01, 0.99);
        final shStart = (shCenter - 0.22).clamp(0.0, 1.0);
        final shEnd = (shCenter + 0.22).clamp(0.0, 1.0);
        // Цвет в пике: белый → голубой → белый
        final shColor = Color.lerp(
          Colors.white,
          const Color(0xFFAAD4FF),
          sin(sh * pi).clamp(0.0, 1.0),
        )!.withValues(alpha: (0.32 * sin(sh * pi)).clamp(0.0, 1.0));

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  const Color(0xFF3D6494),
                  const Color(0xFF1A3A6C),
                  t,
                )!,
                const Color(0xFF0D1B2A),
                Color.lerp(
                  const Color(0xFF2A558A),
                  const Color(0xFF0F2240),
                  t,
                )!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  AppColors.primary.withValues(alpha: 0.4),
                  const Color(0xFF1E4A8A).withValues(alpha: 0.6),
                  t,
                )!,
                blurRadius: 14 + 10 * t,
                spreadRadius: t * 2,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.06 + 0.08 * t),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14.5),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.5),
              onTap: () => Navigator.pushNamed(context, '/garage'),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        const Color(0xFF0E1E30),
                        const Color(0xFF162B44),
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFF1A2635),
                        const Color(0xFF1A3050),
                        t,
                      )!,
                    ],
                    begin: Alignment.lerp(
                      Alignment.topLeft,
                      Alignment.topRight,
                      t * 0.15,
                    )!,
                    end: Alignment.lerp(
                      Alignment.bottomRight,
                      Alignment.bottomLeft,
                      t * 0.15,
                    )!,
                  ),
                  borderRadius: BorderRadius.circular(14.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.5),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      child!,
                      // Косой shimmer на всю ширину
                      Positioned(
                        left: -60,
                        right: -60,
                        top: -60,
                        bottom: -60,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: pi / 12,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    shColor,
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, shStart, shCenter, shEnd, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Мерцающие искры
                      _sparkle(
                        right: 58,
                        top: 14,
                        size: 3,
                        opacity: 0.2 + 0.45 * sp,
                      ),
                      _sparkle(
                        right: 43,
                        top: 23,
                        size: 2,
                        opacity: 0.15 + 0.35 * (1 - sp),
                      ),
                      _sparkle(
                        right: 64,
                        top: 28,
                        size: 2,
                        opacity: 0.1 + 0.4 * sin(sp * pi),
                      ),
                      // Зелёная accent-полоска снизу
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 3,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.accent.withValues(
                                    alpha: 0.3 + 0.35 * t,
                                  ),
                                  AppColors.accent.withValues(
                                    alpha: 0.55 + 0.3 * t,
                                  ),
                                  AppColors.accent.withValues(
                                    alpha: 0.3 + 0.35 * t,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: _buildStaticContent(),
    );
  }

  Widget _sparkle({
    required double right,
    required double top,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      right: right,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: opacity * 0.6),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticContent() {
    return Stack(
      children: [
        // Ghost car silhouette
        Positioned.fill(
          child: Align(
            alignment: const Alignment(1.15, 0.15),
            child: OverflowBox(
              maxWidth: 130,
              maxHeight: 130,
              child: Icon(
                Icons.directions_car,
                size: 120,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ),
        // Decorative ring
        Positioned(
          right: -22,
          top: -22,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.07),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.garage_outlined,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ГАРАЖ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'История обслуживания автомобилей',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

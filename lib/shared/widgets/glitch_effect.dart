import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Digital Glitch Effect Widget
///
/// Creates realistic digital corruption effects including:
/// - Chromatic aberration (RGB channel splitting)
/// - Horizontal tearing/displacement
/// - Vertical jitter
/// - Noise/static overlay
class GlitchEffect extends StatefulWidget {
  final Widget child;
  final AnimationController controller;
  final double intensity; // 0.0 to 1.0

  const GlitchEffect({
    Key? key,
    required this.child,
    required this.controller,
    this.intensity = 1.0,
  }) : super(key: key);

  @override
  State<GlitchEffect> createState() => _GlitchEffectState();
}

class _GlitchEffectState extends State<GlitchEffect> {
  final Random _random = Random();
  double _redOffsetX = 0;
  double _blueOffsetX = 0;
  double _verticalJitter = 0;
  List<GlitchSlice> _slices = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateGlitch);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateGlitch);
    super.dispose();
  }

  void _updateGlitch() {
    if (!mounted) return;

    final intensity = widget.controller.value * widget.intensity;

    setState(() {
      // Chromatic aberration - RGB channel offset
      _redOffsetX = (_random.nextDouble() - 0.5) * 20 * intensity;
      _blueOffsetX = (_random.nextDouble() - 0.5) * 20 * intensity;

      // Vertical jitter
      _verticalJitter = (_random.nextDouble() - 0.5) * 15 * intensity;

      // Horizontal tearing slices
      if (_random.nextDouble() < 0.3) {
        // 30% chance to update slices
        _slices = _generateSlices(intensity);
      }
    });
  }

  List<GlitchSlice> _generateSlices(double intensity) {
    final sliceCount = 5 + (_random.nextInt(10) * intensity).toInt();
    final slices = <GlitchSlice>[];

    for (int i = 0; i < sliceCount; i++) {
      slices.add(
        GlitchSlice(
          yPosition: _random.nextDouble(),
          height: 0.05 + _random.nextDouble() * 0.15,
          offsetX: (_random.nextDouble() - 0.5) * 100 * intensity,
        ),
      );
    }

    return slices;
  }

  @override
  Widget build(BuildContext context) {
    final intensity = widget.controller.value * widget.intensity;

    if (intensity < 0.01) {
      // No glitch effect
      return widget.child;
    }

    return Stack(
      children: [
        // Base layer with vertical jitter
        Transform.translate(
          offset: Offset(0, _verticalJitter),
          child: widget.child,
        ),

        // Chromatic aberration layers
        if (intensity > 0.2) ...[
          // Red channel shifted left
          Transform.translate(
            offset: Offset(_redOffsetX, _verticalJitter),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.red.withOpacity(0.3 * intensity),
                BlendMode.screen,
              ),
              child: widget.child,
            ),
          ),

          // Blue channel shifted right
          Transform.translate(
            offset: Offset(_blueOffsetX, _verticalJitter),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.blue.withOpacity(0.3 * intensity),
                BlendMode.screen,
              ),
              child: widget.child,
            ),
          ),
        ],

        // Horizontal tearing effect
        if (intensity > 0.4)
          ..._slices.map((slice) => _buildTearSlice(slice, intensity)),

        // Static noise overlay
        if (intensity > 0.6)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.15 * intensity,
                child: _StaticNoise(seed: _random.nextInt(1000)),
              ),
            ),
          ),

        // Scanlines for authenticity
        if (intensity > 0.5)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinesPainter(opacity: 0.1 * intensity),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTearSlice(GlitchSlice slice, double intensity) {
    return Positioned.fill(
      child: ClipRect(
        child: Align(
          alignment: Alignment(0, slice.yPosition * 2 - 1),
          child: FractionallySizedBox(
            heightFactor: slice.height,
            child: Transform.translate(
              offset: Offset(slice.offsetX, _verticalJitter),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for glitch slice
class GlitchSlice {
  final double yPosition; // 0.0 to 1.0
  final double height; // fraction of screen
  final double offsetX; // horizontal displacement

  GlitchSlice({
    required this.yPosition,
    required this.height,
    required this.offsetX,
  });
}

/// Static noise overlay
class _StaticNoise extends StatelessWidget {
  final int seed;

  const _StaticNoise({required this.seed});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _NoisePainter(seed: seed));
  }
}

class _NoisePainter extends CustomPainter {
  final int seed;
  final Random _random;

  _NoisePainter({required this.seed}) : _random = Random(seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final pixelSize = 4.0;

    for (double x = 0; x < size.width; x += pixelSize) {
      for (double y = 0; y < size.height; y += pixelSize) {
        if (_random.nextDouble() > 0.95) {
          // 5% chance for white noise
          final brightness = _random.nextDouble();
          paint.color = Color.fromRGBO(
            (brightness * 255).toInt(),
            (brightness * 255).toInt(),
            (brightness * 255).toInt(),
            0.8,
          );
          canvas.drawRect(Rect.fromLTWH(x, y, pixelSize, pixelSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) => oldDelegate.seed != seed;
}

/// Scanlines painter for CRT monitor effect
class _ScanlinesPainter extends CustomPainter {
  final double opacity;

  _ScanlinesPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinesPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

/// Simplified glitch effect for less intensive scenes
class SimpleGlitchEffect extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const SimpleGlitchEffect({Key? key, required this.child, this.enabled = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.red.withOpacity(0.1),
        BlendMode.screen,
      ),
      child: child,
    );
  }
}

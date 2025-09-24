import 'package:flutter/material.dart';

//https://www.youtube.com/watch?v=Vwd26lP2MpY

class AnimatedGradientBorder extends StatefulWidget {
  const AnimatedGradientBorder({
    super.key,
    this.borderRadius = 30,
    this.shape = BoxShape.rectangle,
    this.thickness = 5,
    this.blurRadius = 30,
    this.spreadRadius = 1,
    this.topColor = Colors.blue,
    this.bottomColor = Colors.purple,
    this.glowOpacity = 0.3,
    this.duration = const Duration(milliseconds: 1000),
    this.child,
  });

  // BoxShape.circle or BoxShape.rectangle
  final BoxShape shape;

  // Border radius of the rounded rectangle border. Only used if shape is BoxShape.rectangle
  final double borderRadius;

  // Thickness of the border. Applies padding to child
  final double thickness;

  /// Blur radius of the glow effect
  final double blurRadius;

  /// Spread radius of the glow effect
  final double spreadRadius;

  /// The color of the top of the gradient
  final Color topColor;

  /// The color of the bottom of the gradient
  final Color bottomColor;

  /// The opacity of the glow effect.
  final double glowOpacity;

  /// The duration of the animation. The default is 500 milliseconds.
  final Duration duration;

  final Widget? child;

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _topLeftAlignAnim;
  late Animation<Alignment> _bottomRightAlignAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.duration, vsync: this);

    // top left -> top right -> bottom right -> bottom left
    _topLeftAlignAnim = TweenSequence<Alignment>([
      TweenSequenceItem<Alignment>(
        tween: Tween<Alignment>(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: Tween<Alignment>(
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: Tween<Alignment>(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: Tween<Alignment>(
          begin: Alignment.bottomLeft,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
    ]).animate(_controller);

    // bottom right -> bottom left -> top left -> top right
    _bottomRightAlignAnim = TweenSequence<Alignment>([
      TweenSequenceItem<Alignment>(
        tween: Tween<Alignment>(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: Tween<Alignment>(
          begin: Alignment.bottomLeft,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: Tween<Alignment>(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: Tween<Alignment>(
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
    ]).animate(_controller);

    // Keep the animation going forever
    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // provides access to constraints
      builder: (context, constraints) {
        /// example includes a ClipPath, but I have it removed for now. Considered an expensive operation
        /// Since we can place widgets on top, I don't think it's necessary to do the cutout
        /// May need the cutout if we want to apply the border to a transparent item though
        /// Could make it an optional param. Would require adjusting the code for _CenterCutOut

        return Stack(
          children: [
            _buildAnimatedContent(context, constraints),

            if (widget.child != null)
              Padding(
                padding: EdgeInsets.all(widget.thickness),
                child: widget.shape == BoxShape.circle
                    ? ClipOval(child: widget.child!)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                        child: widget.child!,
                      ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            // Shadow containers
            ..._buildShadowContainers(context, constraints),

            // animated gradient
            Container(
              decoration: BoxDecoration(
                // gradient: SweepGradient(
                //   colors: [Colors.blue, Colors.purple, Colors.blue],
                // ),
                gradient: LinearGradient(
                  begin: _topLeftAlignAnim.value,
                  end: _bottomRightAlignAnim.value,
                  colors: [widget.topColor, widget.bottomColor],
                ),
                borderRadius: widget.shape != BoxShape.circle
                    ? BorderRadius.circular(widget.borderRadius)
                    : null,
                shape: widget.shape,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildShadowContainers(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return [
      // Unmoving container with the main color as a shadow
      Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: widget.shape,
          boxShadow: [
            BoxShadow(
              color: widget.topColor.withValues(alpha: widget.glowOpacity),
              blurRadius: widget.blurRadius,
              spreadRadius: widget.spreadRadius,
            ),
          ],
        ),
      ),
      // Smaller, moving container that starts in the bottom right, moving with the secondary color
      Align(
        alignment: _bottomRightAlignAnim.value,
        child: Container(
          width: constraints.maxWidth * 0.95,
          height: constraints.maxHeight * 0.95,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: widget.shape,
            boxShadow: [
              BoxShadow(
                color: widget.bottomColor.withValues(alpha: widget.glowOpacity),
                blurRadius: widget.blurRadius,
                spreadRadius: widget.spreadRadius,
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

class _CenterCutPath extends CustomClipper<Path> {
  final double radius;
  final double thickness;

  _CenterCutPath({this.radius = 0, this.thickness = 1});

  @override
  Path getClip(Size size) {
    final rect = Rect.fromLTRB(
      -size.width,
      -size.width,
      size.width * 2,
      size.height * 2,
    );
    final double width = size.width - thickness * 2;
    final double height = size.height - thickness * 2;

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(thickness, thickness, width, height),
          Radius.circular(radius - thickness),
        ),
      )
      ..addRect(rect);

    return path;
  }

  @override
  bool shouldReclip(covariant _CenterCutPath oldClipper) {
    return oldClipper.radius == radius || oldClipper.thickness == thickness;
  }
}

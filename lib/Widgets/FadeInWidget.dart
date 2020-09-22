import 'package:flutter/material.dart';

class FadeInWidget extends StatefulWidget {
  final Widget child;
  FadeInWidget({@required this.child});
  @override
  _FadeInWidgetState createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  Animation _animation;
  AnimationController _controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    Animation curve =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _animation = Tween(begin: 0.0, end: 1.0).animate(curve);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      child: widget.child,
      opacity: _animation,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:provider/provider.dart';

import 'LoginSingup/login.dart';
import 'LoginSingup/login_options.dart';
import 'LoginSingup/signup.dart';
import 'LoginSingup/singup_option.dart';

class SingUpLoginPage extends StatefulWidget {
  bool login;
  SingUpLoginPage({this.login});
  static String id = 'SingUpLoginPage';
  @override
  _SingUpLoginPageState createState() => _SingUpLoginPageState();
}

class _SingUpLoginPageState extends State<SingUpLoginPage> {
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (_, mainViewModel, child) {
        return Scaffold(
          backgroundColor: kIcons,
          body: ValueListenableBuilder<bool>(
            valueListenable: mainViewModel.isSigningSignUping,
            builder: (context, value, child) {
              return Stack(
                  children: value
                      ? [
                          child,
                          Center(
                              child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                                widget.login ? Colors.white : kPrimary),
                          ))
                        ]
                      : [child]);
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (!widget.login) {
                          mainViewModel.passwordController.clear();
                          mainViewModel.emailController.clear();
                        }
                        widget.login = true;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.ease,
                      height: widget.login
                          ? MediaQuery.of(context).size.height * 0.6
                          : MediaQuery.of(context).size.height * 0.4,
                      child: CustomPaint(
                        painter: CurvePainter(widget.login),
                        child: Container(
                          padding:
                              EdgeInsets.only(bottom: widget.login ? 0 : 55),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                child: widget.login ? Login() : LoginOption(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (widget.login) {
                          mainViewModel.passwordController.clear();
                          mainViewModel.emailController.clear();
                        }
                        widget.login = false;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.ease,
                      height: widget.login
                          ? MediaQuery.of(context).size.height * 0.4
                          : MediaQuery.of(context).size.height * 0.6,
                      child: Container(
                          color: Colors.transparent,
                          padding: EdgeInsets.only(top: widget.login ? 55 : 0),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                child:
                                    !widget.login ? SignUp() : SignUpOption(),
                              ),
                            ),
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CurvePainter extends CustomPainter {
  bool outterCurve;

  CurvePainter(this.outterCurve);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = kPrimary;
    paint.style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
        size.width * 0.5,
        outterCurve ? size.height + 110 : size.height - 110,
        size.width,
        size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

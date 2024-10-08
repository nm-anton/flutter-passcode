library passcode_screen;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';

typedef PasswordEnteredCallback = void Function(String text);
typedef IsValidCallback = void Function();
typedef CancelCallback = void Function();

class PasscodeScreen extends StatefulWidget {
  final Widget title;
  final int passwordDigits;
  final PasswordEnteredCallback passwordEnteredCallback;
  // Cancel button and delete button will be switched based on the screen state
  final Widget deleteButton;
  final Widget forgotPassButton;
  final Stream<bool> shouldTriggerVerification;
  final CircleUIConfig circleUIConfig;
  final KeyboardUIConfig keyboardUIConfig;

  //isValidCallback will be invoked after passcode screen will pop.
  final IsValidCallback? isValidCallback;
  final CancelCallback? cancelCallback;

  final Color? backgroundColor;
  final Widget? bottomWidget;
  final List<String>? digits;

  final void Function()? onForgotPasswordPressed;

  PasscodeScreen({
    Key? key,
    required this.title,
    this.passwordDigits = 6,
    required this.passwordEnteredCallback,
    required this.deleteButton,
    required this.shouldTriggerVerification,
    required this.onForgotPasswordPressed,
    required this.forgotPassButton,
    this.isValidCallback,
    CircleUIConfig? circleUIConfig,
    KeyboardUIConfig? keyboardUIConfig,
    this.bottomWidget,
    this.backgroundColor,
    this.cancelCallback,
    this.digits,
  })  : circleUIConfig = circleUIConfig ?? const CircleUIConfig(),
        keyboardUIConfig = keyboardUIConfig ?? const KeyboardUIConfig(),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  late StreamSubscription<bool> streamSubscription;
  String enteredPasscode = '';

  @override
  initState() {
    super.initState();
    streamSubscription = widget.shouldTriggerVerification
        .listen((isValid) => _showValidation(isValid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return _buildPortraitPasscodeScreen();
          },
        ),
      ),
    );
  }

  _buildPortraitPasscodeScreen() => Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 500,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.title,
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buildCircles(),
                        ),
                      ),
                      _buildKeyboard(),
                      widget.bottomWidget ?? Container()
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  _buildLandscapePasscodeScreen() => Stack(
        children: [
          Positioned(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                widget.title,
                                Container(
                                  margin: const EdgeInsets.only(top: 20),
                                  height: 40,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: _buildCircles(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        widget.bottomWidget != null
                            ? Positioned(
                                child: Align(
                                    alignment: Alignment.topCenter,
                                    child: widget.bottomWidget),
                              )
                            : Container()
                      ],
                    ),
                  ),
                  _buildKeyboard(),
                ],
              ),
            ),
          ),
          Positioned(
            child: Align(
              alignment: Alignment.bottomRight,
              child: DeleteButton(
                margin: widget.keyboardUIConfig.digitInnerMargin,
                onPressed: _onDeleteCancelButtonPressed,
                child: widget.deleteButton,
              ),
              // child: _buildDeleteButton(),
            ),
          )
        ],
      );

  _buildKeyboard() => Container(
        child: Keyboard(
          onKeyboardTap: _onKeyboardButtonPressed,
          keyboardUIConfig: widget.keyboardUIConfig,
          digits: widget.digits,
          deleteWidget: widget.deleteButton,
          forgotPassWidget: widget.forgotPassButton,
          onDeletePressed: _onDeleteCancelButtonPressed,
          onForgotPasswordPressed: widget.onForgotPasswordPressed,
        ),
      );

  List<Widget> _buildCircles() {
    var list = <Widget>[];
    var config = widget.circleUIConfig;
    for (int i = 0; i < widget.passwordDigits; i++) {
      list.add(
        Container(
          margin: EdgeInsets.all(8),
          child: Circle(
            filled: i < enteredPasscode.length,
            circleUIConfig: config,
          ),
        ),
      );
    }
    return list;
  }

  _onDeleteCancelButtonPressed() {
    if (enteredPasscode.length > 0) {
      setState(() {
        enteredPasscode =
            enteredPasscode.substring(0, enteredPasscode.length - 1);
      });
    }
  }

  _onKeyboardButtonPressed(String text) {
    if (text == Keyboard.deleteButton) {
      _onDeleteCancelButtonPressed();
      return;
    }
    setState(() {
      if (enteredPasscode.length < widget.passwordDigits) {
        enteredPasscode += text;
        if (enteredPasscode.length == widget.passwordDigits) {
          widget.passwordEnteredCallback(enteredPasscode);
        }
      }
    });
  }

  @override
  didUpdateWidget(PasscodeScreen old) {
    super.didUpdateWidget(old);
    // in case the stream instance changed, subscribe to the new one
    if (widget.shouldTriggerVerification != old.shouldTriggerVerification) {
      streamSubscription.cancel();
      streamSubscription = widget.shouldTriggerVerification
          .listen((isValid) => _showValidation(isValid));
    }
  }

  @override
  dispose() {
    streamSubscription.cancel();
    super.dispose();
  }

  _showValidation(bool isValid) {
    if (isValid) {
      Navigator.maybePop(context).then((pop) => _validationCallback());
    }
  }

  _validationCallback() {
    if (widget.isValidCallback != null) {
      widget.isValidCallback!();
    } else {
      print(
          "You didn't implement validation callback. Please handle a state by yourself then.");
    }
  }
}

class DeleteButton extends StatelessWidget {
  const DeleteButton(
      {Key? key, this.onPressed, required this.margin, required this.child})
      : super(key: key);

  final void Function()? onPressed;
  final EdgeInsetsGeometry margin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      child: CupertinoButton(
        onPressed: onPressed,
        child: Container(
          margin: margin,
          child: child,
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';

class PasswordStatusContainer extends StatefulWidget {
  final bool isOn;
  final ValueChanged<bool> onChanged;

  PasswordStatusContainer({required this.isOn, required this.onChanged});

  @override
  _PasswordStatusContainerState createState() =>
      _PasswordStatusContainerState();
}

class _PasswordStatusContainerState extends State<PasswordStatusContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Room Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: widget.isOn,
                    onChanged: widget.onChanged,
                    activeColor: Colors.white, // Color when switch is on
                    inactiveThumbColor: Colors.grey, // Color when switch is off
                    inactiveTrackColor: Colors.grey
                        .withOpacity(0.5), // Track color when switch is off
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

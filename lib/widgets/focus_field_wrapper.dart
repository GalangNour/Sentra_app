import 'package:flutter/material.dart';

class FocusFieldWrapper extends StatefulWidget {
  final Widget Function(bool hasFocus) child;
  final Color focusColor;

  const FocusFieldWrapper({
    super.key,
    required this.child,
    required this.focusColor,
  });

  @override
  State<FocusFieldWrapper> createState() => _FocusFieldWrapperState();
}

class _FocusFieldWrapperState extends State<FocusFieldWrapper> {
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: widget.child(_hasFocus),
      ),
    );
  }
}

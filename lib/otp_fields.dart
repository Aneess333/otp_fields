library otp_fields;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';

class OtpFieldsCustom extends StatefulWidget {
  const OtpFieldsCustom(
      {Key? key,
      required this.context,
      required this.numberOfFields,
      required this.onCodeChanged,
      this.autofillHints,
      this.autofillOtp,
      this.filledBorderColor,
      this.emptyBorderColor,
      this.focusedBorderColor,
      this.style,
      this.backgroundColor})
      : super(key: key);
  final BuildContext context;

  ///Number of OTP fields you want in your project
  final int numberOfFields;

  ///Otp to autofill in the otp boxes
  final String? autofillOtp;

  ///Filled Otp field border color
  final Color? filledBorderColor;

  ///Empty Otp field border color
  final Color? emptyBorderColor;

  ///Focused Otp field border color
  final Color? focusedBorderColor;

  ///Text Style for otp fields
  final TextStyle? style;

  ///Background color of the otp boxes
  final Color? backgroundColor;

  /// callback on otp change
  final Function(String) onCodeChanged;

  /// A list of strings that helps the autofill service identify the type of this text input.
  final List<String>? autofillHints;

  @override
  State<OtpFieldsCustom> createState() => _OtpFieldsCustomState();
}

class _OtpFieldsCustomState extends State<OtpFieldsCustom> {
  late List<FocusNode?> _focusNodes;
  late List<TextEditingController?> _textControllers;
  late List<FocusNode?> _focusNodesKeyboard;
  late List<String?> _verificationCode;

  @override
  void initState() {
    super.initState();
    _verificationCode = List<String?>.filled(widget.numberOfFields, null);
    _focusNodes = List<FocusNode?>.filled(widget.numberOfFields, null);
    _focusNodesKeyboard = List<FocusNode?>.filled(widget.numberOfFields, null);
    _textControllers = List<TextEditingController?>.filled(
      widget.numberOfFields,
      null,
    );
  }

  @override
  void dispose() {
    for (var controller in _textControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autofillOtp != null) {
      _handlePaste(widget.autofillOtp ?? "");
    }
    return generateTextFields(widget.context);
  }

  void addFocusNodeToEachTextField({required int index}) {
    if (_focusNodes[index] == null) {
      _focusNodes[index] = FocusNode();
    }
    if (_focusNodesKeyboard[index] == null) {
      _focusNodesKeyboard[index] = FocusNode();
    }
  }

  void addTextEditingControllerToEachTextField({required int index}) {
    if (_textControllers[index] == null) {
      _textControllers[index] = TextEditingController();
      _textControllers[index]?.text = "\u200b";
    }
  }

  Widget generateTextFields(BuildContext context) {
    List<Widget> textFields = [];
    textFields.addAll(List.generate(widget.numberOfFields, (int i) {
      addFocusNodeToEachTextField(index: i);
      addTextEditingControllerToEachTextField(index: i);
      return _buildOtpField(
        index: i,
        context: widget.context,
      );
    }));
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: textFields,
      ),
    );
  }

  Color getBorderColor(int index) {
    if (_textControllers[index] != null && _focusNodes[index] != null) {
      if (_focusNodes[index]?.hasFocus == true) {
        return widget.focusedBorderColor ?? Theme.of(context).primaryColor;
      } else if (_textControllers[index]?.text.isNotEmpty == true &&
          _textControllers[index]?.text != "\u200b") {
        return widget.filledBorderColor ?? CustomColors.blackColor;
      } else {
        return widget.emptyBorderColor ?? CustomColors.lightWhiteColor;
      }
    }
    return widget.emptyBorderColor ?? CustomColors.lightWhiteColor;
  }

  Widget _buildOtpField({required int index, required BuildContext context}) {
    if (_focusNodes[index] != null) {
      _focusNodes[index]?.addListener(() {
        setState(() {});
      });
    }
    return GestureDetector(
      onTap: () {
        for (int i = 0; i < _focusNodes.length; i++) {
          if (_focusNodes[i] != null && _focusNodes[i]?.hasFocus == true) {
            _focusNodes[i]?.unfocus();
          }
        }
        FocusScope.of(context).requestFocus(_focusNodes[index]);
      },
      child: Container(
        height: MediaQuery.of(context).size.width * 0.15,
        decoration: BoxDecoration(
            color: widget.backgroundColor ?? CustomColors.white,
            border: Border.all(color: getBorderColor(index)),
            borderRadius: BorderRadius.circular(8)),
        width: MediaQuery.of(context).size.width * 0.12,
        child: Center(
          child: TextField(
            controller: _textControllers[index],
            focusNode: _focusNodes[index],
            cursorHeight: 16.0,
            cursorColor: Theme.of(context).primaryColor,
            autofillHints: widget.autofillHints,
            onChanged: (v) async {
              if (v.length > 2) {
                _handlePaste(v);
                return;
              }
              setState(() {});
              if (v != "\u200b" && v.isNotEmpty) {
                if (_verificationCode[index]?.isEmpty == true ||
                    _verificationCode[index] == null) {
                  _verificationCode[index] = v;
                } else {
                  _textControllers[index]?.text =
                      _verificationCode[index] ?? "";
                }
                if (index != widget.numberOfFields - 1) {
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                } else {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              } else if (v.isEmpty) {
                _verificationCode[index] = v;
                if (index != 0) {
                  FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                }
                _textControllers[index]?.text = "\u200b";
                if (index == 0) {
                  _textControllers[index]?.selection =
                      TextSelection.fromPosition(TextPosition(
                          offset: _textControllers[index]?.text.length ?? 0));
                }
              }
              onCodeChanged();
            },
            style: widget.style ??
                Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w500, height: 1),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ),
    );
  }

  void _handlePaste(String str) {
    if (str.length > widget.numberOfFields) {
      str = str.substring(0, widget.numberOfFields);
    }

    for (int i = 0; i < str.length; i++) {
      String digit = str.substring(i, i + 1);
      _textControllers[i]?.text = digit;
      _verificationCode[i] = digit;
    }
    if (str.length == widget.numberOfFields) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      FocusScope.of(context).requestFocus(_focusNodes[str.length]);
    }
    onCodeChanged();
  }

  void onCodeChanged() {
    String code = '';
    for (int i = 0; i < _verificationCode.length; i++) {
      if (_verificationCode[i] != null) {
        code = code + (_verificationCode[i] ?? "");
      }
    }
    widget.onCodeChanged(code);
  }
}

import 'package:flutter/material.dart';

class ExpandingInputFab extends StatefulWidget {
  const ExpandingInputFab({this.onExpansionChanged, this.onInputChanged, super.key});

  final Function(bool expanded)? onExpansionChanged;
  final Function(String text)? onInputChanged;

  @override
  State<StatefulWidget> createState() => _ExpandingInputFabState();
}

class _ExpandingInputFabState extends State<ExpandingInputFab> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isExtended = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedSize(
            alignment: Alignment.bottomRight,
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child:  Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: _isExtended ? screenWidth * 0.75 : 0.0,
                    child: _isExtended ? TextField(
                      focusNode: _inputFocusNode,
                      onChanged: widget.onInputChanged,
                      controller: _inputController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          isDense: true
                      ),
                    ) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _isExtended = !_isExtended;
                        });
                        if (_isExtended) _inputFocusNode.requestFocus();
                        _inputController.clear();
                        widget.onInputChanged?.call("");
                        widget.onExpansionChanged?.call(_isExtended);
                      },
                      splashRadius: 16,
                      icon: _isExtended ? const Icon(Icons.close) : const Icon(Icons.search),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
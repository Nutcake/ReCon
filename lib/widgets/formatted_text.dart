import 'package:flutter/material.dart';
import 'package:recon/string_formatter.dart';

class FormattedText extends StatelessWidget {
  const FormattedText(this.formatTree, {this.style, this.textAlign, this.overflow, this.softWrap, this.maxLines, super.key});

  final FormatNode formatTree;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final bool? softWrap;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (formatTree.isUnformatted) {
      return Text(
        formatTree.text,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        softWrap: softWrap,
        maxLines: maxLines,
      );
    } else {
      return RichText(
        text: formatTree.toTextSpan(baseStyle: style ?? Theme.of(context).textTheme.bodyMedium!),
        textAlign: textAlign ?? TextAlign.start,
        overflow: overflow ?? TextOverflow.clip,
        softWrap: softWrap ?? true,
        maxLines: maxLines,
      );
    }
  }
}

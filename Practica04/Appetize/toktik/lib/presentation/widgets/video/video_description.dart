import 'package:flutter/material.dart';

class VideoDescription extends StatefulWidget {
  final String text;
  const VideoDescription({super.key, required this.text});
  @override
  State<VideoDescription> createState() => _VideoDescriptionState();
}

class _VideoDescriptionState extends State<VideoDescription> {
  bool _expanded = false;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = Theme.of(context).textTheme.bodyLarge!
          .copyWith(color: Colors.white);
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: 2,
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflow = painter.didExceedMaxLines;
      painter.dispose();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_expanded)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .28,
              ),
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scroll,
                  primary: false,
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(widget.text, style: style),
                ),
              ),
            )
          else
            Text(
              widget.text,
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (overflow)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'menos' : '... más'),
            ),
        ],
      );
    },
  );
}

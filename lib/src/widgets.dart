import 'package:flutter/material.dart';

class SimpleLoading extends StatelessWidget {
  final double height;

  const SimpleLoading({Key key, this.height = 200}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class SimpleFailed extends StatelessWidget {
  final VoidCallback retry;

  final String message;

  const SimpleFailed({Key key, this.retry, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 200),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            message != null ? Text(message) : Container(),
            SizedBox(height: 8),
            RaisedButton(
              child: Text(MaterialLocalizations.of(context)
                  .refreshIndicatorSemanticLabel),
              onPressed: retry,
            )
          ],
        ),
      ),
    );
  }
}

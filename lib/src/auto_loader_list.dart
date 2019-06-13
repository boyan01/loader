import 'package:loader/loader.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import 'package:async/async.dart';
import 'package:scoped_model/scoped_model.dart';

///a list view
///auto load more when reached the bottom
class AutoLoadMoreList<T> extends StatefulWidget {
  ///return the items loaded
  ///null indicator failed
  final LoadMoreDelegate<T> loadMore;

  ///build list tile with item
  final Widget Function(BuildContext context, T item) builder;

  const AutoLoadMoreList(
      {Key key, @required this.loadMore, @required this.builder})
      : super(key: key);

  @override
  _AutoLoadMoreListState<T> createState() => _AutoLoadMoreListState<T>();
}

class _AutoLoadMoreList<T> extends Model with AutoLoadMoreMixin<T> {
  final LoadMoreDelegate<T> delegate;

  _AutoLoadMoreList({@required this.delegate}) {
    loadMore();
  }

  @override
  Future<Result<List<T>>> loadData(int offset) {
    return delegate(offset);
  }
}

class _AutoLoadMoreListState<T> extends State<AutoLoadMoreList<T>> {
  _AutoLoadMoreList _autoLoader;

  @override
  void initState() {
    super.initState();
    _autoLoader = _AutoLoadMoreList(delegate: widget.loadMore);
    _autoLoader.addListener(_onDataChanged);
  }

  @override
  void didUpdateWidget(AutoLoadMoreList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadMore != widget.loadMore) {
      _autoLoader.removeListener(_onDataChanged);
      _autoLoader = _AutoLoadMoreList(delegate: widget.loadMore);
      _autoLoader.addListener(_onDataChanged);
    }
  }

  @override
  void dispose() {
    _autoLoader.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        _autoLoader.loadMore(notification: notification);
        return false;
      },
      child: ListView.builder(
          itemCount: _autoLoader.size,
          itemBuilder: _autoLoader.createBuilder(_autoLoader.items,
              builder: (context, index) {
            return widget.builder(context, _autoLoader.items[index]);
          })),
    );
  }
}
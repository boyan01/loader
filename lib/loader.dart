library loader;

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loader/src/widgets.dart';
import 'package:scoped_model/scoped_model.dart';

export 'package:async/async.dart' show Result;
export 'package:async/async.dart' show ErrorResult;
export 'package:async/async.dart' show ValueResult;

export 'src/auto_loader_list.dart';

part 'src/auto_loader.dart';

///build widget when Loader has completed loading...
typedef LoaderWidgetBuilder<T> = Widget Function(
    BuildContext context, T result);

void _defaultFailedHandler(BuildContext context, ErrorResult result) {
  debugPrint("error:\n ${result.stackTrace}");
}

class Loader<T> extends StatefulWidget {
  const Loader(
      {Key? key,
      required this.loadTask,
      required this.builder,
      this.loadingBuilder,
      this.initialData,
      this.onError = _defaultFailedHandler,
      this.errorBuilder})
      : super(key: key);

  static Widget buildSimpleLoadingWidget<T>(BuildContext context) {
    return SimpleLoading(height: 200);
  }

  static Widget buildSimpleFailedWidget(
      BuildContext context, ErrorResult result) {
    return SimpleFailed(
      message: result.error.toString(),
      retry: () {
        Loader.of(context)!.refresh();
      },
    );
  }

  final FutureOr<T>? initialData;

  ///task to load
  ///returned future'data will send by [LoaderWidgetBuilder]
  final Future<Result<T>> Function() loadTask;

  final LoaderWidgetBuilder<T> builder;

  final Widget Function(BuildContext context, ErrorResult result)? errorBuilder;

  ///callback to handle error, could be null
  ///
  /// if null, will do nothing when an error occurred in [loadTask]
  final void Function(BuildContext context, ErrorResult result) onError;

  ///widget display when loading
  ///if null ,default to display a white background with a Circle Progress
  final WidgetBuilder? loadingBuilder;

  static LoaderState<T>? of<T>(BuildContext context) {
    return context.findAncestorStateOfType<LoaderState>() as LoaderState<T>?;
  }

  @override
  State<StatefulWidget> createState() => LoaderState<T>();
}

@visibleForTesting
const defaultErrorMessage = '啊哦，出错了~';

class LoaderState<T> extends State<Loader> {
  bool get isLoading => _loadingTask != null;

  CancelableOperation<Result<T>>? _loadingTask;

  Result<T>? value;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      scheduleMicrotask(() async {
        final data = await widget.initialData;
        if (data != null) {
          await _loadData(Future.value(Result.value(data)), force: true);
        }
        await refresh();
      });
    } else {
      refresh();
    }
  }

  @override
  Loader<T> get widget => super.widget as Loader<T>;

  ///refresh data
  ///force: true to force refresh when a loading ongoing
  Future<void> refresh({bool force: false}) async {
    await _loadData(widget.loadTask(), force: false);
  }

  Future<Result<T>> _loadData(Future<Result<T>> future, {bool force = false}) {
    if (_loadingTask != null && !force) {
      return _loadingTask!.value;
    }
    _loadingTask?.cancel();
    _loadingTask = CancelableOperation<Result<T>>.fromFuture(future)
      ..value.then((result) {
        if (result.isError) {
          _onError(result as ErrorResult);
        } else {
          value = result;
        }
      }).catchError((e, StackTrace stack) {
        _onError(Result.error(e, stack) as ErrorResult);
      }).whenComplete(() {
        _loadingTask = null;
        setState(() {});
      });
    //notify if should be in loading status
    setState(() {});
    return _loadingTask!.value;
  }

  void _onError(ErrorResult result) {
    debugPrint(result.stackTrace.toString());

    if (value == null || value!.isError) {
      value = result;
    }
    widget.onError(context, result);
  }

  @override
  void dispose() {
    super.dispose();
    _loadingTask?.cancel();
    _loadingTask = null;
  }

  @override
  Widget build(BuildContext context) {
    if (value != null) {
      return LoaderResultWidget<T>(
          result: value!,
          valueBuilder: widget.builder,
          errorBuilder: widget.errorBuilder ?? Loader.buildSimpleFailedWidget);
    }
    return (widget.loadingBuilder ?? Loader.buildSimpleLoadingWidget)(context);
  }
}

@visibleForTesting
class LoaderResultWidget<T> extends StatelessWidget {
  final Result<T> result;

  final LoaderWidgetBuilder<T> valueBuilder;
  final Widget Function(BuildContext context, ErrorResult result) errorBuilder;

  const LoaderResultWidget(
      {Key? key,
      required this.result,
      required this.valueBuilder,
      required this.errorBuilder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result.isValue) {
      return valueBuilder(context, result.asValue!.value);
    } else {
      return errorBuilder(context, result as ErrorResult);
    }
  }
}

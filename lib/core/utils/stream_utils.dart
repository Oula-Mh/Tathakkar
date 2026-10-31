import 'dart:async';
import 'package:dartz/dartz.dart';

import '../errors/error_mapper.dart';
import '../errors/failures.dart';

/// Combines the latest values of 3 streams (tiny rxdart replacement).
Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combiner,
) {
  late StreamController<R> controller;
  final subs = <StreamSubscription<dynamic>>[];
  A? va;
  B? vb;
  C? vc;
  var ha = false, hb = false, hc = false;

  void emit() {
    if (ha && hb && hc) controller.add(combiner(va as A, vb as B, vc as C));
  }

  controller = StreamController<R>(
    onListen: () {
      subs.add(a.listen((v) {
        va = v;
        ha = true;
        emit();
      }, onError: controller.addError));
      subs.add(b.listen((v) {
        vb = v;
        hb = true;
        emit();
      }, onError: controller.addError));
      subs.add(c.listen((v) {
        vc = v;
        hc = true;
        emit();
      }, onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}

/// Maps a data stream to Either, turning stream errors into Failures
/// so a broken stream never crashes a BLoC.
Stream<Either<Failure, T>> eitherStream<T>(Stream<T> source) =>
    source.transform(StreamTransformer<T, Either<Failure, T>>.fromHandlers(
      handleData: (data, sink) => sink.add(Right(data)),
      handleError: (e, st, sink) => sink.add(Left(ErrorMapper.toFailure(e, st))),
    ));

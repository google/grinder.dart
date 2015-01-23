// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.utils;

import 'dart:async';
import 'dart:convert' show UTF8;
import 'dart:io';

Future<String> httpGet(String url) {
  HttpClient client = new HttpClient();
  return client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
    return request.close();
  }).then((HttpClientResponse response) {
    return response.toList();
  }).then((List<List> data) {
    return UTF8.decode(data.reduce((a, b) => a.addAll(b)));
  });
}

class ResettableTimer implements Timer {
  final Duration duration;
  final Function callback;

  Timer _timer;

  ResettableTimer(this.duration, this.callback) {
    _timer = new Timer(duration, callback);
  }

  void reset() {
    _timer.cancel();
    _timer = new Timer(duration, callback);
  }

  void cancel() => _timer.cancel();

  bool get isActive => _timer.isActive;
}

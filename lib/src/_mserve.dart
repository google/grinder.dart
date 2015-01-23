// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * A very lightweight web server.
 *
 * **Note:** This library will likely move out of the `grinder` package.
 */
library grinder.mserve;

import 'dart:async';
import 'dart:io';

import 'package:http_server/http_server.dart';

/**
 * A very lightweight web server.
 *
 * **Note:** This library will likely move out of the `grinder` package.
 */
class MicroServer {
  static Future<MicroServer> start({String path, int port: 8000}) {
    if (path == null) path = '.';

    return HttpServer.bind('0.0.0.0', port).then((server) {
      return new MicroServer._(path, server);
    });
  }

  final String _path;
  final HttpServer _server;
  final StreamController _errorController = new StreamController.broadcast();

  MicroServer._(this._path, this._server) {
    VirtualDirectory vDir = new VirtualDirectory(path);
    vDir.allowDirectoryListing = true;
    vDir.jailRoot = false;

    runZoned(() {
      _server.listen(
          vDir.serveRequest,
          onError: (e) => _errorController.add(e));
    }, onError: (e) => _errorController.add(e));
  }

  String get host => _server.address.host;

  String get path => _path;

  int get port => _server.port;

  String get urlBase => 'http://${host}:${port}/';

  Stream get onError => _errorController.stream;

  Future destroy() => _server.close();
}

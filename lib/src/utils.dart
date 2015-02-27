// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.utils;

import 'dart:async';
import 'dart:collection';
import 'dart:convert' show UTF8;
import 'dart:mirrors';
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

String camelToDashes(String input) {
  var segment = new RegExp(r'.[^A-Z]*');
  var matches = segment.allMatches(input);
  return matches
      .map((Match match) =>
          withCapitalization(
              match.input.substring(match.start, match.end),
              false))
      .join('-');
}

// Upper-case or lower-case the first charater of a String.
String withCapitalization(String s, bool capitalized) {
  if (s.isEmpty || capitalized == null) return s;
  var firstLetter = s[0];
  firstLetter = capitalized ?
     firstLetter.toUpperCase() :
     firstLetter.toLowerCase();
  return firstLetter + s.substring(1);
}

// TODO: Remove this once this `dart:mirrors` bug is fixed:
//       http://dartbug.com/22601
declarationsEqual(DeclarationMirror decl1, decl2) =>
    decl2 is DeclarationMirror &&
    decl1.owner == decl2.owner &&
    decl1.simpleName == decl2.simpleName;

// TODO: Remove if this becomes supported by `dart:mirrors`:
//       http://dartbug.com/22591
Map<Symbol, DeclarationMirror> resolveExportedDeclarations(LibraryMirror library) {
  var resolved = {}..addAll(library.declarations);
  library.libraryDependencies.forEach((dependency) {
    if (dependency.isExport) {
      var shown = {};
      var hidden = [];
      dependency.combinators.forEach((combinator) {
        if (combinator.isShow) {
          combinator.identifiers.forEach((id) {
            shown[id] = dependency.targetLibrary.declarations[id];
          });
        }
        if (combinator.isHide) {
          hidden.addAll(combinator.identifiers);
        }
      });
      if (shown.isEmpty) {
        shown.addAll(dependency.targetLibrary.declarations);
        hidden.forEach(shown.remove);
      }
      resolved.addAll(shown);
    }
  });
  return new UnmodifiableMapView(resolved);
}

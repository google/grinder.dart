// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test;

import 'dart:io';

import 'package:grinder/grinder.dart';

/**
 * A small command-line utility to leverage the grinder APIs to make it easy to
 * run CLI or web app tests.
 */
void main(List<String> args) {
  if (args.length != 1) {
    print(
        'usage: pub global run grinder:test <filepath>');
    print(
        '  where <filepath> is either a .dart file (for CLI tests), '
        'or an .html file (for web tests).');
    exit(1);
  }

  String path = args.first;

  if (path.endsWith('.dart')) {
    if (path.contains(Platform.pathSeparator)) {
      String directory = path.substring(0, path.indexOf(Platform.pathSeparator));
      path = path.substring(path.indexOf(Platform.pathSeparator) + 1);
      Tests.runCliTests(directory: directory, testFile: path);
    } else {
      Tests.runCliTests(testFile: path);
    }
  } else if (path.endsWith('.html')) {
    if (path.contains(Platform.pathSeparator)) {
      int index = path.indexOf(Platform.pathSeparator);
      // Handle build/ specially.
      if (path.startsWith('build/')) {
        index = path.indexOf(Platform.pathSeparator, index + 1);
      }
      String directory = path.substring(0, index);
      path = path.substring(index + 1);
      Tests.runWebTests(directory: directory, htmlFile: path)
          .then((_) => exit(0))
          .catchError((e) => exit(1));
    } else {
      Tests.runWebTests(htmlFile: path)
          .then((_) => exit(0))
          .catchError((e) => exit(1));
    }
  } else {
    print('unhandled file type: ${path}');
    exit(1);
  }
}

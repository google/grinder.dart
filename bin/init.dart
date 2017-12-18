// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.init;

import 'dart:io';

/// A command to create a simple, starting `tool/grind.dart` build script.
void main(List args) {
  if (!new File('pubspec.yaml').existsSync()) {
    _fail('This script must be run from the project root.');
  }

  File file = new File('tool${Platform.pathSeparator}grind.dart');

  if (file.existsSync()) {
    _fail('Error: ${file.path} already exists.');
  }

  // Create `tool` if it does not already exist.
  new Directory('tool').createSync();

  file.writeAsStringSync(_grindSampleSource);
  print('Wrote ${file.path}!');
}

void _fail(String message) {
  print(message);
  exit(1);
}

final String _grindSampleSource = '''
import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task()
test() => new TestRunner().testAsync();

@DefaultTask()
@Depends(test)
build() {
  Pub.build();
}

@Task()
clean() => defaultClean();
''';

// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/**
 * A command to create a simple, starting `tool/grind.dart` build script.
 */
void main(List args) {
  File file = new File('tool${Platform.pathSeparator}grind.dart');

  if (file.existsSync()) {
    print('Error: ${file.path} already exists.');
    exit(1);
  }

  file.writeAsStringSync(_grindSampleSource);
  print('Wrote ${file.path}!');
}

final String _grindSampleSource = '''
import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task()
init(GrinderContext context) => defaultInit(context);

@Task(depends: const ['init'])
build(GrinderContext context) {
  Pub.build(context);
}

@Task()
clean(GrinderContext context) => defaultClean(context);
''';

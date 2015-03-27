// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task()
void init() => defaultInit();

@Task()
@Depends(init)
void analyze() {
  Analyzer.analyzePaths(['example/grind.dart']);
  Analyzer.analyzePaths(
      ['lib/grinder.dart', 'lib/grinder_files.dart', 'lib/grinder_tools.dart']);
}

@Task()
@Depends(init)
void tests() {
  Tests.runCliTests();
}

@Task()
@Depends(init)
Future testsWeb() {
  return Tests.runWebTests(directory: 'web', htmlFile: 'web.html');
}

@Task()
@Depends(init)
Future testsBuildWeb() {
  return Pub.buildAsync(directories: ['web']).then((_) {
    return Tests.runWebTests(directory: 'build/web', htmlFile: 'web.html');
  });
}

@Task('Analyze the generated grind script')
@Depends(init)
analyzeInit() {
  Path tempProject = Path.createSystemTemp();

  try {
    File pubspec = tempProject.join('pubspec.yaml').createFile();
    pubspec.writeAsStringSync('name: foo', flush: true);
    runDartScript(
        Path.current.join('bin', 'init.dart').path,
        workingDirectory: tempProject.path);
    Analyzer.analyzePaths([tempProject.join('tool', 'grind.dart').path]);
  } finally {
    tempProject.delete();
  }
}

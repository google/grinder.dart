// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task()
void init(GrinderContext context) => defaultInit(context);

@Task()
@Depends(init)
void analyze(GrinderContext context) {
  Analyzer.analyzePaths(context, ['example/grind.dart']);
  Analyzer.analyzePaths(context,
      ['lib/grinder.dart', 'lib/grinder_files.dart', 'lib/grinder_tools.dart']);
}

@Task()
@Depends(init)
void tests(GrinderContext context) {
  Tests.runCliTests(context);
}

@Task()
@Depends(init)
Future testsWeb(GrinderContext context) {
  return Tests.runWebTests(context, directory: 'web', htmlFile: 'web.html');
}

@Task()
@Depends(init)
Future testsBuildWeb(GrinderContext context) {
  return Pub.buildAsync(context, directories: ['web']).then((_) {
    return Tests.runWebTests(context, directory: 'build/web', htmlFile: 'web.html');
  });
}

@Task('Analyze the generated grind script')
@Depends(init)
analyzeInit(GrinderContext context) {
  Path tempProject = Path.createSystemTemp();

  try {
    File pubspec = tempProject.join('pubspec.yaml').createFile();
    pubspec.writeAsStringSync('name: foo', flush: true);
    runDartScript(context,
        Path.current.join('bin', 'init.dart').path,
        workingDirectory: tempProject.path);
    Analyzer.analyzePaths(context, [tempProject.join('tool', 'grind.dart').path]);
  } finally {
    tempProject.delete();
  }
}

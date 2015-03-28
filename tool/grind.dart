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
  new PubApplication('tuneup')..run(['check']);
}

@Task()
@Depends(init)
void test() => Tests.runCliTests();

@Task('Check that the generated init grind script analyzes well')
@Depends(init)
checkInit() {
  Path temp = Path.createSystemTemp();

  try {
    File pubspec = temp.join('pubspec.yaml').createFile();
    pubspec.writeAsStringSync('name: foo', flush: true);
    runDartScript(Path.current.join('bin', 'init.dart').path, workingDirectory: temp.path);
    Analyzer.analyze(temp.join('tool', 'grind.dart').path, fatalWarnings: true);
  } finally {
    temp.delete();
  }
}

@Task('Gather and send coverage data.')
@Depends(init)
void coverage() {
  final String coverageToken = Platform.environment['REPO_TOKEN'];

  if (coverageToken != null) {
    PubApplication coverallsApp = new PubApplication('dart_coveralls');
    coverallsApp.run(['report',
      '--token', coverageToken,
      '--retry', '2',
      '--exclude-test-files',
      'test/all.dart'
    ]);
  } else {
    log('Skipping coverage task: no environment variable `REPO_TOKEN` found.');
  }
}

@DefaultTask()
@Depends(analyze, test, checkInit, coverage)
void buildbot() => null;

// These tasks require a frame buffer to run.

@Task()
@Depends(init)
Future testsWeb() =>  Tests.runWebTests(directory: 'web', htmlFile: 'web.html');

@Task()
@Depends(init)
Future testsBuildWeb() {
  return Pub.buildAsync(directories: ['web']).then((_) {
    return Tests.runWebTests(directory: 'build/web', htmlFile: 'web.html');
  });
}

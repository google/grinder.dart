// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task()
analyze() => new PubApp.global('tuneup')..runAsync(['check', '--ignore-infos']);

@Task()
test() => new TestRunner().testAsync();

@Task('Apply dartfmt to all Dart source files')
format() => DartFmt.format(existingSourceDirs);

@Task('Check that the generated `init` grind script analyzes well.')
checkInit() {
  FilePath temp = FilePath.createSystemTemp();

  try {
    File pubspec = temp.join('pubspec.yaml').createFile();
    pubspec.writeAsStringSync('name: foo', flush: true);
    Dart.run(FilePath.current.join('bin', 'init.dart').path,
        runOptions: new RunOptions(workingDirectory: temp.path));
    Analyzer.analyze(temp.join('tool', 'grind.dart').path, fatalWarnings: true);
  } finally {
    temp.delete();
  }
}

@Task('Gather and send coverage data.')
void coverage() {
  final String coverageToken = Platform.environment['REPO_TOKEN'];

  if (coverageToken != null) {
    PubApp coverallsApp = new PubApp.global('dart_coveralls');
    coverallsApp.run([
      'report',
      '--token',
      coverageToken,
      '--retry',
      '2',
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

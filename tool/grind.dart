// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';

void main(args) => grind(args);

@Task()
Future<String> analyze() =>
    PubApp.global('tuneup').runAsync(['check', '--ignore-infos']);

@Task()
Future<String> test() {
  // new TestRunner().testAsync();
  return Dart.runAsync(getFile('test/all.dart').path);
}

@Task('Apply dartfmt to all Dart source files')
void format() => DartFmt.format(existingSourceDirs);

@Task('Check that the generated `init` grind script analyzes well.')
void checkInit() {
  final temp = FilePath.createSystemTemp();

  try {
    final pubspec = temp.join('pubspec.yaml').createFile();
    pubspec.writeAsStringSync('name: foo', flush: true);
    Dart.run(FilePath.current.join('bin', 'init.dart').path,
        runOptions: RunOptions(workingDirectory: temp.path));
    Analyzer.analyze(temp.join('tool', 'grind.dart').path, fatalWarnings: true);
  } finally {
    temp.delete();
  }
}

@Task('Gather and send coverage data.')
void coverage() {
  final coverageToken = Platform.environment['COVERAGE_TOKEN'];

  if (coverageToken != null) {
    final coverallsApp = PubApp.global('dart_coveralls');
    coverallsApp.run([
      'report',
      '--retry',
      '2',
      '--exclude-test-files',
      '--token',
      coverageToken,
      'test/all.dart'
    ]);
  } else {
    log('Skipping coverage task: no environment variable `COVERAGE_TOKEN` found.');
  }
}

@DefaultTask()
@Depends(analyze, test, checkInit, coverage)
void buildbot() => null;

@Task()
Future<dynamic> ddc() {
  return DevCompiler().analyzeAsync(getFile('example/grind.dart'));
}

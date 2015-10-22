// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:unscripted/unscripted.dart';

main(args) {

  addTask(new GrinderTask(
      'bump',
      taskFunction: () {
        var releaseType = context.invocation.positionals.first;
        var isPre = context.invocation.options['pre'];
        var preId = context.invocation.options['pre-id'];

        var args = ['bump', releaseType];

        if (isPre) args.add('--pre');
        if (preId != null) args.addAll(['--pre-id', preId]);
        new PubApp.global('den').run(args);
      },
      positionals: [new Positional(valueHelp: 'release type')],
      options: [new Flag(name: 'pre'), new Option(name: 'pre-id')]));

  grind(args);
}
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
  final String coverageToken = Platform.environment['COVERAGE_TOKEN'];

  if (coverageToken != null) {
    PubApp coverallsApp = new PubApp.global('dart_coveralls');
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

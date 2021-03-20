// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';

void main(args) => grind(args);

@Task()
Future<String> analyze() =>
    Dart.runAsync('analyze', arguments: ['--fatal-infos']);

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
    pubspec.writeAsStringSync('''name: foo
environment:
  sdk: '>=2.10.0 <3.0.0'

dependencies:
  grinder:
    path: ${FilePath.current.path}
''', flush: true);
    Dart.run(FilePath.current.join('bin', 'init.dart').path,
        runOptions: RunOptions(workingDirectory: temp.path));
    Process.runSync('pub', ['get'], workingDirectory: temp.path, runInShell: true);
    Analyzer.analyze(temp.join('tool', 'grind.dart').path, fatalWarnings: true);
  } finally {
    temp.delete();
  }
}

@DefaultTask()
@Depends(analyze, test, checkInit)
void buildbot() => null;

@Task()
Future<dynamic> ddc() {
  return DevCompiler().analyzeAsync(getFile('example/grind.dart'));
}

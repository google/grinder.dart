// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  task('init', run: init);
  task('analyze', run: analyze, depends: ['init']);
  task('tests', run: tests, depends: ['init']);
  //task('docs', run: docs, depends: ['analyze']);

  startGrinder(args);
}

void init(GrinderContext context) {
  PubTools pub = new PubTools();
  pub.get(context);
}

void analyze(GrinderContext context) {
  runSdkBinary(context, 'dartanalyzer', arguments: ['lib/grinder.dart']);
  runSdkBinary(context, 'dartanalyzer', arguments: ['lib/grinder_files.dart']);
  runSdkBinary(context, 'dartanalyzer', arguments: ['lib/grinder_utils.dart']);
  runSdkBinary(context, 'dartanalyzer', arguments: ['example/ex1.dart']);
}

void tests(GrinderContext context) {
  runDartScript(context, "test/all.dart");
}

//void docs(GrinderContext context) {
//  FileSet docFiles = new FileSet.fromDir(
//      new Directory('docs'), pattern: '*.html');
//  FileSet sourceFiles = new FileSet.fromDir(
//      new Directory('lib'), pattern: '*.dart', recurse: true);
//
//  if (!docFiles.upToDate(sourceFiles)) {
//    runSdkBinary(context, 'dartdoc',
//        arguments: ['--omit-generation-time',
//                    '--package-root', 'packages/',
//                    '--include-lib', 'grinder,grinder.files,grinder.utils',
//                    'lib/grinder.dart']);
//  }
//}

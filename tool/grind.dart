// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  defineTask('init', taskFunction: init);
  defineTask('analyze', taskFunction: analyze, depends: ['init']);
  defineTask('tests', taskFunction: tests, depends: ['init']);
  defineTask('docs', taskFunction: docs, depends: ['analyze']);

  startGrinder(args);
}

void init(GrinderContext context) {
  PubTools pub = new PubTools();
  pub.get(context);
}

void analyze(GrinderContext context) {
  runSdkBinary(context, 'dartanalyzer', arguments: ['lib/grinder.dart']);
}

void tests(GrinderContext context) {
  runDartScript(context, "test/all.dart");
}

void docs(GrinderContext context) {
  FileSet docFiles = new FileSet.fromDir(
      new Directory('docs'), endsWith: '.html');
  FileSet sourceFiles = new FileSet.fromDir(
      new Directory('lib'), endsWith: '.dart', recurse: true);

  if (!docFiles.upToDate(sourceFiles)) {
    runSdkBinary(context, 'dartdoc',
        arguments: ['--omit-generation-time',
                    '--package-root', 'packages/',
                    '--include-lib', 'grinder,grinder.files,grinder.utils',
                    'lib/grinder.dart']);
  }
}

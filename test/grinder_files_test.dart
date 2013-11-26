// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_files_test;

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:unittest/unittest.dart';

main() {
  group('grinder FileSet', () {
    Directory temp;
    File fileA;
    File fileB;

    setUp(() {
      final String sep = Platform.pathSeparator;

      temp = Directory.systemTemp.createTempSync();

      fileB = new File('${temp.path}${sep}b.txt');
      fileB.writeAsStringSync('b');

      fileA = new File('${temp.path}${sep}a.txt');
      fileA.writeAsStringSync('a');

      File subFile = new File('${temp.path}${sep}foo${sep}sub.txt');
      subFile.createSync(recursive: true);
      subFile.writeAsStringSync('sub');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    test('fromFile ctor', () {
      FileSet fileSet = new FileSet.fromFile(fileA);
      expect(fileSet.files.length, 1);
    });

    test('fromDir ctor', () {
      FileSet fileSet = new FileSet.fromDir(temp, recurse: false);
      expect(fileSet.files.length, 2);

      fileSet = new FileSet.fromDir(temp, recurse: true);
      expect(fileSet.files.length, 3);
    });

    test('exists', () {
      FileSet fileSet = new FileSet.fromFile(fileA);
      expect(fileSet.exists, true);
    });

    test("doesn't exist", () {
      FileSet notExistFileSet = new FileSet.fromFile(new File('noFile'));
      expect(notExistFileSet.exists, false);
    });

    test('upToDate', () {
      FileSet fileSetA = new FileSet.fromFile(fileA);
      FileSet fileSetB = new FileSet.fromFile(fileB);
      expect(fileSetB.upToDate(fileSetA), true);
    });

    test('filename', () {
      final String tempFileName = "temp.txt";
      final String sep = Platform.pathSeparator;
      File tempFile = new File('${temp.path}${sep}tempdir${sep}${tempFileName}');
      expect(fileName(tempFile) == tempFileName, true);
    });
  });
}

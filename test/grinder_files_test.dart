// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_files_test;

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:unittest/unittest.dart';

main() {
  group('grinder.files FileSet', () {
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
  });

  group('grinder.files', () {
    Directory temp;
    final String sep = Platform.pathSeparator;

    setUp(() {
      temp = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    test('fileName', () {
      final String tempFileName = "temp.txt";
      File tempFile = new File('${temp.path}${sep}tempdir${sep}${tempFileName}');
      expect(fileName(tempFile), tempFileName);
    });

    test('fileExt', () {
      final String extension = 'txt';
      final String fileName = 'temp' + '.' + extension;
      File tempFile = new File('${temp.path}${sep}tempdir${sep}${fileName}');
      expect(fileExt(tempFile), extension);

      final fileNameEmptyExt = 'temp.';
      tempFile = new File('${temp.path}${sep}tempdir${sep}${fileNameEmptyExt}');
      expect(fileExt(tempFile), '');
    });

    test('fileExt null', () {
      String fileNameNoExt = 'temp';
      File tempFile =
        new File('${temp.path}${sep}tempdir${sep}${fileNameNoExt}');
      expect(fileExt(tempFile), null);
    });

    test('joinFile', () {
      File tempFile = joinFile(Directory.current, ['dir','test']);
      File expectedFile =
        new File('${Directory.current.path}${sep}dir${sep}test');
      expect(tempFile.path, expectedFile.path);
    });

    test('joinDir', () {
      Directory tempDirectory = joinDir(Directory.current, ['dir','test']);
      Directory expectedDir =
        new Directory('${Directory.current.path}${sep}dir${sep}test');
      expect(tempDirectory.path, expectedDir.path);
    });

    test('copyFile', () {
      final String tempFileName = "copytest.txt";

      File source = joinFile(temp, ['${tempFileName}']);
      source.writeAsStringSync('abcdABCD');

      Directory targetDir = joinDir(temp, ['targetDir']);
      copyFile(source, targetDir);

      File expectedFile = joinFile(targetDir, ['${tempFileName}']);
      expect(expectedFile.readAsStringSync(), 'abcdABCD');
    });

    test('copyDirectory', () {
      Directory sourceDir = joinDir(temp, ['source']);
      sourceDir.createSync();

      joinFile(sourceDir, ['fileA']).writeAsStringSync('abcd');
      joinFile(sourceDir, ['fileB']).writeAsStringSync('efgh');
      joinFile(sourceDir, ['fileC']).writeAsStringSync('1234');

      Directory targetDir = joinDir(temp,['target']);
      copyDirectory(sourceDir, targetDir);

      String expectedResult = joinFile(targetDir, ['fileA']).readAsStringSync() +
                              joinFile(targetDir, ['fileB']).readAsStringSync() +
                              joinFile(targetDir, ['fileC']).readAsStringSync();
      expect(expectedResult, 'abcdefgh1234');
    });

    test('replacePathSeparator', () {
      expect(replacePathSeparator('foo/bar/file'), 'foo${sep}bar${sep}file');
      expect(replacePathSeparator('foo\\bar\\file'), 'foo${sep}bar${sep}file');
    });
  });
}

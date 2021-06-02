// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.files_test;

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:test/test.dart';

final String _sep = Platform.pathSeparator;

void main() {
  group('grinder.files FileSet', () {
    late Directory temp;
    late File fileA;
    late File fileB;

    setUp(() {
      temp = Directory.systemTemp.createTempSync();

      fileB = File('${temp.path}${_sep}b.txt');
      fileB.writeAsStringSync('b');

      fileA = File('${temp.path}${_sep}a.txt');
      fileA.writeAsStringSync('a');

      final subFile = File('${temp.path}${_sep}foo${_sep}sub.txt');
      subFile.createSync(recursive: true);
      subFile.writeAsStringSync('sub');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    test('fromFile ctor', () {
      final fileSet = FileSet.fromFile(fileA);
      expect(fileSet.files.length, 1);
    });

    test('fromDir ctor', () {
      var fileSet = FileSet.fromDir(temp, recurse: false);
      expect(fileSet.files.length, 2);

      fileSet = FileSet.fromDir(temp, recurse: true);
      expect(fileSet.files.length, 3);
    });

    test('exists', () {
      final fileSet = FileSet.fromFile(fileA);
      expect(fileSet.exists, true);
    });

    test("doesn't exist", () {
      final notExistFileSet = FileSet.fromFile(File('noFile'));
      expect(notExistFileSet.exists, false);
    });

    test('upToDate', () {
      final fileSetA = FileSet.fromFile(fileA);
      final fileSetB = FileSet.fromFile(fileB);
      expect(fileSetB.upToDate(fileSetA), true);
    });

    test('fromDir glob', () {
      final fileSet = FileSet.fromDir(fileA.parent, pattern: '*.txt');
      expect(fileSet.files.length, 2);
    });

    test('fromDir glob 2', () {
      final fileSet = FileSet.fromDir(fileA.parent, pattern: '*.txts');
      expect(fileSet.files.length, 0);
    });

    test('fromDir glob 3', () {
      final fileSet = FileSet.fromDir(fileA.parent);
      expect(fileSet.files.length, 2);
    });
  });

  group('grinder.files', () {
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    test('fileName', () {
      final tempFileName = 'temp.txt';
      final tempFile = File('${temp.path}${_sep}tempdir$_sep$tempFileName');
      expect(fileName(tempFile), tempFileName);
    });

    test('fileExt', () {
      final extension = 'txt';
      final fileName = 'temp.$extension';
      var tempFile = File('${temp.path}${_sep}tempdir$_sep$fileName');
      expect(fileExt(tempFile), extension);

      final fileNameEmptyExt = 'temp.';
      tempFile = File('${temp.path}${_sep}tempdir$_sep$fileNameEmptyExt');
      expect(fileExt(tempFile), '');
    });

    test('fileExt null', () {
      final fileNameNoExt = 'temp';
      final tempFile =
          File('${temp.path}${_sep}tempdir$_sep$fileNameNoExt');
      expect(fileExt(tempFile), null);
    });

    test('joinFile', () {
      final tempFile = joinFile(Directory.current, ['dir', 'test']);
      final expectedFile =
          File('${Directory.current.path}${_sep}dir${_sep}test');
      expect(tempFile.path, expectedFile.path);
    });

    test('joinDir', () {
      final tempDirectory = joinDir(Directory.current, ['dir', 'test']);
      final expectedDir =
          Directory('${Directory.current.path}${_sep}dir${_sep}test');
      expect(tempDirectory.path, expectedDir.path);
    });

    test('copyFile', () {
      final tempFileName = 'copytest.txt';

      final source = joinFile(temp, [tempFileName]);
      source.writeAsStringSync('abcdABCD');

      final targetDir = joinDir(temp, ['targetDir']);
      copy(source, targetDir);

      final expectedFile = joinFile(targetDir, [tempFileName]);
      expect(expectedFile.readAsStringSync(), 'abcdABCD');
    });

    test('copyDirectory', () {
      final sourceDir = joinDir(temp, ['source']);
      sourceDir.createSync();

      joinFile(sourceDir, ['fileA']).writeAsStringSync('abcd');
      joinFile(sourceDir, ['fileB']).writeAsStringSync('efgh');
      joinFile(sourceDir, ['fileC']).writeAsStringSync('1234');

      final targetDir = joinDir(temp, ['target']);
      copy(sourceDir, targetDir);

      final expectedResult = joinFile(targetDir, ['fileA']).readAsStringSync() +
          joinFile(targetDir, ['fileB']).readAsStringSync() +
          joinFile(targetDir, ['fileC']).readAsStringSync();
      expect(expectedResult, 'abcdefgh1234');
    });
  });

  group('grinder.files FilePath', () {
    late FilePath temp;

    setUp(() {
      temp = FilePath.createSystemTemp();
    });

    tearDown(() => temp.delete());

    test('FilePath(entity)', () {
      final dir = FilePath(temp.entity);
      expect(dir.exists, true);
      expect(dir.isDirectory, true);

      final file = dir.join('temp.txt');
      file.asFile.writeAsStringSync('foo\n', flush: true);
      expect(file.exists, true);
      expect(file.isDirectory, false);
      expect(file.name, 'temp.txt');
    });

    test('FilePath(str)', () {
      final dir = FilePath(temp.path);
      expect(dir.exists, true);
      expect(dir.isDirectory, true);

      final file = dir.join('temp.txt');
      file.asFile.writeAsStringSync('foo\n', flush: true);
      expect(file.exists, true);
      expect(file.isDirectory, false);
      expect(file.name, 'temp.txt');

      expect(FilePath(dir.path + _sep).path, dir.path);
    });

    test('FilePath(str) platform independent', () {
      final file = temp.join('temp.txt');
      file.asFile.writeAsStringSync('foo\n', flush: true);
      expect(file.exists, true);
      final file2 = FilePath(file.path.replaceAll(_sep, '/'));
      expect(file2.exists, true);
    });

    test('current', () {
      expect(FilePath.current, isNotNull);
      expect(FilePath.current.isDirectory, true);
    });

    test('parent', () {
      expect(temp.parent, isNotNull);
      expect(temp.parent!.isDirectory, true);

      expect(FilePath.current.parent, isNotNull);
      expect(FilePath.current.parent!.path, isNotEmpty);
      expect(FilePath.current.parent!.parent, isNotNull);

      final root = FilePath('/');
      expect(root.exists, true);
      expect(root.parent, isNotNull);
      expect(root.parent!.parent, isNotNull);
    });

//    test('absolute', () {
//      expect(FilePath.current, notEquals(FilePath.current.absolute));
//      expect(FilePath.current.absolute.absolute, FilePath.current.absolute);
//    });

    test('copy', () {
      final file = temp.join('temp.txt');
      file.asFile.writeAsStringSync('foo\n', flush: true);
      final childDir = temp.join('child_dir')..createDirectory();
      final copied = file.copy(childDir);
      expect(copied.exists, true);
      expect(copied.path, endsWith('temp.txt'));
    });

    test('delete', () {
      final file = temp.join('temp.txt');
      file.asFile.writeAsStringSync('foo\n', flush: true);
      expect(file.exists, true);
      file.delete();
      expect(file.exists, false);
    });

    test('length', () {
      expect(temp.length, 0);
      final file = temp.join('temp.txt');
      file.asFile.writeAsStringSync('foo\n', flush: true);
      expect(file.length, 4);
    });
  });
}

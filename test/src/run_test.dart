// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.src.run;

import 'dart:io' as io;

import 'package:grinder/grinder.dart';
import 'package:grinder/grinder_tools.dart';
import 'package:unittest/unittest.dart';
import 'dart:convert' show Converter, Encoding, JSON;

final String sep = io.Platform.pathSeparator;
const runScriptName = 'run_script.dart';
final runScriptPath = 'test${sep}src';
final runScript = '$runScriptPath$sep$runScriptName';

main() {
  group('run', () {
    test('should pass arguments', () {
      const arguments = const ['a', 'b'];

      String output =
          run('dart', arguments: [runScript]..addAll(arguments), quiet: true);
      Map json = JSON.decode(output);
      expect(json['arguments'], orderedEquals(arguments));
    });

    test('should use workingDirectory from RunOptions', () {
      String output = run('dart',
          arguments: [runScriptName],
          runOptions: new RunOptions(workingDirectory: runScriptPath),
          quiet: true);
      Map json = JSON.decode(output);
      expect(json['workingDirectory'], endsWith('$sep$runScriptPath'));
    });

    test('should use workingDirectory form workingDirectory parameter', () {
      String output = run('dart',
          arguments: [runScriptName],
          workingDirectory: runScriptPath,
          quiet: true);
      Map json = JSON.decode(output);
      expect(json['workingDirectory'], endsWith('$sep$runScriptPath'));
    });

    test(
        'should also use workingDirectory parameter when runOptions are passed',
        () {
      String output = run('dart',
          arguments: [runScriptName],
          workingDirectory: runScriptPath,
          runOptions: new RunOptions(),
          quiet: true);
      Map json = JSON.decode(output);
      expect(json['workingDirectory'], endsWith('$sep$runScriptPath'));
    });

    test(
        'should throw when workingDirectory and runOptions.workingDirectory are passed',
        () {
      bool isCheckedMode = false;
      assert(() => isCheckedMode = true);
      if (isCheckedMode) {
        expect(() => run('dart',
                arguments: [runScriptName],
                workingDirectory: runScriptPath,
                runOptions: new RunOptions(workingDirectory: runScriptPath)),
            throws);
      }
    });

    test('should pass environment', () {
      const environment = const {'TESTENV1': 'value1', 'TESTENV2': 'value2'};

      String output = run('dart',
          arguments: [runScript],
          runOptions: new RunOptions(environment: environment),
          quiet: true);
      Map json = JSON.decode(output);
      for (var k in environment.keys) {
        expect(json['environment'][k], environment[k]);
      }
    });

    test('should pass includeParentEnvironment setting', () {
      final environment = {
        'TESTENV1': 'value1',
        'TESTENV2': 'value2',
        'PATH': io.Platform.environment['PATH']
      };

      String output = run('dart',
          arguments: [runScript],
          runOptions: new RunOptions(
              environment: environment, includeParentEnvironment: false),
          quiet: true);
      Map json = JSON.decode(output);
      for (var k in environment.keys) {
        expect(json['environment'][k], environment[k]);
      }
      expect(json['environment'].keys, unorderedEquals(environment.keys));
    });

    test('should pass runInShell setting', () {
      final environment = {
        'TESTENV1': 'value1',
        'TESTENV2': 'value2',
        'PATH': io.Platform.environment['PATH']
      };

      String output = run('dart',
          arguments: [runScript],
          runOptions: new RunOptions(
              environment: environment,
              includeParentEnvironment: false,
              runInShell: true),
          quiet: true);
      Map json = JSON.decode(output);
      for (var k in environment.keys) {
        expect(json['environment'][k], environment[k]);
      }
      // TODO(zoechi) verify if this works in Windows or find a better way to
      // verify that `runInShell: true` is applied.
      expect(json['environment'].length, greaterThan(3));
    });

    test('should use stdoutEncoding', () {
      String output = run('dart',
          arguments: [runScript],
          runOptions: new RunOptions(stdoutEncoding: const DummyEncoding()),
          quiet: true);
      expect(output, DummyDecoder.dummyDecoderOutput);
    });

    test('should use stderrEncoding', () {
      const environment = const {'USE_EXIT_CODE': '100'};

      expect(() => run('dart',
              arguments: [runScript],
              runOptions: new RunOptions(
                  environment: environment,
                  stderrEncoding: const DummyEncoding()),
              quiet: true), throwsA(
          (ProcessException e) => e.stderr == DummyDecoder.dummyDecoderOutput));
    });
  });
}

/// Simple Encoding just to test if this encoding is used when passed.
class DummyEncoding extends Encoding {
  const DummyEncoding();

  @override
  Converter<List<int>, String> get decoder => const DummyDecoder();

  @override
  Converter<String, List<int>> get encoder => null;

  @override
  String get name => null;
}

/// Decoder for [DummyEncoding].
class DummyDecoder extends Converter<List<int>, String> {
  static const dummyDecoderOutput = 'DummyDecoder';
  const DummyDecoder();

  String convert(List<int> codeUnits, [int start = 0, int end]) {
    return dummyDecoderOutput;
  }
}

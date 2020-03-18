// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.src.run;

import 'dart:convert' show Converter, Encoding, jsonDecode;
import 'dart:io' as io;

import 'package:grinder/grinder.dart';
import 'package:grinder/grinder_tools.dart';
import 'package:test/test.dart';

final String sep = io.Platform.pathSeparator;
const runScriptName = 'run_script.dart';
final runScriptPath = 'test${sep}src';
final runScript = '$runScriptPath$sep$runScriptName';

void main() {
  group('run', () {
    test('should pass arguments', () {
      const arguments = ['a', 'b'];

      final output =
          run('dart', arguments: [runScript, ...arguments], quiet: true);
      Map json = jsonDecode(output);
      expect(json['arguments'], orderedEquals(arguments));
    });

    test('should use workingDirectory from RunOptions', () {
      final output = run('dart',
          arguments: [runScriptName],
          runOptions: RunOptions(workingDirectory: runScriptPath),
          quiet: true);
      Map json = jsonDecode(output);
      expect(json['workingDirectory'], endsWith('$sep$runScriptPath'));
    });

    test('should use workingDirectory form workingDirectory parameter', () {
      final output = run('dart',
          arguments: [runScriptName],
          workingDirectory: runScriptPath,
          quiet: true);
      Map json = jsonDecode(output);
      expect(json['workingDirectory'], endsWith('$sep$runScriptPath'));
    });

    test(
        'should also use workingDirectory parameter when runOptions are passed',
        () {
      final output = run('dart',
          arguments: [runScriptName],
          workingDirectory: runScriptPath,
          runOptions: RunOptions(),
          quiet: true);
      Map json = jsonDecode(output);
      expect(json['workingDirectory'], endsWith('$sep$runScriptPath'));
    });

    test(
        'should throw when workingDirectory and runOptions.workingDirectory are passed',
        () {
      var isCheckedMode = false;
      assert((() => isCheckedMode = true)());
      if (isCheckedMode) {
        expect(
            () => run('dart',
                arguments: [runScriptName],
                workingDirectory: runScriptPath,
                runOptions: RunOptions(workingDirectory: runScriptPath)),
            throwsA(isA<ArgumentError>()));
      }
    });

    test('should pass environment', () {
      const environment = {'TESTENV1': 'value1', 'TESTENV2': 'value2'};

      final output = run('dart',
          arguments: [runScript],
          runOptions: RunOptions(environment: environment),
          quiet: true);
      Map json = jsonDecode(output);
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

      final output = run('dart',
          arguments: [runScript],
          runOptions: RunOptions(
              environment: environment, includeParentEnvironment: false),
          quiet: true);
      Map json = jsonDecode(output);
      for (var k in environment.keys) {
        expect(json['environment'][k], environment[k]);
      }
      // Filter out __CF_USER_TEXT_ENCODING.
      expect(
          json['environment'].keys.where(
              (str) => (!str.startsWith('__') && !str.startsWith('GLIB'))),
          unorderedEquals(environment.keys));
    });

    test('should pass runInShell setting', () {
      final environment = {
        'TESTENV1': 'value1',
        'TESTENV2': 'value2',
        'PATH': io.Platform.environment['PATH']
      };

      final output = run('dart',
          arguments: [runScript],
          runOptions: RunOptions(
              environment: environment,
              includeParentEnvironment: false,
              runInShell: true),
          quiet: true);
      Map json = jsonDecode(output);
      for (var k in environment.keys) {
        expect(json['environment'][k], environment[k]);
      }
      // TODO(zoechi) verify if this works in Windows or find a better way to
      // verify that `runInShell: true` is applied.
      expect(json['environment'].length, greaterThan(3));
    });

    test('should use stdoutEncoding', () {
      final output = run('dart',
          arguments: [runScript],
          runOptions: RunOptions(stdoutEncoding: const DummyEncoding()),
          quiet: true);
      expect(output, DummyDecoder.dummyDecoderOutput);
    });

    test('should use stderrEncoding', () {
      const environment = {'USE_EXIT_CODE': '100'};

      expect(
          () => run('dart',
              arguments: [runScript],
              runOptions: RunOptions(
                  environment: environment,
                  stderrEncoding: const DummyEncoding()),
              quiet: true),
          throwsA((ProcessException e) =>
              e.stderr == DummyDecoder.dummyDecoderOutput));
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

  @override
  String convert(List<int> codeUnits, [int start = 0, int end]) {
    return dummyDecoderOutput;
  }
}

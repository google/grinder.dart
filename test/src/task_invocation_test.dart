// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.task_invocation_test;

import 'package:grinder/grinder.dart' hide fail;
import 'package:test/test.dart';
import 'package:unscripted/unscripted.dart';

main() {
  group('TaskInvocation', () {
    group('==', () {
      test('returns false if other is not of same type', () {
        expect(new TaskInvocation('foo') == 'foo', isFalse);
      });

      test('returns false if name is different', () {
        expect(new TaskInvocation('foo') == new TaskInvocation('bar'), isFalse);
      });

      test('returns false if positionals are different', () {
        expect(
            new TaskInvocation('foo', positionals: []) ==
                new TaskInvocation('foo', positionals: [new Positional()]),
            isFalse);
      });

      test('returns false if positionals are different', () {
        expect(
            new TaskInvocation('foo', options: {}) ==
                new TaskInvocation('foo', options: {'option': 'option value'}),
            isFalse);
      });

      test('returns true if all fields are the same', () {
        expect(new TaskInvocation('foo') == new TaskInvocation('foo'), isTrue);
      });
    });

    group('hashCode', () {
      test('returns same value when fields are same', () {
        _getHashCode() => new TaskInvocation('foo').hashCode;
        expect(_getHashCode() == _getHashCode(), isTrue);
      });
    });
  });
}

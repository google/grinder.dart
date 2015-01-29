// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * A `unittest` test configuration that logs the test progress and results to
 * the browser's console log. This makes the test status information available
 * to external test drivers.
 */
library grinder.webtest;

import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

/**
 * A `unittest` test configuration that logs the test progress and results to
 * the browser's console log.
 */
class WebTestConfiguration extends HtmlConfiguration {
  /**
   * Call this before defining tests.
   */
  static void setupTestEnvironment(
      {Duration timeout: const Duration(seconds: 30)}) {
    unittestConfiguration = new WebTestConfiguration(timeout: timeout);
  }

  WebTestConfiguration({Duration timeout}) : super(false) {
    if (timeout != null) {
      this.timeout = timeout;
    }
  }

  void onStart() {
    super.onStart();

    _log('\nStarting tests\n--------------');
  }

  void onTestStart(TestCase testCase) {
    super.onTestStart(testCase);

    _log('${testCase}:');
  }

  void onTestResult(TestCase testCase) {
    super.onTestResult(testCase);

    _log('${testCase}');
  }

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
        String uncaughtError) {
    _log('\nTest summary\n------------');

    results.forEach((TestCase result) {
      if (!result.passed) {
        StringBuffer buf = new StringBuffer();
        buf.writeln('${result}');
        buf.writeln(_indent('  ', result.message.trimRight()));
        if (result.stackTrace != null) {
          buf.writeln(_indent('  ', result.stackTrace.toString()));
        }
        _log(buf.toString());
      }
    });

    if (failed + errors > 0) _log('\n');
    _log('${passed} passed, ${failed} failed, ${errors} errors');

    super.onSummary(passed, failed, errors, results, uncaughtError);
  }

  void onDone(bool success) {
    _log('tests finished - ${success ? "passed" : "failed"}.');
    super.onDone(success);
  }

  String _indent(String indent, String str) =>
      str.split('\n').map((s) => '${indent}${s}').join('\n');

  void _log(String message) => print(message.trimRight());
}


library grinder.src.run_utils;

import 'dart:async';
import 'dart:convert';

import '../grinder.dart';

Stream<String> toLineStream(Stream<List<int>> s) =>
  s.transform(UTF8.decoder).transform(const LineSplitter());

logStdout(String line) {
  log(line);
}

logStderr(String line) {
  log('stderr: $line');
}

// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.example.programmatic;

import 'dart:async';

import 'package:grinder/grinder.dart';

void main(List<String> args) {
  task('init', defaultInit);
  defaultTask = new GrinderTask('build', depends: ['init'], taskFunction: build);
  startGrinder(args);
}

Future build(GrinderContext context) {
  return Pub.buildAsync(context, directories: ['test']);
}

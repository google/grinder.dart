// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_example_2;

import 'dart:async';

import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  task('init', init);
  task('build', build, ['init']);
  task('all', null, ['build']);

  startGrinder(args);
}

void init(GrinderContext context) {
  context.log("I set things up");
}

Future build(GrinderContext context) {
  PubTools pub = new PubTools();
  return pub.buildAsync(context, directories: ['test']);
}

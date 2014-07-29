// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_example_2;

import 'dart:async';

import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  defineTask('init', taskFunction: init);
  defineTask('build', taskFunction: build, depends: ['init']);
  defineTask('all', depends: ['build']);

  startGrinder(args);
}

void init(GrinderContext context) {
  context.log("I set things up");
}

Future build(GrinderContext context) {
  PubTools pub = new PubTools();
  return pub.buildAsync(context, directories: ['test']);
}

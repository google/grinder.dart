// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_example_1;

import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  task('init', init);
  task('compile', compile, ['init']);
  task('deploy', deploy, ['compile']);
  task('all', null, ['deploy']);

  startGrinder(args);
}

void init(GrinderContext context) {
  context.log("I set things up");
}

void compile(GrinderContext context) {
  context.log("I'm compiling now...");
  //context.fail('woot');
}

void deploy(GrinderContext context) {
  context.log("deploying a");
  context.log("deploying b");
}

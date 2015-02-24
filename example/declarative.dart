// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.example.declarative;

import 'package:grinder/grinder.dart';

const main = grind;

@Task()
init(GrinderContext context) {
  context.log("I set things up");
}

@Task(depends: const ['init'])
compile(GrinderContext context) {
  context.log("I'm compiling now...");
  //context.fail('woot');
}

@Task(depends: const ['compile'])
deploy(GrinderContext context) {
  context.log("deploying a");
  context.log("deploying b");
}

@Task(name: 'default', depends: const ['deploy'])
_default(GrinderContext context) {}

// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.example.declarative;

import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task(
    description: 'Initialize stuff.')
init(GrinderContext context) {
  context.log("Initializing stuff...");
}

@Task(
    depends: const ['init'],
    description: 'Compile stuff.')
compile(GrinderContext context) {
  context.log("Compiling stuff...");
}

@DefaultTask(
    depends: const ['compile'],
    description: 'Deploy stuff.')
deploy(GrinderContext context) {
  context.log("Deploying stuff...");
}

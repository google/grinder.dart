// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'package:grinder/grinder.dart';

Future<dynamic> main(args) => grind(args);

@Task('Initialize stuff.')
void init() {
  log('Initializing stuff...');
}

@Task('Compile stuff.')
@Depends(init)
void compile() {
  log('Compiling stuff...');
}

@DefaultTask('Deploy stuff.')
@Depends(compile)
void deploy() {
  log('Deploying stuff...');
}

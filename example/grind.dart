// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task('Initialize stuff.')
init() {
  log("Initializing stuff...");
}

@Task('Compile stuff.')
@Depends(init)
compile() {
  log("Compiling stuff...");
}

@DefaultTask('Deploy stuff.')
@Depends(compile)
deploy() {
  log("Deploying stuff...");
}

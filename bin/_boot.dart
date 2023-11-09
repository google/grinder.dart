// Copyright 2017 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// A script for debugging grinder.
///
/// The main entry-point (`bin/grinder.dart`) trampolines into a different
/// script; running with `_boot.dart` instead allows you to hit breakpoints when
/// debugging.
library;

import 'package:grinder/grinder.dart';

Future<dynamic> main(List<String> args) => grind(args);

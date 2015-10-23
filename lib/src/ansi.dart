// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

bool get supportsAnsi => stdout.hasTerminal;

String get bold => supportsAnsi ? '\u001B[1m' : '';
String get red => supportsAnsi ? '\u001B[31m' : '';
String get reset => supportsAnsi ? '\u001B[0m' : '';

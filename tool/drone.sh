#!/bin/bash

# Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
# All rights reserved. Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

# Display installed versions.
dart --version

# Get our packages.
pub get

# Verify that the libraries are error free.
dartanalyzer --fatal-warnings \
  example/ex1.dart \
  example/ex2.dart \
  lib/grinder.dart \
  lib/grinder_files.dart \
  lib/grinder_utils.dart \
  tool/grind.dart \
  test/all.dart

# Run the tests.
dart test/all.dart

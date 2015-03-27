#!/bin/bash

# Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
# All rights reserved. Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

# Install global tools.
pub global activate tuneup

# Verify that the libraries are error free.
pub global run tuneup check

# Run the tests.
dart -c test/all.dart

# Verify that the generated grind script analyzes well.
dart tool/grind.dart analyze-init

# Gather and send coverage data.
if [ "$REPO_TOKEN" ]; then
  pub global activate dart_coveralls
  pub global run dart_coveralls report \
    --token $REPO_TOKEN \
    --retry 2 \
    --exclude-test-files \
    test/all.dart
fi

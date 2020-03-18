// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.grinder_exception;

/// An exception class for the Grinder library.
class GrinderException implements Exception {
  /// A message describing the error.
  final String message;

  /// Create a new `GrinderException`.
  GrinderException(this.message);

  @override
  String toString() => 'GrinderException: ${message}';
}

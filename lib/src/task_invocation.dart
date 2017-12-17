// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.task_invocation;

import 'package:collection/collection.dart';

/// An invocation of a [GrinderTask].
///
/// Identifies the [name] of the task to invoke, and which arguments
/// ([positionals] and [options]) to send to it.
class TaskInvocation {
  final String name;
  final List positionals;
  final Map<String, dynamic> options;

  TaskInvocation(this.name,
      {this.positionals: const [], this.options: const {}});

  bool operator ==(other) =>
      other is TaskInvocation &&
      name == other.name &&
      const IterableEquality().equals(positionals, other.positionals) &&
      const MapEquality().equals(options, other.options);

  int get hashCode =>
      name.hashCode ^
      (const IterableEquality().hash(positionals) * 3) ^
      (const MapEquality().hash(options) * 5);

  String toString() {
    var args = positionals.toList();
    options.forEach((name, value) {
      if (value != null) {
        args.add('$name=$value');
      }
    });
    var argString = args.isEmpty ? '' : ':${args.join(',')}';
    return '[$name$argString]';
  }
}

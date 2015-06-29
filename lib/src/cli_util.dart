// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli_util;

import 'package:collection/collection.dart';
import 'package:unscripted/unscripted.dart';

import '../grinder.dart';

TaskInvocation parseTaskInvocation(String invocation) {
  var invocationPattern = new RegExp(r'([_a-zA-Z][\-_a-zA-Z0-9]*)(:(.*))?');
  var match = invocationPattern.matchAsPrefix(invocation);
  if (match == null) throw 'Invalid task invocation: $invocation';
  var name = match.group(1);
  var positionalString = match.group(3);
  var positionals = positionalString == null ? [] : positionalString.split(',');

  return new TaskInvocation(name, positionals: positionals);
}

void validatePositionals(GrinderTask task, TaskInvocation invocation) {
  var actual = invocation.positionals != null ? invocation.positionals.length : 0;

  validatePositionalCount(bool condition, String expectation) {
    validateArg(condition, 'Received $actual positional command-line arguments, but $expectation.', task: task);
  }

  var minPositionals = task.positionals.length;
  if (task.rest != null && task.rest.required) {
    minPositionals++;
  }
  validatePositionalCount(actual >= minPositionals, 'at least $minPositionals required');

  var maxPositionals = task.rest == null ? task.positionals.length : null;
  validatePositionalCount(maxPositionals == null || actual <= maxPositionals, 'at most $maxPositionals allowed');
}

TaskInvocation applyTaskToInvocation(GrinderTask task, TaskInvocation invocation) {

  validatePositionals(task, invocation);

  var positionalParams = task.positionals;
  var positionalArgs = invocation.positionals;
  int restParameterIndex;

  if (task.rest != null) {
    restParameterIndex = positionalParams.length;
    positionalArgs = positionalArgs.take(restParameterIndex).toList();
  }

  String getPositionalName(int index, Positional positional) =>
  positional.valueHelp != null ? positional.valueHelp : index.toString();

  var positionalNames = [];
  positionalParams.asMap().forEach((index, positional) {
    positionalNames.add(getPositionalName(index, positional));
  });

  parseArg(param, arg, name) {

    if (param.allowed != null) {
      validateArg(param.allowed.contains(arg),
      '"$arg" is not an allowed value for option "$name".');
    }

    if (param.parser == null || arg == null) return arg;

    try {
      return param.parser(arg);
    } catch(e) {
      validateArg(false, 'Invalid value "$arg":\n$e', task: task, param: name);
    }
  }

  List zipParsedArgs(args, params, names) {
    return new IterableZip([args, params, names])
    .map((parts) => parseArg(parts[1], parts[0], parts[2]))
    .toList();
  }

  var positionals = zipParsedArgs(
      positionalArgs,
      positionalParams,
      positionalNames);

  if (task.rest != null) {
    var rawRest = invocation.positionals.skip(restParameterIndex);
    var rest = zipParsedArgs(
        rawRest,
        new Iterable.generate(rawRest.length, (_) => task.rest),
        new Iterable.generate(rawRest.length, (int indexInRest) =>
        getPositionalName(restParameterIndex + indexInRest, task.rest)));
    positionals.add(rest);
  }

  var options = <String, dynamic> {};

  task.options.forEach((option) {
    var resolvedOptionValue;

    if (!invocation.options.containsKey(option.name)) {
      resolvedOptionValue = option.defaultsTo;
    } else {
      var optionValue = invocation.options[option.name];
      parseValue(value) => parseArg(option, value, option.name);
      resolvedOptionValue = optionValue is List
      ? new UnmodifiableListView(optionValue.map(parseValue))
      : parseValue(optionValue);
    }
    options[option.name] = resolvedOptionValue;
  });

  return new TaskInvocation(invocation.name, positionals: positionals, options: options);
}

/// Throws a [GrinderException] if [condition] is `false`.
void validateArg(bool condition, String message, {GrinderTask task, String param}) {
  var paramString = param == null ? '' : 'Argument "$param": ';
  if (!condition) throw new GrinderException('Task $task: $paramString$message');
}

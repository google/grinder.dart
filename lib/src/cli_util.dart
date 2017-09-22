// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli_util;

import 'dart:math';

import 'package:ansicolor/ansicolor.dart';
import 'package:collection/collection.dart';
import 'package:unscripted/unscripted.dart';

import '../grinder.dart';

TaskInvocation parseTaskInvocation(String invocation) {
  var invocationPattern = new RegExp(r'([_a-zA-Z][\-_a-zA-Z0-9]*)(:(.*))?$');
  var match = invocationPattern.matchAsPrefix(invocation);
  if (match == null) throw 'Invalid task invocation: "$invocation"';
  var name = match.group(1);
  var positionalString = match.group(3);
  var positionals = positionalString == null || positionalString.isEmpty
      ? []
      : positionalString.split(',');

  return new TaskInvocation(name, positionals: positionals);
}

void validatePositionals(GrinderTask task, TaskInvocation invocation) {
  var actual =
      invocation.positionals != null ? invocation.positionals.length : 0;

  validatePositionalCount(bool condition, String expectation) {
    validateArg(condition,
        'Received $actual positional command-line arguments, but $expectation.',
        task: task);
  }

  var minPositionals = task.positionals.length;
  if (task.rest != null && task.rest.required) {
    minPositionals++;
  }
  validatePositionalCount(
      actual >= minPositionals, 'at least $minPositionals required');

  var maxPositionals = task.rest == null ? task.positionals.length : null;
  validatePositionalCount(maxPositionals == null || actual <= maxPositionals,
      'at most $maxPositionals allowed');
}

TaskInvocation applyTaskToInvocation(
    GrinderTask task, TaskInvocation invocation) {
  validatePositionals(task, invocation);

  List<Positional> positionalParams = task.positionals;
  List positionalArgs = invocation.positionals;
  int restParameterIndex;

  if (task.rest != null) {
    restParameterIndex = positionalParams.length;
    positionalArgs = positionalArgs.take(restParameterIndex).toList();
  }

  String getPositionalName(int index, Positional positional) =>
      positional.valueHelp != null ? positional.valueHelp : index.toString();

  List<String> positionalNames = [];
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
    } catch (e) {
      validateArg(false, 'Invalid value "$arg":\n$e', task: task, param: name);
    }
  }

  List zipParsedArgs(args, params, names) {
    return new IterableZip(<List>[args, params, names])
        .map((parts) => parseArg(parts[1], parts[0], parts[2]))
        .toList();
  }

  var positionals =
      zipParsedArgs(positionalArgs, positionalParams, positionalNames);

  if (task.rest != null) {
    var rawRest = invocation.positionals.skip(restParameterIndex);
    var rest = zipParsedArgs(
        rawRest,
        new Iterable.generate(rawRest.length, (_) => task.rest),
        new Iterable.generate(
            rawRest.length,
            (int indexInRest) => getPositionalName(
                restParameterIndex + indexInRest, task.rest)));
    positionals.add(rest);
  }

  var options = <String, dynamic>{};

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

  return new TaskInvocation(invocation.name,
      positionals: positionals, options: options);
}

/// Throws a [GrinderException] if [condition] is `false`.
void validateArg(bool condition, String message,
    {GrinderTask task, String param}) {
  var paramString = param == null ? '' : 'Argument "$param": ';
  if (!condition)
    throw new GrinderException('Task $task: $paramString$message');
}

List<Option> getTaskOptions(Grinder grinder) {
  var tasks = grinder.tasks;

  var optionMap = {};

  tasks.forEach((task) {
    task.options.forEach((option) {
      optionMap.putIfAbsent(option.name, () => []).add(option);
    });
  });

  List<Option> taskOptions = [];

  optionMap.forEach((name, options) {
    var hasFlag = options.any((option) => option is Flag);
    var hasNonFlag = options.any((option) => option is! Flag);

    if (hasFlag && hasNonFlag) {
      throw new GrinderException(
          'Cannot define task option "$name" as both an option and a flag.');
    }

    var option = hasFlag
        ? new Flag(name: name, negatable: true)
        : new Option(name: name, allowMultiple: true, defaultsTo: []);

    taskOptions.add(option);
  });

  return taskOptions;
}

TaskInvocation addTaskOptionsToInvocation(GrinderTask task,
    TaskInvocation invocation, Map<String, dynamic> allOptions) {
  var options = {};

  task.options.forEach((option) {
    var optionValue = allOptions[option.name];
    if (option is Flag) {
      bool value = optionValue;
      validateArg(value || option.negatable, 'Is not negatable.',
          task: task, param: option.name);

      optionValue = value == null ? option.defaultsTo : value;
    } else {
      List values = optionValue;
      validateArg(option.allowMultiple || values.length <= 1,
          'Does not allow multiple values: $values',
          task: task, param: option.name);

      optionValue = values.isEmpty
          ? option.defaultsTo
          : option.allowMultiple ? values : values.first;
    }

    options[option.name] = optionValue;
  });

  return new TaskInvocation(invocation.name,
      options: options, positionals: invocation.positionals);
}

String getTaskHelp(Grinder grinder, {bool useColor}) {
  var positionalPen = new AnsiPen()..green();
  var textPen = new AnsiPen()..gray(level: 0.5);

  var originalColorDisabled = color_disabled;
  if (useColor != null) color_disabled = !useColor;

  if (grinder.tasks.isEmpty) {
    return '\n\n  No tasks defined.\n';
  }

  // Calculate the dependencies.
  grinder.start([], dontRun: true);

  List<GrinderTask> tasks = grinder.tasks.toList();

  var firstColMap = tasks.fold({}, (map, task) {
    map[task] = '$task${grinder.defaultTask == task ? ' (default)' : ''}';
    return map;
  });

  var firstColMax =
      firstColMap.values.fold(0, (width, next) => max<num>(width, next.length));
  var padding = 4;
  var firstColWidth = firstColMax + padding;

  var ret = '\n\n' +
      tasks.map((GrinderTask task) {
        Iterable<TaskInvocation> deps = grinder.getImmediateDependencies(task);

        var buffer = new StringBuffer();
        buffer.write(
            '  ${positionalPen(firstColMap[task].padRight(firstColWidth))}');
        var desc = task.description == null ? '' : task.description;
        var depText = '${textPen('(depends on ')}${positionalPen(
            deps.join(' '))}${textPen(')')}';
        if (desc.isNotEmpty) {
          buffer.writeln(textPen(task.description));
          if (deps.isNotEmpty) {
            buffer.writeln('  ${''.padRight(firstColWidth)}$depText');
          }
        } else {
          if (deps.isNotEmpty) buffer.write(depText);
          buffer.writeln();
        }

        return buffer.toString();
      }).join();

  if (useColor != null) color_disabled = originalColorDisabled;

  return ret;
}

List<String> allowedTasks(Grinder grinder) =>
    grinder.tasks.map((task) => task.name).toList();

String cleanupStackTrace(st) {
  List<String> lines = '${st}'.trim().split('\n');

  // Remove lines which are not useful to debugging script issues. With our move
  // to using zones, the exceptions now have stacks 30 frames deep.
  while (lines.isNotEmpty) {
    String line = lines.last;

    if (line.contains(' (dart:') ||
        line.contains(' (package:grinder/') ||
        line.contains('package:unscripted/')) {
      lines.removeLast();
    } else {
      break;
    }
  }

  return lines.join('\n').trim().replaceAll('<anonymous closure>', '<anon>');
}

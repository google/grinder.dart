// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.utils;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

class ResettableTimer implements Timer {
  final Duration duration;
  final void Function() callback;

  late Timer _timer;

  ResettableTimer(this.duration, this.callback) {
    _timer = Timer(duration, callback);
  }

  void reset() {
    _timer.cancel();
    _timer = Timer(duration, callback);
  }

  @override
  void cancel() => _timer.cancel();

  @override
  bool get isActive => _timer.isActive;

  @override
  int get tick => _timer.tick;
}

String camelToDashes(String input) {
  var segment = RegExp(r'.[^A-Z]*');
  var matches = segment.allMatches(input);
  return matches
      .map((Match match) => withCapitalization(
          match.input.substring(match.start, match.end), false))
      .join('-');
}

// Upper-case or lower-case the first character of a String.
String withCapitalization(String s, bool capitalized) {
  if (s.isEmpty) return s;
  var firstLetter = s[0];
  firstLetter =
      capitalized ? firstLetter.toUpperCase() : firstLetter.toLowerCase();
  return firstLetter + s.substring(1);
}

Map<Symbol, DeclarationMirror> resolveExportedDeclarations(
    LibraryMirror library) {
  final resolvedDeclarations = <Symbol, DeclarationMirror>{};
  resolvedDeclarations.addAll(library.declarations);

  for (final dependency in library.libraryDependencies) {
    if (dependency.isExport) {
      var library = dependency.targetLibrary;

      // Ignore deferred libraries that aren't loaded yet.
      if (library == null) continue;

      final shown = <Symbol, DeclarationMirror>{};
      final hidden = <Symbol>[];
      for (final combinator in dependency.combinators) {
        if (combinator.isShow) {
          for (final id in combinator.identifiers) {
            // It's valid for an export to show names that don't exist. If it
            // does, ignore those `show`s.
            var declaration = library.declarations[id];
            if (declaration != null) shown[id] = declaration;
          }
        }
        if (combinator.isHide) {
          hidden.addAll(combinator.identifiers);
        }
      }
      if (shown.isEmpty) {
        shown.addAll(library.declarations);
        hidden.forEach(shown.remove);
      }
      resolvedDeclarations.addAll(shown);
    }
  }

  return UnmodifiableMapView<Symbol, DeclarationMirror>(resolvedDeclarations);
}

T? getFirstMatchingAnnotation<T>(DeclarationMirror decl) => decl.metadata
    .map((InstanceMirror mirror) => mirror.reflectee)
    .whereType<T>()
    .firstOrNull;

/// A simple way to expose a default value that can be overridden within zones.
class ZonedValue<T> {
  final T _rootValue;
  final _valueKey = Object();
  final _finalKey = Object();

  ZonedValue(T rootValue) : _rootValue = rootValue;

  dynamic withValue(T value, dynamic Function() f, {bool isFinal = false}) {
    if (this.isFinal) {
      throw StateError('Cannot override final zoned value');
    }
    return runZoned(f, zoneValues: {_valueKey: value, _finalKey: isFinal});
  }

  bool get isFinal {
    var parentIsFinal = Zone.current[_finalKey];
    return parentIsFinal != null && parentIsFinal;
  }

  T get value {
    // TODO: Allow null values when http://dartbug.com/21247 is fixed.
    var v = Zone.current[_valueKey];
    return v ?? _rootValue;
  }
}

/// Given a [String], [File], or list of strings or files, coerce the
/// [filesOrPaths] param into a list of strings.
List<String> coerceToPathList(filesOrPaths) {
  if (filesOrPaths is! Iterable) filesOrPaths = [filesOrPaths];
  return filesOrPaths
      .map((item) {
        if (item is String) return item;
        if (item is FileSystemEntity) return item.path;
        return '$item';
      })
      .cast<String>()
      .toList();
}

/// Takes a list of paths and if an element is a directory it expands it to
/// the Dart source files contained by this directory, otherwise the element is
/// added to the result unchanged.
Set<String> findDartSourceFiles(Iterable<String> paths) {
  /// Returns `true` if this [fileName] is a Dart file.
  bool isDartFileName(String fileName) => fileName.endsWith('.dart');

  /// Returns `true` if this relative path is a hidden directory.
  bool isInHiddenDir(String relative) =>
      path.split(relative).any((part) => part.startsWith('.'));

  Set<String> findDartSourceFiles(Directory directory) {
    var files = <String>{};
    if (directory.existsSync()) {
      for (var entry
          in directory.listSync(recursive: true, followLinks: false)) {
        var relative = path.relative(entry.path, from: directory.path);
        if (isDartFileName(entry.path) && !isInHiddenDir(relative)) {
          files.add(entry.path);
        }
      }
    }
    return files;
  }

  var files = <String>{};

  for (final path in paths) {
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.directory) {
      files.addAll(findDartSourceFiles(Directory(path)));
    } else {
      files.add(path);
    }
  }
  return files;
}

String cleanupStackTrace(st) {
  final lines = '$st'.trim().split('\n');

  // Remove lines which are not useful to debugging script issues. With our move
  // to using zones, the exceptions now have stacks 30 frames deep.
  while (lines.isNotEmpty) {
    final line = lines.last;

    if (line.contains(' (dart:') || line.contains(' (package:grinder/')) {
      lines.removeLast();
    } else {
      break;
    }
  }

  return lines.join('\n').trim().replaceAll('<anonymous closure>', '<anon>');
}

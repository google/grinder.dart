// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * General file system routines, useful in the context of running builds. This
 * includes the [FileSet] class, which is used for reasoning about sets of
 * files.
 */
library grinder.files;

import 'dart:io';

import 'package:quiver/pattern.dart';

import 'grinder.dart';

// TODO: add files to a set

// TODO: union sets?

// TODO: it would be nice to be able to pipeline processing sets of files. So
// copy groups a, b, c to location d. zip that new set d. the zip file is set e;
// move that somewhere. Or, being able to run map, reduce, and expand on groups
// of files.
// Every operation:
//   - takes an input set
//   - performs work
//   - and returns an output set

/**
 * A class to handle defining, composing, and comparing groups of files.
 */
class FileSet {
  List<File> files = [];

  FileSet.fromDir(Directory dir, {String pattern, bool recurse: false}) {
    Glob glob = (pattern == null ? null : new Glob(pattern));

    if (dir.existsSync()) {
      _collect(files, dir, glob, recurse);
    }
  }

  FileSet.fromFile(File file) {
    files.add(file);
  }

  /**
   * Returns whether this file set exists, and is not older then the given
   * [FileSet].
   */
  bool upToDate(FileSet other) {
    if (!exists) {
      return false;
    } else {
      return !other.lastModified.isAfter(lastModified);
    }
  }

  bool get exists {
    if (files.isEmpty) {
      return false;
    } else {
      return files.any((f) => f.existsSync());
    }
  }

  DateTime get lastModified {
    DateTime time = new DateTime.fromMillisecondsSinceEpoch(0);

    files.forEach((f) {
      DateTime modified = f.lastModifiedSync();
      if (modified.isAfter(time)) {
        time = modified;
      }
    });

    return time;
  }

  // TODO: have a refresh method?

  static void _collect(List<File> files, Directory dir, Glob glob, bool recurse) {
    for (FileSystemEntity entity in dir.listSync(recursive: false, followLinks: false)) {
      String name = fileName(entity);

      if (entity is File) {
        if (glob == null || glob.hasMatch(name)) {
          files.add(entity);
        }
      } else if (entity is Directory) {
        if (recurse && !name.startsWith('.')) {
          _collect(files, entity, glob, recurse);
        }
      }
    }
  }
}

/**
 * Return the last segment of the file path.
 */
String fileName(FileSystemEntity entity) {
  String name = entity.path;
  int index = name.lastIndexOf(Platform.pathSeparator);

  return (index != -1 ? name.substring(index + 1) : name);
}

/**
 * Return the file's extension without the period. This will return `null` if
 * there is no extension.
 */
String fileExt(FileSystemEntity entity) {
  String name = fileName(entity);
  int index = name.indexOf('.');
  return index != -1 && index < name.length ? name.substring(index + 1) : null;
}

/**
 * Return the first n - 1 segments of the file path.
 */
String baseName(FileSystemEntity entity) {
  String name = entity.path;
  int index = name.lastIndexOf(Platform.pathSeparator);

  return (index != -1 ? name.substring(0, index) : null);
}

File joinFile(Directory dir, List<String> files) {
  String pathFragment = files.join(Platform.pathSeparator);
  return new File("${dir.path}${Platform.pathSeparator}${pathFragment}");
}

Directory joinDir(Directory dir, List<String> files) {
  String pathFragment = files.join(Platform.pathSeparator);
  return new Directory("${dir.path}${Platform.pathSeparator}${pathFragment}");
}

/**
 * Return the file pointed to by the given [path]. This method converts the
 * given path to a platform dependent path.
 */
File getFile(String path) {
  if (Platform.pathSeparator == '/') {
    return new File(path);
  } else {
    return new File(path.replaceAll('/', Platform.pathSeparator));
  }
}

/**
 * Return the directory pointed to by the given [path]. This method converts the
 * given path to a platform dependent path.
 */
Directory getDir(String path) {
  if (Platform.pathSeparator == '/') {
    return new Directory(path);
  } else {
    return new Directory(path.replaceAll('/', Platform.pathSeparator));
  }
}

void copyFile(File srcFile, Directory destDir, [GrinderContext context]) {
  File destFile = joinFile(destDir, [fileName(srcFile)]);

  if (!destFile.existsSync() ||
      srcFile.lastModifiedSync() != destFile.lastModifiedSync()) {
    if (context != null) {
      context.log('copying ${srcFile.path} to ${destDir.path}');
    }
    destDir.createSync(recursive: true);
    destFile.writeAsBytesSync(srcFile.readAsBytesSync());
  }
}

void copyDirectory(Directory srcDir, Directory destDir, [GrinderContext context]) {
  if (context != null) {
    context.log('copying ${srcDir.path} to ${destDir.path}');
  }

  for (FileSystemEntity entity in srcDir.listSync()) {
    String name = fileName(entity);

    if (entity is File) {
      copyFile(entity, destDir);
    } else {
      copyDirectory(entity, joinDir(destDir, [name]));
    }
  }
}

void deleteEntity(FileSystemEntity entity, [GrinderContext context]) {
  if (entity.existsSync()) {
    if (context != null) {
      context.log('deleting ${entity.path}');
    }

    entity.deleteSync(recursive: true);
  }
}

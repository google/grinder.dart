// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * General file system routines, useful in the context of running builds. This
 * includes the [FileSet] class, which is used for reasoning about sets of
 * files.
 */
library grinder.files;

import 'dart:io';

import 'package:glob/glob.dart';

import 'grinder.dart';

final String _sep = Platform.pathSeparator;

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
        if (glob == null || glob.matches(name)) {
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

abstract class Path {
  factory Path(FileSystemEntity entity) => new _EntityPath(entity);
  factory Path.str(String p) => new _StringPath(p);

  Path._();

  String get name;

  String get path;

  bool get isDirectory;

  bool get exists;

  FileSystemEntity get entity;

  void copyPath(Directory destDir) => copy(entity, destDir);

  void deletePath() => delete(entity);

  Path join([arg0, String arg1, String arg2, String arg3, String arg4,
    String arg5, String arg6, String arg7, String arg8, String arg9]) {
    List args = [];

    if (arg0 is List) {
      args = arg0;
    } else if (arg0 is String) {
      _addNonNull(args, arg0);
      _addNonNull(args, arg1);
      _addNonNull(args, arg2);
      _addNonNull(args, arg3);
      _addNonNull(args, arg4);
      _addNonNull(args, arg5);
      _addNonNull(args, arg6);
      _addNonNull(args, arg7);
      _addNonNull(args, arg8);
      _addNonNull(args, arg9);
    }

    if (args.isEmpty) {
      return this;
    } else {
      return new Path.str('${path}${_sep}${args.join(_sep)}');
    }
  }

  File returnAsFile() => new File(path);

  Directory returnAsDirectory() => new Directory(path);

  String toString() => path;
}

class _EntityPath extends Path {
  final FileSystemEntity _entity;

  _EntityPath(this._entity) : super._();

  FileSystemEntity get entity => _entity;

  bool get exists => _entity.existsSync();

  bool get isDirectory => _entity is Directory;

  String get name => fileName(_entity);

  String get path => _entity.path;
}

class _StringPath extends Path {
  final String _path;

  _StringPath(this._path) : super._();

  FileSystemEntity get entity {
    final FileSystemEntityType type = FileSystemEntity.typeSync(_path);

    if (type == FileSystemEntityType.FILE) {
      return new File(_path);
    } else if (type == FileSystemEntityType.DIRECTORY) {
      return new Directory(_path);
    } else if (type == FileSystemEntityType.LINK) {
      return new Link(_path);
    } else {
      return null;
    }
  }

  bool get exists =>
      FileSystemEntity.typeSync(_path) != FileSystemEntityType.NOT_FOUND;

  bool get isDirectory => FileSystemEntity.isDirectorySync(_path);

  String get name {
    int index = _path.lastIndexOf(_sep);
    return index != -1 ? _path.substring(index + 1) : null;
  }

  String get path => _path;
}

/**
 * Return the last segment of the file path.
 */
String fileName(FileSystemEntity entity) {
  String name = entity.path;
  int index = name.lastIndexOf(_sep);
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
  int index = name.lastIndexOf(_sep);
  return (index != -1 ? name.substring(0, index) : null);
}

File joinFile(Directory dir, List<String> files) {
  String pathFragment = files.join(_sep);
  return new File("${dir.path}${_sep}${pathFragment}");
}

Directory joinDir(Directory dir, List<String> files) {
  String pathFragment = files.join(_sep);
  return new Directory("${dir.path}${_sep}${pathFragment}");
}

/**
 * Return the file pointed to by the given [path]. This method converts the
 * given path to a platform dependent path.
 */
File getFile(String path) {
  if (_sep == '/') {
    return new File(path);
  } else {
    return new File(path.replaceAll('/', _sep));
  }
}

/**
 * Return the directory pointed to by the given [path]. This method converts the
 * given path to a platform dependent path.
 */
Directory getDir(String path) {
  if (_sep == '/') {
    return new Directory(path);
  } else {
    return new Directory(path.replaceAll('/', _sep));
  }
}

void copy(FileSystemEntity entity, Directory destDir, [GrinderContext context]) {
  if (entity is Directory) {
    if (context != null) {
      context.log('copying ${entity.path} to ${destDir.path}');
    }

    for (FileSystemEntity entity in entity.listSync()) {
      String name = fileName(entity);

      if (entity is File) {
        copy(entity, destDir);
      } else {
        copy(entity, joinDir(destDir, [name]));
      }
    }
  } else if (entity is File) {
    File destFile = joinFile(destDir, [fileName(entity)]);

    if (!destFile.existsSync() ||
        entity.lastModifiedSync() != destFile.lastModifiedSync()) {
      if (context != null) {
        context.log('copying ${entity.path} to ${destDir.path}');
      }
      destDir.createSync(recursive: true);
      entity.copySync(destFile.path);
    }
  } else {
    throw new StateError('unexpected type: ${entity.runtimeType}');
  }
}

/**
 * Delete the given file entity reference.
 */
void delete(FileSystemEntity entity, [GrinderContext context]) {
  if (entity.existsSync()) {
    if (context != null) {
      context.log('deleting ${entity.path}');
    }

    entity.deleteSync(recursive: true);
  }
}


@Deprecated('deprecated in favor of copy()')
void copyFile(File srcFile, Directory destDir, [GrinderContext context]) {
  copy(srcFile, destDir, context);
}

@Deprecated('deprecated in favor of copy()')
void copyDirectory(Directory srcDir, Directory destDir, [GrinderContext context]) {
  copy(srcDir, destDir, context);
}

@Deprecated('deprecated in favor of delete()')
void deleteEntity(FileSystemEntity entity, [GrinderContext context]) {
  delete(entity, context);
}

_addNonNull(List args, String arg) {
  if (arg != null) args.add(arg);
}

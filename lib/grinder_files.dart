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

  static void _collect(
      List<File> files, Directory dir, Glob glob, bool recurse) {
    for (FileSystemEntity entity
        in dir.listSync(recursive: false, followLinks: false)) {
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

/// A class to make it easier to manipulate file system entites. Once paths or
/// entites are converted into `Path`s, they can be easily copied, deleted,
/// joined, and their name retrieved.
class FilePath {
  /// Creates a temporary directory in the system temp directory. See
  /// [Directory.systemTemp] and [Directory.createTempSync]. If [prefix] is
  /// missing or null, the empty string is used for [prefix].
  static FilePath createSystemTemp([String prefix]) {
    return new FilePath(Directory.systemTemp.createTempSync(prefix));
  }

  static FilePath get current => new FilePath(Directory.current);

  final String _path;

  /// Create a new [FilePath]. The [entityOrString] parameter can be a
  /// [FileSystemEntity] or a [String]. If a [String], this method converts the
  /// given path from a platform independent one to a platform dependent path.
  /// This conversion will work for relative paths but wouldn't make sense to
  /// use for absolute ones.
  FilePath(entityOrString) : _path = _coerce(entityOrString);

  String get name {
    int index = _path.lastIndexOf(_sep);
    return index != -1 ? _path.substring(index + 1) : null;
  }

  String get path => _path;

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

  /// Return whether an entity actually exists for this path. The entity could
  /// be a [File], [Directory], or [Link].
  bool get exists {
    return FileSystemEntity.typeSync(_path) != FileSystemEntityType.NOT_FOUND;
  }

  /// Returns the containing [Path]. Returns a non-null value even if this is a
  /// root directory.
  ///
  /// See [FileSystemEntity.parent].
  FilePath get parent {
    int index = _path.lastIndexOf(_sep);

    // Do string manipulation if there are path separators; otherwise, use the
    // file system entity information.
    if (index == 0 || index == -1) {
      FileSystemEntity e = entity;
      return e == null ? null : new FilePath(e.parent);
    } else {
      return new FilePath(_path.substring(0, index));
    }
  }

//  /// Returns the abolute version of this Path.
//  FilePath get absolute {
//    // TODO:
//  }

  bool get isDirectory => FileSystemEntity.isDirectorySync(_path);
  bool get isFile => FileSystemEntity.isFileSync(_path);
  bool get isLink => FileSystemEntity.isLinkSync(_path);

  /// Assume the current file system entity is a [File] and return it as such.
  /// You would call this instead of [entity] when the file system entity does
  /// not yet exist.
  File get asFile => new File(path);

  /// Assume the current file system entity is a [Directory] and return it as
  /// such. You would call this instead of [entity] when the file system entity
  /// does not yet exist.
  Directory get asDirectory => new Directory(path);

  /// Assume the current file system entity is a [Link] and return it as such.
  /// You would call this instead of [entity] when the file system entity does
  /// not yet exist.
  Link get asLink => new Link(path);

  /// Copy the the entity to the given destination. Return the newly created
  /// [FilePath].
  FilePath copy(FilePath destDir) {
    _copyImpl(entity, destDir.asDirectory);
    return new FilePath(destDir).join(name);
  }

  /// Delete the entity at the path.
  void delete() => _deleteImpl(entity);

  /// Synchronously create the file. See also [File.createSync].
  ///
  /// If [recursive] is false, the default, the file is created only if all
  /// directories in the path exist. If [recursive] is true, all non-existing
  /// path components are created.
  File createFile({bool recursive: false}) {
    var file = asFile;
    file.createSync(recursive: recursive);
    return file;
  }

  /// Synchronously create the directory. See also [Directory.createSync].
  ///
  /// If [recursive] is false, the default, the file is created only if all
  /// directories in the path exist. If [recursive] is true, all non-existing
  /// path components are created.
  Directory createDirectory({bool recursive: false}) {
    var directory = asDirectory;
    directory.createSync(recursive: recursive);
    return directory;
  }

  /// Synchronously create the link. See also [Link.createSync].
  ///
  /// If [recursive] is false, the default, the file is created only if all
  /// directories in the path exist. If [recursive] is true, all non-existing
  /// path components are created.
  Link createLink(FilePath target, {bool recursive: false}) {
    var link = asLink;
    link.createSync(target.path, recursive: recursive);
    return link;
  }

  /// Return the file length; if this FilePath is not a File, return 0.
  int get length => isFile ? asFile.lengthSync() : 0;

  /// Join the given path elements to this path, and return a new [FilePath] object.
  FilePath join(
      [arg0,
      String arg1,
      String arg2,
      String arg3,
      String arg4,
      String arg5,
      String arg6,
      String arg7,
      String arg8,
      String arg9]) {
    List paths = [path];

    if (arg0 is List) {
      paths.addAll(arg0);
    } else if (arg0 is String) {
      _addNonNull(paths, arg0);
      _addNonNull(paths, arg1);
      _addNonNull(paths, arg2);
      _addNonNull(paths, arg3);
      _addNonNull(paths, arg4);
      _addNonNull(paths, arg5);
      _addNonNull(paths, arg6);
      _addNonNull(paths, arg7);
      _addNonNull(paths, arg8);
      _addNonNull(paths, arg9);
    }

    if (paths.length == 1) {
      return this;
    } else {
      return new FilePath(paths.join(_sep));
    }
  }

  bool operator ==(other) => other is FilePath && path == other.path;

  int get hashCode => path.hashCode;

  String toString() => path;

  static String _coerce(arg) {
    if (arg is String) {
      if (_sep != '/') arg = arg.replaceAll('/', _sep);

      if (arg.length > 1 && arg.endsWith((_sep))) {
        return arg.substring(0, arg.length - 1);
      } else {
        return arg;
      }
    }
    if (arg is FileSystemEntity) return arg.path;
    if (arg is FilePath) return arg.path;
    throw new ArgumentError('expected a FileSystemEntity or a String');
  }
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

void copy(FileSystemEntity entity, Directory destDir,
    [GrinderContext context]) {
  log('copying ${entity.path} to ${destDir.path}');
  return _copyImpl(entity, destDir, context);
}

void _copyImpl(FileSystemEntity entity, Directory destDir,
    [GrinderContext context]) {
  if (entity is Directory) {
    for (FileSystemEntity entity in entity.listSync()) {
      String name = fileName(entity);

      if (entity is File) {
        _copyImpl(entity, destDir);
      } else {
        _copyImpl(entity, joinDir(destDir, [name]));
      }
    }
  } else if (entity is File) {
    File destFile = joinFile(destDir, [fileName(entity)]);

    if (!destFile.existsSync() ||
        entity.lastModifiedSync() != destFile.lastModifiedSync()) {
      destDir.createSync(recursive: true);
      entity.copySync(destFile.path);
    }
  } else {
    throw new StateError('unexpected type: ${entity.runtimeType}');
  }
}

/// Delete the given file entity reference.
void delete(FileSystemEntity entity) => _deleteImpl(entity);

void _deleteImpl(FileSystemEntity entity) {
  if (entity.existsSync()) {
    log('deleting ${entity.path}');
    entity.deleteSync(recursive: true);
  }
}

/// Prefer using [copy].
void copyFile(File srcFile, Directory destDir, [GrinderContext context]) {
  copy(srcFile, destDir, context);
}

/// Prefer using [copy].
void copyDirectory(Directory srcDir, Directory destDir,
    [GrinderContext context]) {
  copy(srcDir, destDir, context);
}

/// Prefer using [delete].
void deleteEntity(FileSystemEntity entity, [GrinderContext context]) {
  delete(entity);
}

_addNonNull(List args, String arg) {
  if (arg != null) args.add(arg);
}

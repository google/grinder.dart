// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * General file system routines, useful in the context of running builds. This
 * includes the [FileSet] class, which is used for reasoning about sets of
 * files.
 */
library grinder.files;

import 'dart:io';

// TODO: add files to a set

// TODO: union sets?

// TODO: add tests for upToDate()

/**
 * A class to handle defining, composing, and comparing groups of files.
 */
class FileSet {
  List<File> files = [];

  FileSet.fromDir(Directory dir, {RegExp pattern, String endsWith, bool recurse: false}) {
    if (pattern == null && endsWith != null) {
      endsWith = endsWith.replaceAll('.', '\\.');
      pattern = new RegExp(".*${endsWith}\$");
    }

    // TODO: handle recursion
    // TODO: skip '.' directories

    if (dir.existsSync()) {
      files = dir.listSync(recursive: false, followLinks: false).where((FileSystemEntity entity) {
        if (entity is File) {
          return pattern.matchAsPrefix(fileName(entity)) != null;
        } else {
          return false;
        }
      }).toList();
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
      // TODO: add a test for this
      return !other.lastModified.isAfter(lastModified);
    }
  }

  bool get exists {
    if (files.isEmpty) {
      return false;
    }

    return files.any((f) => f.existsSync());
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

}

String fileName(FileSystemEntity entity) {
  String name = entity.path;
  int index = name.lastIndexOf(Platform.pathSeparator);

  if (index != -1) {
    name = name.substring(index + 1);
  }

  return name;
}

String baseName(FileSystemEntity entity) {
  String name = entity.path;
  int index = name.lastIndexOf(Platform.pathSeparator);

  if (index != -1) {
    return name.substring(0, index);
  } else {
    return null;
  }
}

//void copyDirectory(Directory srcDir, Directory destDir) {
//  for (FileSystemEntity entity in srcDir.listSync()) {
//    String name = getName(entity);
//
//    if (entity is File) {
//      copyFile(entity, destDir);
//    } else {
//      copyDirectory(entity, joinDir(destDir, [name]));
//    }
//  }
//}

File joinFile(Directory dir, List<String> files) {
  String pathFragment = files.join(Platform.pathSeparator);
  return new File("${dir.path}${Platform.pathSeparator}${pathFragment}");
}

Directory joinDir(Directory dir, List<String> files) {
  String pathFragment = files.join(Platform.pathSeparator);
  return new Directory("${dir.path}${Platform.pathSeparator}${pathFragment}");
}

@deprecated
Directory getParent(Directory dir) {
  String base = baseName(dir);

  if (base == null) {
    return null;
  } else {
    return new Directory(base);
  }
}

void copyFile(File srcFile, Directory destDir) {
  File destFile = joinFile(destDir, [fileName(srcFile)]);

  if (!destFile.existsSync() ||
      srcFile.lastModifiedSync() != destFile.lastModifiedSync()) {
    destDir.createSync(recursive: true);
    destFile.writeAsBytesSync(srcFile.readAsBytesSync());
  }
}

// TODO: this should take a context, and log if it does any work -

void copyDirectory(Directory srcDir, Directory destDir) {
  for (FileSystemEntity entity in srcDir.listSync()) {
    String name = fileName(entity);

    if (entity is File) {
      copyFile(entity, destDir);
    } else {
      copyDirectory(entity, joinDir(destDir, [name]));
    }
  }
}

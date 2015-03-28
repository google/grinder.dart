// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli_test;

import 'package:grinder/src/cli.dart';
import 'package:unittest/unittest.dart';

main() {
  group('cli', () {
    test('cleanupStackTrace', () {
      expect(cleanupStackTrace(_st), _stExpected);
    });
  });
}

final _st = '''
#0      GrinderContext.fail (package:grinder/grinder.dart:131:5)
#1      fail (package:grinder/grinder.dart:85:42)
#2      analyze (file:///Users/devoncarew/projects/grinder.dart/tool/grind.dart:17:7)
#3      _LocalLibraryMirror._invoke (dart:mirrors-patch/mirrors_impl.dart:1313)
#4      _LocalObjectMirror.invoke (dart:mirrors-patch/mirrors_impl.dart:382)
#5      TaskDiscovery.discoverDeclaration.<anon> (package:grinder/src/discover_tasks.dart:80:44)
#6      _rootRun (dart:async/zone.dart:895)
#7      _CustomZone.run (dart:async/zone.dart:796)
#8      runZoned (dart:async/zone.dart:1251)
#9      ZonedValue.withValue (package:grinder/src/utils.dart:115:20)
#10     GrinderTask.execute (package:grinder/grinder.dart:169:36)
#11     Grinder._executeTask (package:grinder/grinder.dart:373:30)
#12     Grinder.start.<anon> (package:grinder/grinder.dart:348:28)
#13     Future.forEach.<anon>.<anon> (dart:async/future.dart:336)
#14     Future.Future.sync (dart:async/future.dart:168)
#15     Future.forEach.<anon> (dart:async/future.dart:336)
#16     Future.Future.sync (dart:async/future.dart:168)
#17     Future.doWhile.<anon> (dart:async/future.dart:361)
#18     _RootZone.runUnaryGuarded (dart:async/zone.dart:1093)
#19     _RootZone.bindUnaryCallback.<anon> (dart:async/zone.dart:1122)
#20     _RootZone.runUnary (dart:async/zone.dart:1155)
#21     _Future._propagateToListeners.handleValueCallback (dart:async/future_impl.dart:484)
#22     _Future._propagateToListeners (dart:async/future_impl.dart:567)
#23     _Future._completeWithValue (dart:async/future_impl.dart:358)
#24     _Future._asyncComplete.<anon> (dart:async/future_impl.dart:412)
#25     _asyncRunCallbackLoop (dart:async/schedule_microtask.dart:41)
#26     _asyncRunCallback (dart:async/schedule_microtask.dart:48)
#27     _runPendingImmediateCallback (dart:isolate-patch/isolate_patch.dart:96)
#28     _Timer._runTimers (dart:isolate-patch/timer_impl.dart:392)
#29     _handleMessage (dart:isolate-patch/timer_impl.dart:411)
#30     _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:142)
''';

final _stExpected = '''
#0      GrinderContext.fail (package:grinder/grinder.dart:131:5)
#1      fail (package:grinder/grinder.dart:85:42)
#2      analyze (file:///Users/devoncarew/projects/grinder.dart/tool/grind.dart:17:7)''';

// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library all_test;

import 'cli_test.dart' as cli_test;
import 'discover_tasks_test.dart' as get_annotated_tasks_test;
import 'grinder_test.dart' as grinder_test;
import 'grinder_files_test.dart' as grinder_files_test;
import 'grinder_tools_test.dart' as grinder_tools_test;

main() {
  cli_test.main();
  get_annotated_tasks_test.main();
  grinder_test.main();
  grinder_files_test.main();
  grinder_tools_test.main();
}

// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library all_test;

import 'grinder_test.dart' as grinder_test;
import 'grinder_files_test.dart' as grinder_files_test;
import 'grinder_sdk_test.dart' as grinder_sdk_test;
import 'integration_test.dart' as integration_test;
import 'src/cli_util_test.dart' as src_cli_test;
import 'src/discover_tasks_test.dart' as src_discover_tasks_test;
import 'src/utils_test.dart' as src_utils_test;
import 'src/run_test.dart' as src_run_test;

main() {
  grinder_test.main();
  grinder_files_test.main();
  grinder_sdk_test.main();
  integration_test.main();
  src_cli_test.main();
  src_discover_tasks_test.main();
  src_utils_test.main();
  src_run_test.main();
}

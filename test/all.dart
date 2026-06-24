// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'grinder_test.dart' as grinder_test;
import 'integration_test.dart' as integration_test;
import 'src/cli_util_test.dart' as src_cli_test;
import 'src/discover_tasks_test.dart' as src_discover_tasks_test;
import 'src/files_test.dart' as src_files_test;
import 'src/run_test.dart' as src_run_test;
import 'src/sdk_test.dart' as src_sdk_test;
import 'src/utils_test.dart' as src_utils_test;

void main() {
  grinder_test.main();
  integration_test.main();
  src_cli_test.main();
  src_discover_tasks_test.main();
  src_files_test.main();
  src_run_test.main();
  src_sdk_test.main();
  src_utils_test.main();
}

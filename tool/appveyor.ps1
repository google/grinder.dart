# Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
# All rights reserved. Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

param([string]$action)

function throw_if_process_failed {
    param([string]$message)
    if ($LASTEXITCODE -ne 0) { throw $message }
}

function install {
    start-filedownload https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-windows-x64-release.zip
    7z.exe x dartsdk-windows-x64-release.zip -oc:\ | select-string "^Extracting" -notmatch
    throw_if_process_failed "could not extract sdk"
}

function test {
    $env:PATH = "c:\dart-sdk\bin;$env:PATH"

    # Install global tools.
    pub global activate tuneup
    # Verify that the libraries are error free.
    pub global run tuneup check --ignore-infos
    throw_if_process_failed "libraries have errors"

    # Run the tests.
    dart test/all.dart 
    # Verify that the generated grind script analyzes well.
    dart tool/grind.dart analyze-init
}

switch ($action) {
    "install" { install }
    "test" { test }
}
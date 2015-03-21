param([string]$action)

function install {
    start-filedownload https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-windows-x64-release.zip
    7z.exe x dartsdk-windows-x64-release.zip -oc:\ | select-string "^Extracting" -notmatch
}

function test {
    $env:PATH = "c:\dart-sdk\bin;$env:PATH"

    # Install global tools.
    pub global activate tuneup
    # Verify that the libraries are error free.
    pub global run tuneup check --ignore-infos
    if ($LASTEXITCODE -ne 0) { throw "libraries have errors" }

    # Run the tests.
    dart test/all.dart 
    # Verify that the generated grind script analyzes well.
    dart tool/grind.dart analyze-init
}

switch ($action) {
    "install" { install }
    "test" { test }
}
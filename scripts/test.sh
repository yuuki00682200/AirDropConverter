#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
task_test_dir="$(mktemp -d)"
trap 'rm -rf "$task_test_dir"' EXIT
xcrun swiftc -module-cache-path "$task_test_dir/cache" AirDropConverter/FileArrivalTracker.swift AirDropConverter/ImageConverter.swift Tests/ConversionTests.swift -o "$task_test_dir/tests"
"$task_test_dir/tests"

#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/menubar-tests
sed '/^if CommandLine.arguments.contains("--diagnostics")/,$d' Sources/CodexVisual/main.swift > .build/menubar-tests/main.swift
cat Tests/CodexVisualTests/MenuBarTests.swift >> .build/menubar-tests/main.swift
swiftc -swift-version 6 .build/menubar-tests/main.swift -o .build/menubar-tests/check
.build/menubar-tests/check

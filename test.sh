#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build/tests .build/module-cache
cp Tests/SmokeTests.swift .build/tests/main.swift
cp -R Resources/en.lproj Resources/ko.lproj .build/tests/
xcrun swiftc -Osize -whole-module-optimization -swift-version 5 -target "$(uname -m)-apple-macosx13.0" \
  -module-cache-path "$PWD/.build/module-cache" \
  -framework AppKit -framework SwiftUI -framework QuartzCore -framework ScreenCaptureKit -framework CoreImage \
  Sources/Localization.swift Sources/Preferences.swift Sources/Overlay.swift Sources/ZoomCapture.swift Sources/EffectTransition.swift Sources/KeystrokeMonitor.swift Sources/KeyDisplay.swift .build/tests/main.swift \
  -o .build/tests/SmokeTests
xcrun strip -S -x .build/tests/SmokeTests
.build/tests/SmokeTests
BIGMOUSE_EXPECTED_LANGUAGE=ko .build/tests/SmokeTests --localization-only -AppleLocale en_KR -AppleLanguages '(en)'
BIGMOUSE_EXPECTED_LANGUAGE=en .build/tests/SmokeTests --localization-only -AppleLocale ko_US -AppleLanguages '(ko)'
BIGMOUSE_EXPECTED_LANGUAGE=en .build/tests/SmokeTests --localization-only -AppleLocale ja_JP -AppleLanguages '(ja)'

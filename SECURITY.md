# Security / 보안

## Reporting a vulnerability

Do not post private keystrokes, captured screens, credentials, or exploit details in a public issue.

Use [private vulnerability reporting](https://github.com/jvisualschool/BIGMOUSE/security/advisories/new). If that form is unavailable, open an issue asking for a private security contact, without describing the vulnerability publicly. [GitHub reporting guidance](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately)

Include the BigMouse version, macOS version, architecture, reproduction steps using dummy input, expected behavior, and impact. No response-time guarantee is currently defined.

## Data and permissions

| Data | Processing | Persistence / transmission |
| --- | --- | --- |
| Keystrokes | Read-only event tap while display is enabled; up to 24 short labels | Memory only; expires about 1.8 seconds after the last input |
| Screen images | ScreenCaptureKit frames from the display under the pointer, used during zoom and fade-out | No app file or network output; audio capture disabled |
| Display/window metadata | Prepared to reduce zoom startup delay; invalidated on pause, sleep, or display changes | In-process only |
| Preferences | Color, size, display mode, position, shortcut, enabled effects | Local macOS UserDefaults |
| Diagnostics | Numeric first-frame zoom latency | macOS unified log; no input text or image content |

The app code has no network client, server listener, remote updater, shell execution, telemetry SDK, login, or bundled credentials. Input Monitoring and Screen Recording are requested through macOS for their respective features. The app has no App Sandbox entitlement; it is not described as sandboxed.

## Security boundaries

- Key display is off at launch. Disabling it removes the event tap and clears its buffer.
- Pause, sleep, session deactivation, and display rebuild clear key display and stop zoom. Hidden overlays drop key strings, text-layer content, and magnified-image references.
- macOS Secure Event Input is checked before processing or displaying input. This is not a universal password-field detector. Disable key display before typing sensitive information.
- On-screen content may be captured by an external recording or sharing application.
- Clearing Swift/Core Animation references is not a guarantee of cryptographic memory erasure, nor protection against OS swap, crash dumps, or a compromised local account.
- OS permission prompts and macOS diagnostics have their own system behavior.

## Release integrity

The build uses a fresh staging bundle. Packaging rejects unexpected files and symlinks and supplies a SHA-256 checksum. Verify checksums from a trusted release channel; a checksum by itself does not authenticate the publisher.

The first official release is **version 0.7**, free through [GitHub](https://github.com/jvisualschool/BIGMOUSE/) and the [developer website](https://jvibeschool.org/BIGMOUSE/). It is not a Mac App Store release. Developer ID signing and notarization also support direct distribution. [Apple distribution guidance](https://developer.apple.com/macos/distribution/)

The official 0.7 / build 15 app has an **ad hoc signature**, with no Developer ID identity, Hardened Runtime, or Apple notarization. It is published as an official GitHub release. ZIP contents and local signature integrity are checked; installation on another Mac remains unverified. Developer ID signing and notarization are pending for a future signed release. Do not treat the earlier source review or local signature check as Apple approval.

See the [dated review](docs/security-review-2026-10-18.md) for findings, fixes, and validation limits. This is a focused source/build review, not a security assessment certificate or a claim that the app has no vulnerabilities.

## 한국어 안내

취약점은 GitHub의 비공개 취약점 제보 기능을 이용해 주세요. 기능이 없으면 세부 내용을 공개하지 말고 비공개 연락 방법만 문의하세요. 비밀번호·실제 키 입력·화면 내용·인증서는 첨부하지 않습니다.

키 입력과 확대 화면은 앱에서 파일로 저장하거나 전송하지 않습니다. 설정만 로컬에 저장하며 진단 로그에는 줌 시작 시간만 기록합니다. 일시 정지 시 표시 계층의 입력 문자열·이미지 참조도 제거합니다. 메모리의 완전 삭제나 모든 암호 입력란 보호를 보장하지는 않으므로 민감한 입력 전에는 키 표시를 꺼 주세요.

첫 공개 버전 0.7 / 빌드 15는 GitHub와 홈페이지에서 무료로 제공하는 공식 버전입니다. 임시 서명만 적용되며 GitHub 정식 릴리스로 제공합니다. ZIP 내용과 로컬 서명 무결성은 검사하지만 Developer ID 서명·Apple 공증과 별도 Mac에서의 신규 설치 검증은 미완료입니다.

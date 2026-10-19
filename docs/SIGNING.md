# 업데이트와 권한 / Updates and permissions

## 한국어

BigMouse 0.8부터 동일한 전용 인증서와 앱 식별자로 서명합니다. 이전 임시 서명은 실행 파일이 달라질 때 앱 식별 기준도 바뀌어 화면 기록·입력 모니터링 권한을 다시 연결해야 했습니다.

- `config/signing.json`에는 공개 인증서의 지문만 저장합니다. 개인 키는 개발자의 로그인 키체인에 보관하며 소스·앱·배포 ZIP에 넣지 않습니다.
- `bash build.sh`는 고정된 서명 키가 없으면 중단합니다. 임시 서명으로 조용히 대체하지 않습니다.
- `scripts/signing.py verify APP`은 앱 무결성, 앱 식별자, 인증서 SHA-1 요구사항과 SHA-256 지문을 검사합니다. 패키징에도 같은 검사를 적용합니다.
- `scripts/signing.py verify-update OLD NEW`로 업데이트 전후 앱이 동일한 인증서에 연결되는지 검사합니다.
- 공개 서명 키가 없는 개발자는 `bash build.sh --development`를 사용할 수 있습니다. `dist/BigMouse Dev.app`과 별도 앱 식별자를 사용하므로 배포 앱과 권한을 공유하지 않습니다.

기존 임시 서명 앱에서 처음 전환할 때는 화면 기록과 입력 모니터링을 한 번 다시 허용해야 합니다. 이후에는 같은 서명으로 만든 업데이트를 같은 위치의 앱에 교체합니다. macOS의 추가 확인이나 사용자가 직접 취소한 권한까지 없애는 기능은 아닙니다.

전용 인증서는 자체 발급한 코드 서명 인증서입니다. Developer ID 또는 Apple 공증을 받은 상태는 아니며, 처음 실행 시 macOS의 실행 허용 절차는 유지됩니다. 사용자가 인증서를 설치하거나 시스템 신뢰 설정을 바꿀 필요는 없습니다.

개인 키를 잃으면 기존 서명을 재현할 수 없습니다. 로그인 키체인을 안전하게 백업하고, 키를 다시 만드는 것으로 복구하지 마세요. 인증서를 교체할 때는 별도의 이전·권한 검증이 필요합니다. 공개 인증서 지문을 바꾸는 것만으로 기존 권한이 유지되지는 않습니다.

## English

Starting with BigMouse 0.8, releases use one dedicated certificate and bundle identifier. Earlier ad hoc signatures identified a specific build, so an update could lose access to Screen Recording and Input Monitoring.

- `config/signing.json` contains public certificate fingerprints only. The private key stays in the developer's login keychain and is never included in source or release archives.
- `bash build.sh` stops if the pinned signing key is unavailable; it never silently falls back to ad hoc signing.
- `scripts/signing.py verify APP` checks bundle integrity, bundle identity, the certificate-bound requirement and SHA-256 certificate fingerprint. Packaging uses the same verification.
- `scripts/signing.py verify-update OLD NEW` checks that both builds use the pinned identity.
- Contributors without the release key can use `bash build.sh --development`. It builds `dist/BigMouse Dev.app` with a separate bundle identifier and independent permissions.

Moving from an ad hoc build requires a one-time permission grant. Later updates use the same certificate and app location. This does not suppress additional macOS prompts or override permissions revoked by the user.

The dedicated certificate is self-issued for code signing. It is not Developer ID signing or Apple notarization, so first-launch approval is still required. Users do not need to install a certificate or change certificate trust settings.

Back up the login keychain securely. Losing or replacing the private key changes the app's identity and requires a separate migration and permission test.

## 검증 기록 / Validation

2026-10-19, macOS 27.0.1 / Apple Silicon에서 실행 파일 해시가 다른 빌드 20을 21로 교체했습니다. 권한을 초기화하거나 다시 요청하지 않고 확대 화면 프레임과 입력 이벤트 모니터가 작동했습니다. / On 2026-10-19, build 20 was replaced by build 21 with a different executable hash on macOS 27.0.1 / Apple Silicon. Screen frames and the input-event monitor continued working without resetting or re-requesting permissions.

## References

- [Apple: Code signing requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)
- [Apple DTS: ScreenCaptureKit permissions and ad hoc signing](https://developer.apple.com/forums/thread/819406)
- [Apple: Code Signing Tasks](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html)

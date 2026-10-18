# BigMouse 보안 점검 — 2026-10-18

대상: 0.3.6 / 빌드 14, 로컬 소스·전체 Git 이력·빌드 및 ZIP.
환경: macOS 27.0.1, Apple Silicon arm64, Apple Swift 6.4.
초기 0.3.6 검사 당시 GitHub 원격 저장소가 없어 온라인 설정·Actions·Release는 대상에 포함하지 않았습니다. 이후 v0.7 공개 전 재검사는 문서 마지막에 기록합니다.

## 결과

발견한 앱 내부 데이터 잔존과 재빌드 파일 혼입 문제를 수정했습니다. 점검한 소스에는 키 입력·캡처 영상의 파일 저장이나 네트워크 전송 경로가 없었습니다. 주요 자격증명 패턴 검색에서 일치 항목은 발견되지 않았습니다.

이 결과는 제한된 정적 검토와 동작 검사이며, 악성코드 검사 인증이나 취약점 부재 보증은 아닙니다. 정식 서명·공증·라이선스와 별도 기기 설치 검증은 남아 있습니다.

## 수정한 문제

| 항목 | 기존 동작과 영향 | 수정 | 확인 |
| --- | --- | --- | --- |
| 숨긴 화면의 데이터 참조 잔존 | 일시 정지 시 창만 숨겨 마지막 키 문자열과 확대 이미지가 렌더링 계층에 남을 수 있음. 외부 유출을 확인한 것은 아니나 불필요한 보관과 재표시 가능성을 줄일 필요가 있었음 | `KeyDisplayRenderer.clear()`, 숨김 시 렌즈 이미지 참조 제거, 일시 정지·재구성·종료 시 마지막 키 상태 초기화, 정지 상태의 tick 차단 | 보유한 텍스트 계층 참조까지 검사하여 문자열·contents가 nil인지 확인. 다시 표시해도 이전 키/이미지 숨김 유지 |
| 기존 앱 폴더의 잔여 파일 혼입 | 이전 `dist/BigMouse.app`을 재사용해 수동 추가 파일이 다음 서명·배포에 포함될 수 있음 | 새 임시 번들에서 빌드·서명 검증 후 교체. 기존 앱은 성공 전까지 유지 | 이전 번들에 무해한 검사 파일을 넣고 새 빌드에서 제거됨을 확인 |
| 배포 묶음 검증 부재 | ZIP 내용과 무결성을 확인하는 반복 가능한 절차가 없었음 | 파일 허용 목록, 심볼릭 링크 거부, 기존 릴리스 덮어쓰기 차단, SHA-256 파일 생성 | 예상 밖 파일·심볼릭 링크·덮어쓰기 각각 거부 확인. ZIP 해제 후 전체 파일 해시와 서명 재검증 |

관련 소스: [KeyDisplay.swift](../Sources/KeyDisplay.swift), [Overlay.swift](../Sources/Overlay.swift), [build.sh](../build.sh), [package-release.sh](../scripts/package-release.sh).

메모리 참조 해제는 Swift·Core Animation·OS 메모리의 물리적인 완전 삭제를 뜻하지 않습니다.

## 데이터·권한 검토

- 키 입력: 표시 활성화 시 읽기 전용 `CGEvent` 탭 설치. 비활성화 시 제거. 최대 24개/144자 버퍼, 마지막 입력 약 1.8초 후 소멸.
- 보안 입력: `IsSecureEventInputEnabled()`를 수신과 표시 경로에서 검사. 모든 앱의 비밀번호란을 식별하는 기능은 아니므로 민감한 입력 전에는 키 표시를 꺼야 함.
- 화면: ScreenCaptureKit, 오디오 비활성화. 줌 종료·일시 정지 시 캡처 중단 및 참조 해제. 대기 중 화면/창 메타데이터 준비와 영상 캡처를 구분.
- 저장: UserDefaults에 설정 저장. 입력·영상 저장 경로 없음.
- 로그: 줌 첫 프레임 지연 시간만 OSLog에 기록. 입력 문자·화면 내용 없음.
- 통신/실행: 앱 소스에서 네트워크 클라이언트·서버·원격 업데이트·프로세스 실행 경로 없음. System Settings의 두 고정 URL만 열며 외부 URL 입력 기능 없음.
- 실행 의존성: `otool -L` 결과 Apple 시스템 프레임워크·Swift 런타임만 사용.
- 배포 바이너리의 문자열 검사에서 `/Users/` 절대 경로 없음.
- 앱은 App Sandbox를 사용하지 않음. 최종 서명 검사에서도 sandbox entitlement를 확인하지 못했으므로 샌드박스 앱이라고 표기하지 않음.

## 자격증명·공개 범위

초기 검사에서 현재 파일 32개와 Git 이력의 고유 blob 92개를 대상으로 다음 7종 패턴을 검사했고, 일치 항목은 0개였습니다.

개인 키 헤더, AWS 키 ID, GitHub 토큰, OpenAI 키, Google API 키, 비밀번호를 포함한 연결 URL, 긴 리터럴 자격증명 대입.

Gitleaks/TruffleHog가 설치되어 있지 않아 로컬 패턴 검사를 사용했습니다. 알 수 없는 토큰 형식·인코딩된 비밀·이미지 내 정보까지 검증하는 검사는 아닙니다.

Git 이력의 작업 일지에는 개인 로컬 경로와 검증 이력이 있습니다. `.gitattributes`로 소스 ZIP에서 작업 일지를 제외하고, 새 일지는 gitignore로 로컬에만 남깁니다. **이미 존재하는 커밋은 그대로이며, 공개 push 전에 이력 공개 범위를 확인해야 합니다.** 이력 재작성이나 원격 게시를 수행하지 않았습니다.

## 검증 결과

- `bash test.sh`: 112개 기본·지역·렌더링 검사 및 별도 지역 실행 22개 × 3회, 총 178개 통과.
- 영어 선호 언어 + 한국 지역 → 한국어, 한국어 선호 언어 + 미국 지역 → 영어, 일본어·일본 지역 → 영어.
- 두 언어 설정 화면 시각 확인. 영어 색상·표시 방식·위치 버튼과 권한 안내가 잘리지 않음.
- `bash build.sh`, 코드 서명 검증, plist/번역 파일 문법, 셸 문법, 공백 오류 검사 통과.
- 잔여 파일 제거, 예상 밖 파일·심볼릭 링크·ZIP 덮어쓰기 거부 검사 통과.
- 앱 내부 일반 파일 12개, 합계 **656,247바이트**.
- 배포 ZIP **399,730바이트**. ZIP을 `ditto`로 해제한 뒤 원본 12개 파일의 SHA-256 전체 일치 및 코드 서명 검증 통과.

실행 파일 SHA-256:

```text
bc912176362f56d97d3dc80da4feff40742fc81c42aafdbd3130f1b4726d8741
```

로컬 검토용 ZIP SHA-256:

```text
984401891aa9a7b62325181866e92c5e1a0ec6656d8f473a2ca4e1e3aa24600d
```

정식 서명을 적용하면 해시가 바뀌므로 ZIP과 체크섬을 다시 만들어야 합니다.

## 남은 배포 항목과 검증 한계

1. **정식 배포 서명:** 현재 `Signature=adhoc`, TeamIdentifier 없음, Hardened Runtime·공증 없음. 정상 서명·공증을 마친 최종 파일의 다운로드 설치 검증 필요.
2. **macOS 권한:** 재빌드 앱에서 입력 모니터링·화면 기록 권한 필요 안내가 다시 나타남. 현재 사용자 설정은 일시 정지 상태로 유지. 권한 재연결과 실제 Fn/Option 동작 확인는 이번 수정에서 완료하지 않음.
3. **라이선스:** 코드의 공개 라이선스와 제공받은 앱 아이콘의 재배포 조건 미확정. Lucide ISC/MIT 고지는 포함.
4. **환경:** Intel, macOS 13 실기기, 다중 물리 모니터, 실제 보안 입력 필드, Zoom/OBS 공유, 새 사용자에서의 설치 검증 미실시.
5. **감사 범위:** 패킷 캡처·메모리 덤프 분석·전문 침투 점검·Apple 공증 검사는 미실시. 정적 코드 검토 결과와 구분.

[배포 절차](DISTRIBUTION.md)와 [보안 정책](../SECURITY.md)을 함께 확인합니다.

## English summary

Fixed unnecessary retention of rendered keystroke/image references and stale-file inclusion during rebuilds. Added an explicit release-file allowlist, symlink/overwrite rejection, and checksums. All 178 automated assertions passed; extracted application files match the original and retain a valid local signature.

A pattern-based scan of 92 historical blobs found no matching credentials. This is not a full secret-scanner or security assessment certification. Existing work-log history still needs publication review.

The current arm64 package is ad hoc signed, not notarized or publicly published. Developer ID/Hardened Runtime/notarization, code/icon licensing, final permission/physical-key checks, and additional hardware/OS validation remain pending.


## v0.7 공개 전 재검사 — 2026-10-18

- 0.7 / 빌드 15, Apple Silicon 앱을 공식 버전으로 배포합니다. 위의 0.3.6 검토 수치와 구분합니다.
- 현재 소스에서 기존 자동 검사 178개(112 + 22 × 3)를 재실행하여 모두 통과했습니다.
- 작업 일지를 제외한 공개 대상 56개 파일에서 위의 7종 자격증명 패턴 일치 0개. 전문 비밀정보 스캐너나 이미지 내 개인정보 분석을 대신하는 검사는 아닙니다.
- 공개 main은 기존 로컬 Git 이력과 분리한 소스 스냅샷으로 시작하며, 작업 일지·백업·빌드 산출물·이전 로컬 이력은 제외합니다.
- 현재 앱을 재빌드하지 않고 묶은 ZIP은 400,044바이트. 압축 해제한 12개 앱 파일이 원본과 일치하고 ad hoc 서명 검증에 성공했습니다. 실행 파일에 /Users/ 경로 문자열이 없습니다.
- 앱 ZIP SHA-256: `40d6f9453d0ed516d8bca15dec2cd11ddcbbad3169712f274f17f060c377d4bf`.
- Developer ID·Hardened Runtime·Apple 공증·별도 Mac 신규 설치는 미완료이며 릴리스·README·홈페이지에 명시합니다. 비공개 취약점 보고는 GitHub 설정에서 활성화했습니다.

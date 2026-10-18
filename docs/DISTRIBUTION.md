# GitHub·홈페이지 무료 배포 / Free direct distribution

기준: 2026-10-18. 첫 공개 버전은 **ver 0.7 / 빌드 15**, **공식 버전**입니다. Mac App Store에는 배포하지 않습니다.

## 공개 경로

| 항목 | 경로 |
| --- | --- |
| 홈페이지 | [jvibeschool.org/BIGMOUSE](https://jvibeschool.org/BIGMOUSE/) |
| 소스·문서 | [jvisualschool/BIGMOUSE](https://github.com/jvisualschool/BIGMOUSE/) |
| 공식 릴리스 | [v0.7](https://github.com/jvisualschool/BIGMOUSE/releases/tag/v0.7) |
| 앱 ZIP | [BigMouse-0.7-macos-arm64.zip](https://github.com/jvisualschool/BIGMOUSE/releases/download/v0.7/BigMouse-0.7-macos-arm64.zip) |
| 앱 체크섬 | [SHA-256](https://github.com/jvisualschool/BIGMOUSE/releases/download/v0.7/BigMouse-0.7-macos-arm64.zip.sha256) |

홈페이지는 같은 GitHub 자산에 연결합니다. 무료 사용이며 회원 가입·구독·유료 기능 해제는 없습니다. 별도의 오픈소스 라이선스를 지정한 것은 아닙니다. Lucide 고지를 유지합니다.

## v0.7의 검증 범위

- Apple Silicon `arm64`, 최소 빌드 대상 macOS 13, 앱 내부 버전 0.7 / 빌드 15.
- 현재 사용 중인 앱을 다시 빌드하거나 교체하지 않고 패키징했습니다. 기존 macOS 권한 연결을 유지했습니다.
- ZIP의 파일 허용 목록·심볼릭 링크 검사, 앱 서명 무결성, plist/언어 파일 문법, 압축 해제한 앱 12개 파일의 원본 일치를 확인합니다.
- 로컬 실행에서 메뉴 막대 아이콘, 확대 프레임과 키 표시를 확인했습니다. 별도 Mac 신규 설치, 실제 Fn 입력, Intel·macOS 13 실기기·외부 모니터·화면 공유 검증은 별도입니다.
- **임시 서명(ad hoc)만 있으며 Developer ID·Hardened Runtime·Apple 공증은 없습니다.** GitHub에서 정식 릴리스로 공개하고 README와 홈페이지에서도 공식 0.7 버전으로 안내합니다.

설치·첫 실행 안내는 [한국어 README](../README.md#installation), [English README](../README.en.md#installation)와 [릴리스 노트](releases/v0.7.md)를 확인합니다. 시스템 보안 전체를 끄는 방법은 배포 안내에 사용하지 않습니다.

## 공개 소스와 로컬 이력

공개 `main` 브랜치는 검토한 소스 스냅샷으로 시작합니다. 기존 로컬 `master` 개발 이력은 보존하지만 공개하지 않습니다. 로컬 작업 일지, 인증서·키·토큰, `.build/`, `dist/`, 임시 앱과 백업은 공개 소스에서 제외합니다.

`.gitattributes`의 `/docs/work-logs export-ignore`는 소스 아카이브에서 작업 일지를 제외합니다. 이미 존재하는 Git 이력에서 파일을 지우지는 않습니다. 따라서 **기존 로컬 `master`를 원격에 push하거나 `git push --all`을 실행하지 않습니다.** 공개용 `public` 브랜치를 원격 `main`에 연결합니다.

후속 소스 게시 시:

1. 로컬 작업 내용을 커밋합니다.
2. 현재 원격 `main`을 별도 임시 checkout으로 가져옵니다.
3. `git archive HEAD`에서 내보낸 검토된 파일로 공개 checkout 내용을 동기화합니다. `.git`과 공개 이력은 유지하고 작업 일지·빌드·비밀정보 제외를 확인합니다.
4. 그 checkout에서 후속 커밋을 만들고 원격 `main`에 push합니다. 로컬 `public` 참조도 같은 커밋으로 갱신합니다.
5. 공개 URL의 파일, 릴리스 태그와 자산을 확인합니다. 기존 로컬 `master` 이력을 원격에 합치지 않습니다.

## 패키징과 릴리스

실행 중인 앱을 바꿀 필요가 있을 때만 `bash build.sh`를 실행합니다. 임시 서명 앱을 재빌드하면 권한을 다시 연결해야 할 수 있습니다.

```sh
bash test.sh
codesign --verify --strict dist/BigMouse.app
plutil -lint dist/BigMouse.app/Contents/Info.plist
lipo -archs dist/BigMouse.app/Contents/MacOS/BigMouse
bash scripts/package-release.sh
cd dist/releases/v0.7
shasum -a 256 -c BigMouse-0.7-macos-arm64.zip.sha256
```

패키징 스크립트는 앱 내부 버전과 아키텍처에서 파일명을 결정하고 기존 ZIP 덮어쓰기를 거부합니다. 공개 자산을 같은 버전으로 몰래 교체하지 말고, 앱이 달라지면 새 버전을 사용합니다.

소스 ZIP은 공개 태그 `v0.7`에서 만들고 별도의 SHA-256 파일을 제공합니다. 앱 ZIP과 소스 ZIP은 각각 용도가 다르며 릴리스에 네 파일을 첨부합니다. GitHub의 자동 소스 ZIP은 설치할 앱이 아닙니다.

GitHub에는 태그 `v0.7`과 **BigMouse ver 0.7** 제목을 사용합니다. 초안에서 네 파일·링크·버전·체크섬을 검사한 뒤 정식 릴리스로 공개합니다. 비공개 취약점 제보를 활성화하고 자격증명 검사를 수행합니다.

## 향후 정식 서명·공증

Developer ID Application 인증서와 공증용 Keychain 프로필을 준비한 뒤 실제 이름을 환경에 지정합니다. 개인 키·앱 전용 암호를 소스나 명령에 직접 넣지 않습니다. 다음은 **향후 절차**이며 v0.7에 적용한 상태가 아닙니다.

```sh
: "${BIGMOUSE_SIGNING_IDENTITY:?Set the Developer ID Application identity}"
: "${BIGMOUSE_NOTARY_PROFILE:?Set the notarization Keychain profile}"
codesign --force --options runtime --timestamp \
  --sign "$BIGMOUSE_SIGNING_IDENTITY" dist/BigMouse.app
codesign --verify --strict --verbose=2 dist/BigMouse.app
ditto -c -k --keepParent dist/BigMouse.app .build/BigMouse-notarization.zip
xcrun notarytool submit .build/BigMouse-notarization.zip \
  --keychain-profile "$BIGMOUSE_NOTARY_PROFILE" --wait
xcrun stapler staple dist/BigMouse.app
xcrun stapler validate dist/BigMouse.app
spctl --assess --type execute --verbose=2 dist/BigMouse.app
```

공증 Accepted와 로그를 확인한 뒤 최종 앱을 다시 패키징하고 체크섬을 생성합니다. 서명 이후 재빌드하면 서명·공증도 다시 해야 합니다. 최종 다운로드본을 별도 Mac에서 설치하여 Gatekeeper·권한·Fn 확대·키 표시를 검증합니다. [Apple 직접 배포](https://developer.apple.com/macos/distribution/) · [Apple 공증](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

## 홈페이지 동기화

릴리스 공개와 다운로드 검증 이후 홈페이지의 다운로드 링크를 갱신합니다. 웹사이트에는 같은 GitHub ZIP·체크섬·릴리스 노트를 연결하며 설치·서명 상태 안내를 함께 표시합니다. 공개 후 HTTPS 상태·파일 일치·한영 표시·모바일·브라우저 콘솔을 검사합니다. `.org`의 기존 `noindex, nofollow`와 CSP를 유지합니다. 다른 서버 프로젝트나 루트 설정은 수정하지 않습니다.

## English summary

Version 0.7 / build 15 is a free **official release** for Apple Silicon. It has an ad hoc signature, with no Developer ID, Hardened Runtime or notarization. The website links to the same GitHub app ZIP, checksum and release notes. Fresh installation on another Mac and additional hardware/OS validation remain pending.

The public `main` branch starts with a reviewed snapshot that excludes private work logs and build output. Preserve the existing local development history privately; never push local `master` or use `git push --all`. Continue the public branch from its own history. Validate package contents, downloaded bytes and release metadata, and keep private vulnerability reporting enabled. No separate open-source license has been assigned.

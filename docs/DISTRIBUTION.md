# GitHub·홈페이지 무료 배포 / Free direct distribution

기준 / Updated: 2026-10-19 · **ver 0.8 / build 21 · Apple Silicon (arm64)**

## 공개 경로 / Public channels

- [홈페이지 / Website](https://jvibeschool.org/BIGMOUSE/)
- [공개 소스 / Public source](https://github.com/jvisualschool/BIGMOUSE/)
- [v0.8 릴리스 / Release](https://github.com/jvisualschool/BIGMOUSE/releases/tag/v0.8)
- [앱 ZIP / App ZIP](https://github.com/jvisualschool/BIGMOUSE/releases/download/v0.8/BigMouse-0.8-macos-arm64.zip) · [SHA-256](https://github.com/jvisualschool/BIGMOUSE/releases/download/v0.8/BigMouse-0.8-macos-arm64.zip.sha256)

무료 직접 배포이며 App Store·계정·구독·유료 기능 해제가 없습니다. 별도 오픈소스 라이선스는 지정하지 않았으며 Lucide 고지를 유지합니다. / Free direct distribution with no App Store, account, subscription or paid unlock. No separate open-source license has been assigned; retain Lucide notices.

## 서명과 권한 / Signing and permissions

0.8은 고정된 전용 코드 서명 인증서를 사용합니다. 앱 식별자와 인증서 지문을 검증하고, 키가 없으면 빌드를 중단합니다. 개인 키는 로그인 키체인에만 보관합니다. 개발용 `bash build.sh --development`는 별도 식별자의 BigMouse Dev.app을 생성합니다. 자세한 내용은 [서명 안내](SIGNING.md)를 참고합니다.

Version 0.8 uses a pinned, dedicated code-signing certificate. Builds and packaging validate the bundle identifier and certificate fingerprint; missing keys stop the release build. The private key stays in the login keychain. `bash build.sh --development` creates a separate BigMouse Dev.app identity. See [signing instructions](SIGNING.md).

기존 임시 서명에서 처음 전환할 때는 화면 기록·입력 모니터링을 한 번 다시 허용합니다. 이후 같은 서명과 앱 위치를 유지합니다. Developer ID·Hardened Runtime·Apple 공증은 없으며, 첫 실행 허용은 별도입니다. / Migration from ad hoc signing requires a one-time permission grant. Keep the same signing identity and app location for later updates. Developer ID, Hardened Runtime and Apple notarization are not included; first-launch approval is separate.

## 검증 범위 / Validation scope

- macOS 27.0.1 / Apple Silicon에서 빌드 20 → 21 교체 후 권한 초기화·재요청 없이 확대 프레임과 입력 이벤트 모니터가 작동했습니다. / On macOS 27.0.1 / Apple Silicon, build 20 → 21 retained working screen frames and the input event monitor without a permission reset or new grant.
- 회귀 검사 274개, 지역별 번역 검사 22개 × 3개 지역을 통과했습니다. / Passed 274 regression checks and 22 localization checks in each of three region configurations.
- 앱 ZIP 압축 해제 후 12개 파일 일치, 버전·아키텍처·고정 서명과 SHA-256을 확인합니다. / Verify all 12 extracted app files, version, architecture, pinned signature and SHA-256.
- 한·영 웹사이트는 밝은/어두운 화면과 320/390/1280px에서 검사합니다. / Check the bilingual website in both themes at 320/390/1280px.
- 별도 Mac 신규 설치, Intel, macOS 13 실기기, 외부 모니터와 화면 공유는 별도 검증 대상입니다. / Fresh installation on another Mac, Intel, physical macOS 13, external monitors and screen sharing remain outside this validation.

## 공개 소스와 로컬 이력 / Public source and private history

공개 `main`은 검토된 소스 스냅샷으로 시작했습니다. 기존 로컬 `master` 개발 이력은 비공개로 유지합니다. **로컬 master push·git push --all·개발 이력 병합을 하지 않습니다.** 작업 일지, `.build/`, `dist/`, 임시 앱, 백업과 자격증명은 공개 소스에서 제외합니다. `.gitattributes`의 `/docs/work-logs export-ignore`를 유지합니다.

Public `main` began with a reviewed source snapshot. Preserve local `master` history privately: **never push local master, use git push --all, or merge private development history into main**. Exclude work logs, build output, temporary apps, backups and credentials. Preserve the work-log export exclusion.

## 패키징 / Packaging

배포용 키가 있는 담당자가 최종 앱을 검사·패키징합니다. / The release maintainer needs the pinned signing key.

```sh
bash test.sh
python3 scripts/signing.py verify dist/BigMouse.app
plutil -lint dist/BigMouse.app/Contents/Info.plist
lipo -archs dist/BigMouse.app/Contents/MacOS/BigMouse
bash scripts/package-release.sh
cd dist/releases/v0.8
shasum -a 256 -c BigMouse-0.8-macos-arm64.zip.sha256
```

스크립트는 알 수 없는 앱 파일, 심볼릭 링크, 잘못된 서명과 기존 ZIP 덮어쓰기를 거부합니다. 이미 공개한 앱 파일을 같은 버전으로 바꾸지 않습니다. / Packaging rejects unexpected files, symlinks, incorrect signatures and existing ZIPs. Never replace a published app silently under the same version.

공개 태그에서 `BigMouse-0.8-source.zip`과 `.sha256`을 만들고 앱 ZIP·체크섬과 함께 네 자산을 제공합니다. / Create the source ZIP and checksum from the public tag and attach all four assets. GitHub's automatic source archives are not installable apps.

## 배포 순서 / Deployment order

1. 수정 내용을 로컬 커밋하고 앱·권한 유지·한영 웹 검사를 통과합니다. / Commit locally and pass app, permission-continuity and bilingual web checks.
2. 별도 checkout에서 원격 main을 가져오고 `git archive HEAD`의 검토된 스냅샷을 동기화합니다. `.git`과 공개 이력을 보존하고 공개용 커밋·태그·소스 ZIP을 준비합니다. / Prepare a reviewed public snapshot, commit, tag and source ZIP in a separate checkout based on remote main.
3. **홈페이지를 먼저 배포합니다.** 기존 파일은 웹 루트 밖에 백업하고 원격 변경 여부를 검사합니다. GitHub 릴리스 공개 전에는 검증된 앱 ZIP·체크섬을 사이트 다운로드 경로로 제공하고 개선 로그를 연결합니다. / **Deploy the website first**, with backups outside the web root and a remote-change check. Use a verified website copy of the app and checksum until the GitHub release is public.
4. 공개 main과 태그를 push하고 네 자산을 검사한 뒤 **BigMouse ver 0.8** 릴리스를 공개합니다. / Push public main and the tag, validate the four assets, and publish **BigMouse ver 0.8**.
5. GitHub 공개 다운로드를 검증하고 웹사이트 링크를 같은 GitHub ZIP·체크섬·릴리스로 연결합니다. HTTPS·SHA-256·한영·모바일·콘솔을 다시 확인합니다. / Verify public GitHub downloads, then connect the website to the same GitHub assets and recheck HTTPS, hashes and bilingual mobile behavior.

`.org`의 `noindex, nofollow`와 CSP를 유지하며 다른 프로젝트나 서버 루트 설정은 바꾸지 않습니다. / Preserve `.org` noindex/nofollow and CSP; leave other projects and root server configuration unchanged.

향후 Developer ID·공증으로 전환할 경우 별도 권한 이전 검사를 완료한 뒤 새 버전으로 배포합니다. / A future move to Developer ID and notarization requires separate migration testing and a new release.

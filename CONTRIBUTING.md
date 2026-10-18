# Contributing / 기여 안내

## 개발 환경 / Development

macOS, Apple Command Line Tools, Swift. 외부 패키지 관리자는 사용하지 않습니다. / No external package manager is required.

```sh
bash build.sh
bash test.sh
git diff --check
```

검사는 로그인된 macOS 데스크톱 세션에서 실행합니다. 화면 없는 CI에서는 오버레이 검사가 실패할 수 있습니다. / Run tests in a logged-in desktop session; headless CI may not provide a display for overlay tests.

## 코드 변경 / Changes

- 화면 문구는 `Sources/Localization.swift`의 키와 `Resources/{ko,en}.lproj/Localizable.strings` 두 파일에 함께 추가합니다. / Add every interface string to both languages and the typed key list.
- 언어는 선호 언어가 아니라 지역으로 결정합니다. `en_KR` → 한국어, `ko_US` → English를 유지합니다. / Region takes precedence over preferred language.
- 설정의 저장 키·enum raw value는 번역하지 않습니다. / Do not translate persisted preference keys or enum raw values.
- 키 입력·화면 캡처를 파일, 로그 또는 네트워크로 출력하지 않습니다. / Do not write keystrokes or captured content to files, logs, or the network.
- 일시 정지·잠자기·화면 재구성 시 입력과 영상 참조를 해제하는 동작을 유지합니다. / Preserve clearing of input and image references when suspended.
- 둥근 요소의 한쪽 모서리에만 색이 뭉치는 테두리·그라데이션을 사용하지 않습니다. / Avoid one-sided accents that bunch up at rounded corners.
- 기능 변경에는 해당 동작의 회귀 검사를 추가하고, 문구·단순 배치는 실제 두 언어 UI로 확인합니다. / Test behavior changes and inspect layout in both languages.
- 커밋 메시지는 영어로 작성합니다. / Use English commit messages.

## 문제 제보 / Bug reports

앱 버전, macOS 버전, Mac 아키텍처, 지역 설정, 재현 순서와 기대/실제 결과를 적습니다. 민감한 입력, 화면 내용, 서명 인증서, 자격증명을 첨부하지 마세요. / Include app and macOS versions, architecture, region, reproduction steps, and expected/actual behavior. Omit private input, screen content, signing keys, and credentials.

보안 취약점은 공개 이슈에 세부 내용을 올리지 말고 [SECURITY.md](SECURITY.md)를 따릅니다. / Follow the private reporting guidance in SECURITY.md for vulnerabilities.

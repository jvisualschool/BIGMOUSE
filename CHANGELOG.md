# Changelog / 변경 기록

## 0.8 — 2026-10-19

- 확대·스포트라이트·키 표시의 단축키를 각각 지정합니다. 중복·시스템 예약 검사와 기본값 복원을 제공합니다. / Assign shortcuts independently, with conflict checks and restore defaults.
- 전용 고정 서명으로 업데이트 간 앱 식별을 유지합니다. 이전 임시 서명에서 전환 시 한 번 재허용이 필요합니다. / Keep app identity across updates with a dedicated certificate; migration from an ad hoc build requires one permission grant.
- 확대 권한 오류와 복구 안내를 설정창 맨 위에 표시합니다. / Keep zoom permission errors and recovery steps visible above the settings form.
- 홈페이지에서 최신 버전과 한국어·영어 개선 로그를 제공합니다. / Show the latest version and bilingual release history on the website.

- 설정창 맨 아래에 앱 버전을 한국어·영어로 표시합니다. / Show the app version at the bottom of Settings in both languages.

- 한글 입력 상태의 Command·Control·Option 조합을 영문 키로 표시합니다. 실제 입력은 바꾸지 않습니다. / Show English key labels for Hangul shortcuts without modifying input.
- ‘단축키만 / 모든 키’와 ‘특수키도 표시’ 선택을 추가했습니다. Shift만 사용한 문자 입력과 일반 Space는 단축키에서 제외합니다. / Add shortcut filtering with optional special keys.
- 새 설치는 단축키만 표시하고 기존 설치는 모든 키 표시를 유지합니다. 선택은 저장되며 즉시 적용됩니다. / Default to shortcuts on new installs; preserve all-key behavior on upgrades.

## 0.7 — 2026-10-18 / First official release

- 실제 설정 화면과 3D 아이소메트릭 복셀 히어로를 사용한 한국어·영어 홈페이지 가이드 추가.
- Add a bilingual website guide with real settings screenshots and a 3D isometric voxel hero.
- 메뉴 막대에 앱 아이콘 모양을 유지한 흰색 아이콘을 18pt로 표시.
- Use an 18pt white silhouette of the app icon in the menu bar.
- 첫 공식 버전 ver 0.7, 빌드 15 공개.
- Publish the first official release, version 0.7, build 15.
- GitHub `jvisualschool/BIGMOUSE`와 `https://jvibeschool.org/BIGMOUSE/`에서 무료 직접 배포. App Store 배포 없음.
- Free direct distribution through GitHub and the developer website; no Mac App Store release.
- 한국어·영어 README에 설치·권한·전체 기능·기본값·FAQ·업데이트·삭제 안내 확장.
- Expanded Korean and English manuals, including permission recovery and troubleshooting.
- 두 자리 버전 `0.7`과 세 자리 버전을 모두 허용하도록 패키징 검사 조정.
- Packaging accepts both two-component versions such as `0.7` and three-component versions.
- Apple Silicon용 공식 릴리스. Developer ID 서명·공증과 별도 Mac 신규 설치 검증은 미완료. 아래 0.3.x는 공개 이전 개발 이력.
- Official Apple Silicon release. Developer ID signing, notarization, and fresh installation on another Mac remain pending. The 0.3.x entries below are local development history.

## 0.3.6 — 2026-10-18 (release preparation / 배포 준비)

- 한국 지역은 한국어, 나머지 지역은 영어로 표시. 설정·메뉴·권한 안내·접근성·키 입력 상태의 72개 문구 적용.
- Korean for the South Korea region; English elsewhere. Localized settings, menus, permission messages, accessibility labels, and status text.
- 영어 문구에 맞춘 설정 창 너비 조정. / Wider English settings layout.
- 일시 정지·잠자기·화면 재구성·종료 시 렌더링된 키 문자열과 확대 이미지 참조 정리.
- Release rendered key text and zoom image references on pause, sleep, display reconfiguration, and shutdown.
- 깨끗한 임시 폴더에서 빌드하고 허용한 파일만 ZIP으로 패키징. SHA-256 파일 생성.
- Build in clean staging; validate release file contents and generate ZIP checksums.
- 한국어·영어 README, 배포 안내, 보안 정책 및 점검 문서 준비.
- Prepared bilingual documentation, release guidance, security policy, and review notes.

## 0.3.5 — 2026-10-17

- 코드 크기 최적화와 디버그·로컬 심볼 정리로 앱 전체를 약 631KB로 축소.
- Reduced the app bundle to approximately 631KB with size optimization and symbol stripping.

## 0.3.0–0.3.4 — 2026-10-17

- Option 두 번 키 표시, 폰트·128pt 크기·연속/분리·상중하 설정.
- Keystroke display, font and size controls, continuous/separate modes, and vertical positioning.
- 표준 2컬럼 선택 UI, 검정·흰색 강조색, 형태가 통일된 위치 아이콘.
- Standard two-column controls, black/white highlight colors, and consistent position icons.
